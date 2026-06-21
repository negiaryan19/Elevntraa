/// Standalone pipeline benchmark: Sarvam STT → Gemini extraction.
///
/// Reads API keys from the project's .env file, runs the same batch STT flow
/// and Gemini extraction flow used in the app, 5 times on the same audio, then
/// prints a summary table.
library;

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

// ── Constants ──────────────────────────────────────────────────────────────

const _sarvamBase = 'https://api.sarvam.ai';
const _geminiBase = 'https://generativelanguage.googleapis.com/v1beta';
const _geminiModel = 'gemini-2.5-flash';

const _usage = '''
Usage: dart run bin/bench.dart --audio <path> [--env <path>] [--debug]

  --audio <path>  Path to the audio file to benchmark.
                  Defaults to \$BENCH_AUDIO_PATH if set.
  --env <path>    Path to the .env file with API keys. Defaults to
                  \$BENCH_ENV_PATH, then '.env' in the current directory.
  --debug         Print transcript and full clinical extraction.
                  WARNING: this exposes PHI/PII in the terminal and any
                  captured logs. Off by default.
''';

// ── Entry point ────────────────────────────────────────────────────────────

Future<void> main(List<String> args) async {
  final opts = _parseArgs(args);

  final envPath =
      opts['env'] ?? Platform.environment['BENCH_ENV_PATH'] ?? '.env';
  final audioPath = opts['audio'] ?? Platform.environment['BENCH_AUDIO_PATH'];
  final debug = opts.containsKey('debug');

  if (audioPath == null || audioPath.isEmpty) {
    stderr.writeln('ERROR: no audio file specified.\n');
    stderr.writeln(_usage);
    exit(64); // EX_USAGE
  }

  final envFile = File(envPath);
  if (!envFile.existsSync()) {
    stderr.writeln('ERROR: .env file not found: $envPath');
    exit(1);
  }

  // Parse keys from .env
  final env = _parseEnv(envFile.readAsStringSync());
  final sarvamKey = env['SARVAM_API_KEY'] ?? '';
  final geminiKey = env['GEMINI_API_KEY'] ?? '';

  if (sarvamKey.isEmpty) {
    stderr.writeln('ERROR: SARVAM_API_KEY not found in $envPath');
    exit(1);
  }
  if (geminiKey.isEmpty) {
    stderr.writeln('ERROR: GEMINI_API_KEY not found in $envPath');
    exit(1);
  }

  final audioFile = File(audioPath);
  if (!audioFile.existsSync()) {
    stderr.writeln('ERROR: Audio file not found: $audioPath');
    exit(1);
  }

  final dio = _buildDio();

  _header('Pipeline Benchmark — 5 Runs');
  print('Audio : $audioPath');
  print('Size  : ${(audioFile.lengthSync() / 1024).toStringAsFixed(1)} KB');
  if (!debug) {
    print('(transcript & extraction hidden — pass --debug to show)');
  }
  print('');

  final results = <_RunResult>[];

  for (var i = 1; i <= 5; i++) {
    _divider('Run $i / 5');

    try {
      // ── STT ──────────────────────────────────────────────────────────────
      print('[$i] Starting Sarvam batch STT...');
      final sttStart = DateTime.now();
      final transcript = await _sarvamBatchTranscribe(
        dio,
        sarvamKey,
        audioPath,
      );
      final sttSec =
          DateTime.now().difference(sttStart).inMilliseconds / 1000.0;

      print('[$i] STT complete in ${_s(sttSec)}');
      if (debug) {
        print('\n── Transcript ─────────────────────────────────────────');
        print(transcript);
      }

      // ── Gemini ───────────────────────────────────────────────────────────
      print('\n[$i] Starting Gemini extraction...');
      final gemStart = DateTime.now();
      final insight = await _geminiExtract(dio, geminiKey, transcript);
      final gemSec =
          DateTime.now().difference(gemStart).inMilliseconds / 1000.0;
      final totalSec = sttSec + gemSec;

      print('[$i] Gemini complete in ${_s(gemSec)}');

      print('\n── Timings ────────────────────────────────────────────');
      print('  STT:    ${_s(sttSec)}');
      print('  Gemini: ${_s(gemSec)}');
      print('  TOTAL:  ${_s(totalSec)}');

      if (debug) {
        print('\n── Clinical summary ───────────────────────────────────');
        final diag = insight['diagnosis']?.toString() ?? '';
        final followUp = insight['followUpDays'];
        final meds = (insight['medications'] as List<dynamic>?) ?? <dynamic>[];
        print('  Diagnosis : $diag');
        if (insight['icdCode'] != null) {
          print(
            '  ICD-10    : ${insight["icdCode"]} — ${insight["icdDescription"]} '
            '(${insight["icdConfidence"]})',
          );
        }
        print(
          '  Follow-up : '
          '${followUp != null ? "$followUp days" : "not specified"}',
        );
        print('  Medicines :');
        if (meds.isEmpty) {
          print('    (none)');
        } else {
          for (final med in meds.cast<Map<String, dynamic>>()) {
            final parts =
                [med['name'], med['dosage'], med['frequency'], med['duration']]
                    .where((v) => v != null && v.toString().trim().isNotEmpty)
                    .join(' | ');
            print('    • $parts');
          }
        }

        print('\n── Full extracted JSON ────────────────────────────────');
        print(const JsonEncoder.withIndent('  ').convert(insight));
      }

      results.add(
        _RunResult(run: i, sttSec: sttSec, gemSec: gemSec, totalSec: totalSec),
      );
    } catch (e, st) {
      print('[$i] ERROR: $e');
      if (e is DioException) {
        print('     Status: ${e.response?.statusCode}');
        if (debug) print('     Body  : ${e.response?.data}');
      }
      print(st.toString().split('\n').take(5).join('\n'));
      results.add(_RunResult(run: i, error: e.toString()));
    }
  }

  // ── Summary table ─────────────────────────────────────────────────────────
  _header('Summary Table');
  final colW = 12;
  final header =
      '${'Run'.padRight(4)}| ${'STT time'.padRight(colW)}| '
      '${'Gemini time'.padRight(colW)}| Total time';
  print(header);
  print('-' * header.length);

  for (final r in results) {
    if (r.error != null) {
      print('${r.run.toString().padRight(4)}| ERROR: ${r.error}');
    } else {
      print(
        '${r.run.toString().padRight(4)}| '
        '${_s(r.sttSec!).padRight(colW)}| '
        '${_s(r.gemSec!).padRight(colW)}| '
        '${_s(r.totalSec!)}',
      );
    }
  }

  final ok = results.where((r) => r.error == null).toList();
  if (ok.isNotEmpty) {
    print('-' * header.length);

    double avg(Iterable<double> vals) =>
        vals.reduce((a, b) => a + b) / ok.length;
    double min_(Iterable<double> vals) => vals.reduce((a, b) => a < b ? a : b);
    double max_(Iterable<double> vals) => vals.reduce((a, b) => a > b ? a : b);

    final sttVals = ok.map((r) => r.sttSec!);
    final gemVals = ok.map((r) => r.gemSec!);
    final totVals = ok.map((r) => r.totalSec!);

    print(
      '${'Avg'.padRight(4)}| '
      '${_s(avg(sttVals)).padRight(colW)}| '
      '${_s(avg(gemVals)).padRight(colW)}| '
      '${_s(avg(totVals))}',
    );
    print('');
    print(
      'Min total : ${_s(min_(totVals))}   '
      'Max total : ${_s(max_(totVals))}',
    );
  }

  print('=' * 60);
  dio.close();
}

// ── Sarvam batch STT ────────────────────────────────────────────────────────
// Mirrors SarvamSttService._transcribeBatch — same API flow, same headers.

Future<String> _sarvamBatchTranscribe(Dio dio, String key, String path) async {
  final filename = path.split(Platform.pathSeparator).last;
  // Audio is >28s so we always use the batch path (same logic as the app).
  const mode = 'transcribe'; // language unknown → transcribe mode

  print('  [Sarvam] Creating job...');
  final jobId = await _sarvamInitiateJob(dio, key, mode);
  print('  [Sarvam] Job ID: $jobId');

  print('  [Sarvam] Getting upload URL...');
  final uploadUrl = await _sarvamGetUploadUrl(dio, key, jobId, filename);

  print('  [Sarvam] Uploading file...');
  await _sarvamUploadFile(dio, uploadUrl, File(path));
  print('  [Sarvam] File uploaded.');

  print('  [Sarvam] Starting job...');
  await _sarvamStartJob(dio, key, jobId);

  print('  [Sarvam] Polling for completion (every 3s, timeout 20min)...');
  final outputFilename = await _sarvamPollUntilComplete(dio, key, jobId);
  print('  [Sarvam] Done. Output file: $outputFilename');

  print('  [Sarvam] Getting download URL...');
  final downloadUrl = await _sarvamGetDownloadUrl(
    dio,
    key,
    jobId,
    outputFilename,
  );

  print('  [Sarvam] Downloading transcript...');
  return _sarvamDownloadTranscript(dio, downloadUrl);
}

Future<String> _sarvamInitiateJob(Dio dio, String key, String mode) async {
  final res = await dio.post<Map<String, dynamic>>(
    '$_sarvamBase/speech-to-text/job/v1',
    data: {
      'job_parameters': {
        'model': 'saaras:v3',
        'mode': mode,
        'language_code': 'unknown',
        'with_diarization': true,
        'num_speakers': 2,
      },
    },
    options: Options(
      headers: {
        'API-Subscription-Key': key,
        'Content-Type': 'application/json',
      },
      responseType: ResponseType.json,
    ),
  );
  final jobId = res.data?['job_id'] as String?;
  if (jobId == null) throw Exception('Sarvam did not return a job_id.');
  return jobId;
}

Future<String> _sarvamGetUploadUrl(
  Dio dio,
  String key,
  String jobId,
  String filename,
) async {
  final res = await dio.post<Map<String, dynamic>>(
    '$_sarvamBase/speech-to-text/job/v1/upload-files',
    data: {
      'job_id': jobId,
      'files': [filename],
    },
    options: Options(
      headers: {
        'API-Subscription-Key': key,
        'Content-Type': 'application/json',
      },
      responseType: ResponseType.json,
    ),
  );
  final urls = res.data?['upload_urls'] as Map<String, dynamic>?;
  final entry = urls?[filename] as Map<String, dynamic>?;
  final url = entry?['file_url'] as String?;
  if (url == null) throw Exception('Sarvam did not return an upload URL.');
  return url;
}

Future<void> _sarvamUploadFile(Dio dio, String presignedUrl, File file) async {
  final bytes = await file.readAsBytes();
  final res = await dio.put<dynamic>(
    presignedUrl,
    data: bytes,
    options: Options(
      // Correct MIME type for MP3; same x-ms-blob-type header the app uses
      // to satisfy Azure Blob Storage's requirement.
      headers: {'Content-Type': 'audio/mpeg', 'x-ms-blob-type': 'BlockBlob'},
      contentType: 'audio/mpeg',
      responseType: ResponseType.bytes,
      sendTimeout: const Duration(minutes: 5),
    ),
  );
  if ((res.statusCode ?? 0) >= 300) {
    throw Exception('Upload failed (${res.statusCode})');
  }
}

Future<void> _sarvamStartJob(Dio dio, String key, String jobId) async {
  await dio.post<dynamic>(
    '$_sarvamBase/speech-to-text/job/v1/$jobId/start',
    data: {},
    options: Options(
      headers: {
        'API-Subscription-Key': key,
        'Content-Type': 'application/json',
      },
      responseType: ResponseType.json,
    ),
  );
}

Future<String> _sarvamPollUntilComplete(
  Dio dio,
  String key,
  String jobId,
) async {
  const interval = Duration(seconds: 3);
  final deadline = DateTime.now().add(const Duration(minutes: 20));
  var dots = 0;

  while (DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(interval);

    final res = await dio.get<Map<String, dynamic>>(
      '$_sarvamBase/speech-to-text/job/v1/$jobId/status',
      options: Options(
        headers: {'API-Subscription-Key': key},
        responseType: ResponseType.json,
      ),
    );

    final body = res.data;
    final jobState = body?['job_state'] as String?;

    dots++;
    stdout.write(
      '\r  [Sarvam] State: ${(jobState ?? '...').padRight(12)} (${dots * 3}s elapsed)',
    );

    if (jobState == 'Completed') {
      print(''); // newline after spinner
      final details = (body?['job_details'] as List?)
          ?.cast<Map<String, dynamic>>();
      final outputs = (details?.firstOrNull?['outputs'] as List?)
          ?.cast<Map<String, dynamic>>();
      final outputFilename = outputs?.firstOrNull?['file_name'] as String?;
      if (outputFilename == null) {
        throw Exception('Job completed but no output file listed.');
      }
      return outputFilename;
    }

    if (jobState == 'Failed') {
      print('');
      final msg = body?['error_message'] as String? ?? 'Unknown error';
      throw Exception('Sarvam job failed: $msg');
    }
  }

  throw Exception('Transcription timed out after 20 minutes.');
}

Future<String> _sarvamGetDownloadUrl(
  Dio dio,
  String key,
  String jobId,
  String outputFilename,
) async {
  final res = await dio.post<Map<String, dynamic>>(
    '$_sarvamBase/speech-to-text/job/v1/download-files',
    data: {
      'job_id': jobId,
      'files': [outputFilename],
    },
    options: Options(
      headers: {
        'API-Subscription-Key': key,
        'Content-Type': 'application/json',
      },
      responseType: ResponseType.json,
    ),
  );
  final urls = res.data?['download_urls'] as Map<String, dynamic>?;
  final entry = urls?[outputFilename] as Map<String, dynamic>?;
  final url = entry?['file_url'] as String?;
  if (url == null) throw Exception('Sarvam did not return a download URL.');
  return url;
}

Future<String> _sarvamDownloadTranscript(Dio dio, String presignedUrl) async {
  final res = await dio.get<dynamic>(
    presignedUrl,
    options: Options(responseType: ResponseType.plain),
  );
  final raw = res.data?.toString() ?? '';
  final json = jsonDecode(raw) as Map<String, dynamic>?;

  final segments = _readDiarizedSegments(json?['diarized_transcript']);
  if (segments != null && segments.isNotEmpty) {
    return _buildDiarizedText(segments);
  }
  return (json?['transcript'] as String?) ?? '';
}

List? _readDiarizedSegments(dynamic raw) {
  if (raw is List) return raw;
  if (raw is Map) {
    final entries = raw['entries'] ?? raw['segments'];
    if (entries is List) return entries;
  }
  return null;
}

String _buildDiarizedText(List segments) {
  final buf = StringBuffer();
  for (final seg in segments.cast<Map<String, dynamic>>()) {
    final id = seg['speaker_id']?.toString() ?? '0';
    final text = (seg['transcript'] as String?)?.trim() ?? '';
    if (text.isNotEmpty) buf.writeln('SPEAKER_$id: $text');
  }
  return buf.toString().trim();
}

// ── Gemini extraction ────────────────────────────────────────────────────────
// Mirrors InsightService.extract — same instructions, same schema, same config.

final _speakerPattern = RegExp(r'SPEAKER_\d+:');

Future<Map<String, dynamic>> _geminiExtract(
  Dio dio,
  String key,
  String rawTranscript,
) async {
  final isDiarized = _speakerPattern.hasMatch(rawTranscript);
  print('  [Gemini] Path: ${isDiarized ? "diarized" : "plain"}');

  final url = '$_geminiBase/models/$_geminiModel:generateContent?key=$key';

  final instruction = isDiarized ? _diarizedInstruction : _plainInstruction;
  final schema = isDiarized ? _diarizedSchema : _plainSchema;

  final body = {
    'systemInstruction': {
      'parts': [
        {'text': instruction},
      ],
    },
    'contents': [
      {
        'role': 'user',
        'parts': [
          {'text': rawTranscript},
        ],
      },
    ],
    'generationConfig': {
      'temperature': 0.3,
      'responseMimeType': 'application/json',
      'responseSchema': schema,
      'maxOutputTokens': 4096,
      'thinkingConfig': {'thinkingBudget': 1024},
    },
  };

  final res = await dio.post<Map<String, dynamic>>(
    url,
    data: jsonEncode(body),
    options: Options(
      headers: {'Content-Type': 'application/json'},
      responseType: ResponseType.json,
    ),
  );

  final rawJson = _extractGeminiJson(res.data);
  final decoded = jsonDecode(rawJson) as Map<String, dynamic>;

  if (isDiarized) {
    final doctorId = (decoded['doctor_speaker_id'] as String? ?? '').trim();
    final patientId = (decoded['patient_speaker_id'] as String? ?? '').trim();
    print('  [Gemini] Doctor→$doctorId  Patient→$patientId');
  }

  return _coerce(decoded);
}

String _extractGeminiJson(Map<String, dynamic>? data) {
  if (data == null) return '{}';
  final candidates = data['candidates'] as List<dynamic>?;
  if (candidates == null || candidates.isEmpty) return '{}';
  final parts =
      (candidates.first as Map)['content']?['parts'] as List<dynamic>?;
  if (parts == null || parts.isEmpty) return '{}';
  return parts.map((p) => (p as Map)['text'] ?? '').join('').toString();
}

final _icdPattern = RegExp(r'^[A-Z]\d{2}(\.[0-9A-Z]{1,4})?$');

Map<String, dynamic> _coerce(Map<String, dynamic> input) {
  final meds =
      (input['medications'] as List?)?.map((m) {
        if (m is! Map) return {'name': m.toString()};
        return {
          'name': m['name'] ?? '',
          'dosage': m['dosage'] ?? '',
          'frequency': m['frequency'] ?? '',
          'duration': m['duration'] ?? '',
          'timing': m['timing'] ?? '',
          'needsReview': m['needsReview'] ?? m['needs_review'] ?? false,
        };
      }).toList() ??
      const <Map<String, dynamic>>[];

  final rawIcd = input['icdCode'];
  final icdCode = rawIcd is String && _icdPattern.hasMatch(rawIcd)
      ? rawIcd
      : null;
  final rawDesc = input['icdDescription'];
  final icdDescription =
      icdCode != null && rawDesc is String && rawDesc.isNotEmpty
      ? rawDesc
      : null;
  final rawConf = input['icdConfidence'];
  final icdConfidence =
      icdCode != null &&
          rawConf is String &&
          (rawConf == 'high' || rawConf == 'medium')
      ? rawConf
      : null;

  return {
    'consultationSummary':
        input['consultationSummary'] ?? input['consultation_summary'] ?? '',
    'symptoms': input['symptoms'] ?? const <String>[],
    'diagnosis': input['diagnosis'] ?? '',
    'differentials': input['differentials'] ?? const <String>[],
    'medications': meds,
    'tests': input['tests'] ?? const <String>[],
    'advice': input['advice'] ?? const <String>[],
    'instructions': input['instructions'] ?? const <String>[],
    'followUpDays': input['followUpDays'] ?? input['follow_up_days'],
    'doctorNotes': input['doctorNotes'] ?? input['doctor_notes'] ?? '',
    'icdCode': icdCode,
    'icdDescription': icdDescription,
    'icdConfidence': icdConfidence,
  };
}

// ── Gemini system instructions (verbatim from InsightService) ────────────────

const _plainInstruction =
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
    '(null followUpDays). Output strict JSON per schema. '
    'For the instructions field, write in simple, clear prescription language '
    'that a doctor would naturally write on a prescription pad. Use "Take" not '
    '"Administer". Use "before bed" not "prior to sleep". Keep each instruction '
    'short and direct. Examples of good instruction style: '
    '"Take Paracetamol 650mg after food", "Take Cetirizine at bedtime", '
    '"Drink plenty of water and take rest", "Avoid cold food and drinks", '
    '"Return after 3 days if fever persists". '
    'Do not repeat dosage, frequency, or duration details that are already '
    'captured in the medications list — only include timing relative to meals, '
    'special precautions, lifestyle advice, and follow-up guidance. '
    'Pay special attention to follow-up instructions. If the doctor mentions '
    'ANY of these: "come back", "return", "wapas aana", "follow up", "phir '
    'aana", "check-up ke liye aana", or any indication of a return visit with '
    'a timeframe, extract the followUpDays as a number. If a timeframe is '
    'mentioned but vague (e.g. "come back if not better"), set followUpDays to '
    'null but include the instruction in the instructions field. '
    'For the diagnosis, if it maps clearly and unambiguously to a single '
    'ICD-10 code, provide the code with icdConfidence "high". If it could '
    'reasonably map to a code but there is some ambiguity (e.g. multiple '
    'possible codes, or the diagnosis is somewhat general), provide your best '
    'code with icdConfidence "medium". If you are not reasonably confident, '
    'return null for icdCode, icdDescription, and icdConfidence — do not guess.';

const _diarizedInstruction =
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
    '(null followUpDays). Output strict JSON per schema. '
    'For the instructions field, write in simple, clear prescription language '
    'that a doctor would naturally write on a prescription pad. Use "Take" not '
    '"Administer". Use "before bed" not "prior to sleep". Keep each instruction '
    'short and direct. Examples of good instruction style: '
    '"Take Paracetamol 650mg after food", "Take Cetirizine at bedtime", '
    '"Drink plenty of water and take rest", "Avoid cold food and drinks", '
    '"Return after 3 days if fever persists". '
    'Do not repeat dosage, frequency, or duration details that are already '
    'captured in the medications list — only include timing relative to meals, '
    'special precautions, lifestyle advice, and follow-up guidance. '
    'Pay special attention to follow-up instructions. If the doctor mentions '
    'ANY of these: "come back", "return", "wapas aana", "follow up", "phir '
    'aana", "check-up ke liye aana", or any indication of a return visit with '
    'a timeframe, extract the followUpDays as a number. If a timeframe is '
    'mentioned but vague (e.g. "come back if not better"), set followUpDays to '
    'null but include the instruction in the instructions field. '
    'For the diagnosis, if it maps clearly and unambiguously to a single '
    'ICD-10 code, provide the code with icdConfidence "high". If it could '
    'reasonably map to a code but there is some ambiguity (e.g. multiple '
    'possible codes, or the diagnosis is somewhat general), provide your best '
    'code with icdConfidence "medium". If you are not reasonably confident, '
    'return null for icdCode, icdDescription, and icdConfidence — do not guess.';

// ── Gemini schemas (verbatim from InsightService) ────────────────────────────

const _diarizedSchema = {
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
    'icdCode': {'type': 'STRING', 'nullable': true},
    'icdDescription': {'type': 'STRING', 'nullable': true},
    'icdConfidence': {'type': 'STRING', 'nullable': true},
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

const _plainSchema = {
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
    'icdCode': {'type': 'STRING', 'nullable': true},
    'icdDescription': {'type': 'STRING', 'nullable': true},
    'icdConfidence': {'type': 'STRING', 'nullable': true},
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

// ── Dio setup ────────────────────────────────────────────────────────────────

Dio _buildDio() => Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(minutes: 5),
    receiveTimeout: const Duration(minutes: 5),
  ),
);

// ── Utilities ────────────────────────────────────────────────────────────────

/// Minimal flag parser: supports `--key value`, `--key=value`, and bare
/// boolean flags like `--debug`. Avoids pulling in an extra dependency.
Map<String, String> _parseArgs(List<String> args) {
  const valueFlags = {'env', 'audio'};
  final map = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (!arg.startsWith('--')) continue;
    final body = arg.substring(2);
    final eq = body.indexOf('=');
    if (eq >= 0) {
      map[body.substring(0, eq)] = body.substring(eq + 1);
    } else if (valueFlags.contains(body) && i + 1 < args.length) {
      map[body] = args[++i];
    } else {
      map[body] = '';
    }
  }
  return map;
}

Map<String, String> _parseEnv(String raw) {
  final map = <String, String>{};
  for (final line in raw.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final idx = trimmed.indexOf('=');
    if (idx < 0) continue;
    map[trimmed.substring(0, idx).trim()] = trimmed.substring(idx + 1).trim();
  }
  return map;
}

String _s(double sec) => '${sec.toStringAsFixed(2)}s';

void _header(String title) {
  print('\n${'=' * 60}');
  print(title);
  print('=' * 60);
}

void _divider(String title) {
  print('\n${'─' * 60}');
  print(title);
  print('─' * 60);
}

// ── Result model ─────────────────────────────────────────────────────────────

class _RunResult {
  _RunResult({
    required this.run,
    this.sttSec,
    this.gemSec,
    this.totalSec,
    this.error,
  });

  final int run;
  final double? sttSec;
  final double? gemSec;
  final double? totalSec;
  final String? error;
}

// Dart 3 extension for null-safe firstOrNull on List
extension _ListFirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
