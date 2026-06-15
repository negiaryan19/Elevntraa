import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/config/env.dart';
import '../../../core/errors/failure.dart';
import 'stt_service.dart';

/// Alternative STT impl: send the audio directly to Gemini 2.5 as
/// multimodal input. Useful for benchmarking against Sarvam. The
/// production default is Sarvam (see [SttService]).
class GeminiAudioSttService implements SttService {
  GeminiAudioSttService(this._dio);

  final Dio _dio;

  @override
  Future<String> transcribe(
    String path, {
    String languageCode = 'unknown',
    Duration? audioDuration,
  }) async {
    final key = Env.geminiApiKey;
    if (key == null || key.isEmpty) {
      throw const ApiFailure('Gemini API key is not configured.');
    }
    final file = File(path);
    if (!file.existsSync()) {
      throw const StorageFailure('Recording file not found.');
    }

    // Gemini inline_data caps at ~20 MB after base64 expansion (≈15 MB raw).
    // Past that, callers should use the Files API. Fail fast so the doctor
    // sees a useful message instead of a generic HTTP 400.
    const maxRawBytes = 15 * 1024 * 1024;
    final size = file.lengthSync();
    if (size > maxRawBytes) {
      throw ApiFailure(
        'Recording is ${(size / 1024 / 1024).toStringAsFixed(1)} MB — '
        'too large for Gemini inline upload. Use Sarvam for long recordings.',
      );
    }

    final bytes = await file.readAsBytes();
    final b64 = base64Encode(bytes);
    final mime = _mimeFor(path);

    final url =
        '${Env.geminiEndpointBase}/models/${Env.geminiModel}:generateContent?key=$key';

    final hint = languageCode == 'unknown'
        ? 'Auto-detect the spoken language (Indian languages or English are likely).'
        : 'The audio is in language code "$languageCode".';

    final body = {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {
              'text':
                  'This is a doctor-patient consultation recording with two '
                  'speakers. Transcribe verbatim, labeling each speaker as '
                  '"Doctor:" or "Patient:" (the doctor typically speaks first). '
                  '$hint Preserve code-mixed Hindi/English exactly as spoken. '
                  'Output only the labeled transcript.',
            },
            {
              'inline_data': {'mime_type': mime, 'data': b64},
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.0,
        'responseMimeType': 'text/plain',
        // Verbatim transcription needs no reasoning budget — disabling Gemini
        // 2.5 "thinking" cuts the token cost substantially.
        'thinkingConfig': {'thinkingBudget': 0},
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
      final text = _extractText(res.data);
      if (text.trim().isEmpty) {
        throw const ApiFailure('Gemini returned an empty transcript.');
      }
      return text.trim();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  String _extractText(Map<String, dynamic>? data) {
    if (data == null) return '';
    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) return '';
    final parts =
        (candidates.first as Map)['content']?['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) return '';
    return parts.map((p) => (p as Map)['text'] ?? '').join('').toString();
  }

  String _mimeFor(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.m4a') || lower.endsWith('.mp4')) return 'audio/mp4';
    if (lower.endsWith('.aac')) return 'audio/aac';
    if (lower.endsWith('.wav')) return 'audio/wav';
    if (lower.endsWith('.mp3')) return 'audio/mpeg';
    if (lower.endsWith('.ogg') || lower.endsWith('.opus')) return 'audio/ogg';
    return 'audio/mp4';
  }

  Failure _mapDioError(DioException e) {
    final code = e.response?.statusCode;
    if (code == 401 || code == 403) {
      return ApiFailure('Gemini rejected the API key.', statusCode: code);
    }
    if (code != null && code >= 400) {
      final detail =
          _readGeminiError(e.response?.data) ??
          e.response?.statusMessage ??
          'Bad request';
      return ApiFailure('Gemini HTTP $code: $detail', statusCode: code);
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return NetworkFailure(
        'Could not reach Gemini — check your connection.',
        cause: e,
      );
    }
    return UnknownFailure(
      'Gemini transcription failed: ${e.message}',
      cause: e,
    );
  }

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
}
