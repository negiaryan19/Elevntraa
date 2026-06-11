import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/errors/failure.dart';
import '../../../core/network/dio_client.dart';
import '../../../domain/models/medical_insight.dart';
import '../../../domain/models/medication.dart';

/// Holds both the re-labeled transcript (Doctor:/Patient:) and the extracted
/// [MedicalInsight]. The controller stores both in the visit row so the Review
/// screen shows a clean, human-readable conversation.
class InsightResult {
  const InsightResult({required this.transcript, required this.insight});
  final String transcript;
  final MedicalInsight insight;
}

/// Gemini structured extraction.
///
/// When the transcript comes from Sarvam diarization it contains raw
/// `SPEAKER_0:` / `SPEAKER_1:` labels. In that case a single Gemini call
/// reads the FULL conversation to decide who is the Doctor and who is the
/// Patient (based on context — who prescribes vs who describes symptoms),
/// re-labels the transcript, and extracts the medical insight.
///
/// When the transcript is plain text (single-speaker dictation or
/// already labeled), the original extraction path is used.
class InsightService {
  InsightService(this._dio);

  final Dio _dio;

  static final _speakerPattern = RegExp(r'SPEAKER_\d+:');

  // ── Plain-transcript system instruction ──────────────────────────────────

  static const String _plainInstruction =
      'You are a medical scribe. Given a doctor-patient consultation transcript '
      '(lines labeled "Doctor:"/"Patient:"), do two things: '
      '1) Write a consultationSummary: 1-2 plain sentences describing what the '
      'patient came in for and what the doctor prescribed or advised. Write it '
      'as a simple human-readable note, not a list. '
      '2) Extract structured fields: symptoms (patient-described or '
      'doctor-observed); diagnosis, medications, tests, followUpDays, '
      'doctorNotes; '
      'advice (general health guidance: rest, diet, hydration, lifestyle — NOT '
      'tied to a specific medicine); '
      'instructions (specific actionable directions the patient must follow: '
      'how/when to take medicines, precautions, warning signs to return, when '
      'to follow up). '
      'Each advice/instruction is a short separate sentence in the list. '
      'Extract these ONLY from the Doctor\'s explicit words. '
      'Write EVERY output field (consultationSummary, symptoms, diagnosis, '
      'medications, tests, advice, instructions, doctorNotes) in clear English. '
      'If the consultation '
      'is in Hindi or code-mixed Hindi/English, translate the meaning into '
      'English — never output Hindi or Devanagari script. Keep drug names in '
      'their standard Latin spelling. Translating the language is allowed, but '
      'never add clinical information that was not spoken. '
      'Never infer or add anything unspoken. Use empty list/string when absent '
      '(null followUpDays). Output strict JSON per schema.';

  // ── Diarized-transcript system instruction ───────────────────────────────

  static const String _diarizedInstruction =
      'You are a medical scribe. Given a doctor-patient consultation transcript '
      'with speakers labeled SPEAKER_0/1/... (roles unknown), do three things: '
      '1) Identify which speaker is the Doctor (examines, diagnoses, prescribes) '
      'and which is the Patient (describes symptoms). '
      '2) Write a consultationSummary: 1-2 plain sentences describing what the '
      'patient came in for and what the doctor prescribed or advised. Write it '
      'as a simple human-readable note, not a list. '
      '3) Extract structured fields: symptoms (patient-described or '
      'doctor-observed); diagnosis, medications, tests, followUpDays, '
      'doctorNotes; '
      'advice (general health guidance: rest, diet, hydration, lifestyle — NOT '
      'tied to a specific medicine); '
      'instructions (specific actionable directions the patient must follow: '
      'how/when to take medicines, precautions, warning signs to return, when '
      'to follow up). '
      'Each advice/instruction is a short separate sentence in the list. '
      'Extract these ONLY from Doctor lines. '
      'Write EVERY output field (consultationSummary, symptoms, diagnosis, '
      'medications, tests, advice, instructions, doctorNotes) in clear English. '
      'If the consultation '
      'is in Hindi or code-mixed Hindi/English, translate the meaning into '
      'English — never output Hindi or Devanagari script. Keep drug names in '
      'their standard Latin spelling. Translating the language is allowed, but '
      'never add clinical information that was not spoken. '
      'Never infer or add anything unspoken. Use empty list/string when absent '
      '(null followUpDays). Output strict JSON per schema.';

  // ── Public API ────────────────────────────────────────────────────────────

  Future<InsightResult> extract(String rawTranscript) async {
    final key = Env.geminiApiKey;
    if (key == null || key.isEmpty) {
      throw const ApiFailure('Gemini API key is not configured.');
    }
    if (rawTranscript.trim().isEmpty) {
      return InsightResult(transcript: rawTranscript, insight: MedicalInsight.empty);
    }

    final isDiarized = _speakerPattern.hasMatch(rawTranscript);
    return isDiarized
        ? _extractDiarized(rawTranscript, key)
        : _extractPlain(rawTranscript, key);
  }

  // ── Diarized path (SPEAKER_X labels) ─────────────────────────────────────

  Future<InsightResult> _extractDiarized(String rawTranscript, String key) async {
    final url =
        '${Env.geminiEndpointBase}/models/${Env.geminiModel}:generateContent?key=$key';

    final body = {
      'systemInstruction': {
        'parts': [
          {'text': _diarizedInstruction}
        ]
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': rawTranscript}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.3,
        'responseMimeType': 'application/json',
        'responseSchema': _diarizedSchema,
        // Quality-first token control. Gemini 2.5 Flash's default "thinking" is
        // *dynamic* and can run thousands of tokens per call. We don't switch it
        // off (role identification + clinical extraction genuinely benefit from
        // reasoning) — we BOUND it to a generous-but-capped budget. This keeps
        // medical accuracy intact while removing the unbounded cost. The output
        // cap is set high so a long medicine list / notes is never truncated.
        'maxOutputTokens': 4096,
        'thinkingConfig': {'thinkingBudget': 1024},
      },
    };

    try {
      final res = await _dio.post<Map<String, dynamic>>(
        url,
        data: jsonEncode(body),
        options: Options(
          headers: {'Content-Type': 'application/json'},
          responseType: ResponseType.json,
        ),
      );
      final raw = _extractJson(res.data);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;

      final doctorId = (decoded['doctor_speaker_id'] as String? ?? '').trim();
      final patientId = (decoded['patient_speaker_id'] as String? ?? '').trim();

      final relabeled = _relabelTranscript(rawTranscript, doctorId, patientId);
      final insight = MedicalInsight.fromJson(_coerce(decoded));

      return InsightResult(transcript: relabeled, insight: insight);
    } on DioException catch (e) {
      throw _mapDioError(e);
    } on FormatException catch (e) {
      throw ApiFailure('Gemini returned malformed JSON: ${e.message}');
    }
  }

  /// Replace raw speaker IDs with Doctor/Patient labels throughout the
  /// transcript. Any third speaker (rare) gets "Speaker".
  String _relabelTranscript(String raw, String doctorId, String patientId) {
    var result = raw;
    if (doctorId.isNotEmpty) {
      result = result.replaceAll('$doctorId:', 'Doctor:');
    }
    if (patientId.isNotEmpty) {
      result = result.replaceAll('$patientId:', 'Patient:');
    }
    // Any remaining SPEAKER_X (unexpected third party)
    result = result.replaceAll(_speakerPattern, 'Speaker:');
    return result;
  }

  // ── Plain path (no SPEAKER_ labels) ──────────────────────────────────────

  Future<InsightResult> _extractPlain(String transcript, String key) async {
    final url =
        '${Env.geminiEndpointBase}/models/${Env.geminiModel}:generateContent?key=$key';

    final body = {
      'systemInstruction': {
        'parts': [
          {'text': _plainInstruction}
        ]
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': transcript}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.3,
        'responseMimeType': 'application/json',
        'responseSchema': _schema,
        // See _extractDiarized: bounded (not disabled) reasoning preserves
        // extraction quality while capping the token cost.
        'maxOutputTokens': 4096,
        'thinkingConfig': {'thinkingBudget': 1024},
      },
    };

    try {
      final res = await _dio.post<Map<String, dynamic>>(
        url,
        data: jsonEncode(body),
        options: Options(
          headers: {'Content-Type': 'application/json'},
          responseType: ResponseType.json,
        ),
      );
      final raw = _extractJson(res.data);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return InsightResult(
        transcript: transcript,
        insight: MedicalInsight.fromJson(_coerce(decoded)),
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    } on FormatException catch (e) {
      throw ApiFailure('Gemini returned malformed JSON: ${e.message}');
    }
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Map<String, dynamic> _coerce(Map<String, dynamic> input) {
    final meds = (input['medications'] as List?)?.map((m) {
          if (m is! Map) return Medication(name: m.toString()).toJson();
          return {
            'name': m['name'] ?? '',
            'dosage': m['dosage'] ?? '',
            'frequency': m['frequency'] ?? '',
            'duration': m['duration'] ?? '',
            'needsReview': m['needsReview'] ?? m['needs_review'] ?? false,
          };
        }).toList() ??
        const <Map<String, dynamic>>[];
    return {
      'consultationSummary': input['consultationSummary'] ?? input['consultation_summary'] ?? '',
      'symptoms': input['symptoms'] ?? const <String>[],
      'diagnosis': input['diagnosis'] ?? '',
      'differentials': input['differentials'] ?? const <String>[],
      'medications': meds,
      'tests': input['tests'] ?? const <String>[],
      'advice': input['advice'] ?? const <String>[],
      'instructions': input['instructions'] ?? const <String>[],
      'followUpDays': input['followUpDays'] ?? input['follow_up_days'],
      'doctorNotes': input['doctorNotes'] ?? input['doctor_notes'] ?? '',
    };
  }

  String _extractJson(Map<String, dynamic>? data) {
    if (data == null) return '{}';
    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) return '{}';
    final parts =
        (candidates.first as Map)['content']?['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) return '{}';
    return parts.map((p) => (p as Map)['text'] ?? '').join('').toString();
  }

  Failure _mapDioError(DioException e) {
    final code = e.response?.statusCode;
    if (code == 401 || code == 403) {
      return ApiFailure('Gemini rejected the API key.', statusCode: code);
    }
    if (code != null && code >= 400) {
      final reason = _readGeminiError(e.response?.data) ??
          e.response?.statusMessage ??
          'Bad request';
      return ApiFailure('Gemini HTTP $code: $reason', statusCode: code);
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return NetworkFailure('Could not reach Gemini — check your connection.',
          cause: e);
    }
    return UnknownFailure('Extraction failed: ${e.message}', cause: e);
  }

  /// Gemini errors come back as `{"error":{"message":"..."}}`. Dio may parse
  /// or hand back raw bytes; handle both so the doctor sees a clean message.
  String? _readGeminiError(dynamic data) {
    Map<String, dynamic>? json;
    if (data is Map<String, dynamic>) {
      json = data;
    } else if (data is String && data.isNotEmpty) {
      try {
        json = jsonDecode(data) as Map<String, dynamic>?;
      } catch (_) {
        return data;
      }
    }
    final err = json?['error'];
    if (err is Map) {
      final msg = err['message'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    return null;
  }

  // ── Schemas ───────────────────────────────────────────────────────────────

  /// Schema for diarized transcripts — adds speaker role fields so Gemini
  /// tells us which SPEAKER_ID is the Doctor and which is the Patient.
  static const Map<String, dynamic> _diarizedSchema = {
    'type': 'OBJECT',
    'properties': {
      'doctor_speaker_id': {'type': 'STRING'},
      'patient_speaker_id': {'type': 'STRING'},
      'consultationSummary': {'type': 'STRING'},
      'symptoms': {
        'type': 'ARRAY',
        'items': {'type': 'STRING'},
      },
      'diagnosis': {'type': 'STRING'},
      'differentials': {
        'type': 'ARRAY',
        'items': {'type': 'STRING'},
      },
      'medications': {
        'type': 'ARRAY',
        'items': {
          'type': 'OBJECT',
          'properties': {
            'name': {'type': 'STRING'},
            'dosage': {'type': 'STRING'},
            'frequency': {'type': 'STRING'},
            'duration': {'type': 'STRING'},
            'needsReview': {'type': 'BOOLEAN'},
          },
          'required': ['name'],
        },
      },
      'tests': {
        'type': 'ARRAY',
        'items': {'type': 'STRING'},
      },
      'advice': {
        'type': 'ARRAY',
        'items': {'type': 'STRING'},
      },
      'instructions': {
        'type': 'ARRAY',
        'items': {'type': 'STRING'},
      },
      'followUpDays': {'type': 'INTEGER', 'nullable': true},
      'doctorNotes': {'type': 'STRING'},
    },
    'required': [
      'doctor_speaker_id',
      'patient_speaker_id',
      'consultationSummary',
      'symptoms',
      'diagnosis',
      'differentials',
      'medications',
      'tests',
      'advice',
      'instructions',
      'doctorNotes',
    ],
  };

  /// Schema for plain (non-diarized) transcripts.
  static const Map<String, dynamic> _schema = {
    'type': 'OBJECT',
    'properties': {
      'consultationSummary': {'type': 'STRING'},
      'symptoms': {
        'type': 'ARRAY',
        'items': {'type': 'STRING'},
      },
      'diagnosis': {'type': 'STRING'},
      'differentials': {
        'type': 'ARRAY',
        'items': {'type': 'STRING'},
      },
      'medications': {
        'type': 'ARRAY',
        'items': {
          'type': 'OBJECT',
          'properties': {
            'name': {'type': 'STRING'},
            'dosage': {'type': 'STRING'},
            'frequency': {'type': 'STRING'},
            'duration': {'type': 'STRING'},
            'needsReview': {'type': 'BOOLEAN'},
          },
          'required': ['name'],
        },
      },
      'tests': {
        'type': 'ARRAY',
        'items': {'type': 'STRING'},
      },
      'advice': {
        'type': 'ARRAY',
        'items': {'type': 'STRING'},
      },
      'instructions': {
        'type': 'ARRAY',
        'items': {'type': 'STRING'},
      },
      'followUpDays': {'type': 'INTEGER', 'nullable': true},
      'doctorNotes': {'type': 'STRING'},
    },
    'required': [
      'consultationSummary',
      'symptoms',
      'diagnosis',
      'differentials',
      'medications',
      'tests',
      'advice',
      'instructions',
      'doctorNotes',
    ],
  };
}

final insightServiceProvider = Provider<InsightService>((ref) {
  return InsightService(ref.watch(dioProvider));
});
