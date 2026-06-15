import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/config/env.dart';
import '../../../core/errors/failure.dart';
import 'stt_service.dart';

/// Sarvam Saaras v3 speech-to-text.
///
/// Routing logic:
///   • audio < 30 s  → REST  POST /speech-to-text           (immediate result)
///   • audio ≥ 30 s  → Batch POST /speech-to-text/job/v1    (async, up to 1 h)
///
/// The Batch path also enables speaker diarization (num_speakers=2), which
/// lets InsightService identify Doctor vs Patient from labelled segments.
class SarvamSttService implements SttService {
  SarvamSttService(this._dio);

  final Dio _dio;
  static const _base = 'https://api.sarvam.ai';
  // Sarvam REST rejects >30s. Probe drift + container padding can push a
  // "29s" recording over the wire as 30.x, so we keep a 2s safety margin.
  static const _restThresholdSeconds = 28;

  @override
  Future<String> transcribe(
    String path, {
    String languageCode = 'unknown',
    Duration? audioDuration,
  }) async {
    final key = Env.sarvamApiKey;
    if (key == null || key.isEmpty) {
      throw const ApiFailure('Sarvam API key is not configured.');
    }

    final file = File(path);
    if (!file.existsSync()) {
      throw const StorageFailure('Recording file not found.');
    }

    final size = file.lengthSync();
    if (size < 4 * 1024) {
      throw StorageFailure(
        'Recording is only ${size}B — probably silent. '
        'Try again, speak louder, or check microphone.',
      );
    }

    // Use REST for short clips; Batch for everything else.
    // If duration is unknown, default to Batch (safe for any length).
    final useBatch =
        audioDuration == null ||
        audioDuration.inSeconds >= _restThresholdSeconds;

    try {
      if (useBatch) {
        return await _transcribeBatch(key, path, languageCode);
      } else {
        return await _transcribeRest(key, path, languageCode);
      }
    } on Failure {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // ── REST path (≤ 30 s) ────────────────────────────────────────────────────

  Future<String> _transcribeRest(
    String key,
    String path,
    String languageCode,
  ) async {
    // codemix requires a specific language; fall back to transcribe for
    // auto-detect so the request doesn't 400.
    final mode = (languageCode == 'unknown') ? 'transcribe' : 'codemix';
    final filename = path.split(Platform.pathSeparator).last;
    final sizeKb = File(path).lengthSync() ~/ 1024;

    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        path,
        filename: filename,
        contentType: MediaType('audio', 'mp4'),
      ),
      'model': 'saaras:v3',
      'mode': mode,
      'language_code': languageCode,
    });

    final res = await _dio.post<Map<String, dynamic>>(
      '$_base/speech-to-text',
      data: form,
      options: Options(
        headers: {'API-Subscription-Key': key, 'Accept': 'application/json'},
        responseType: ResponseType.json,
      ),
    );

    final body = res.data;
    if (body == null) throw const ApiFailure('Empty response from Sarvam.');

    if (kDebugMode) {
      developer.log('REST response: $body', name: 'SarvamSTT');
    }

    final transcript = body['transcript'] as String?;
    if (transcript == null || transcript.trim().isEmpty) {
      final detected = body['language_code']?.toString();
      throw ApiFailure(
        'Sarvam heard the audio but produced no transcript '
        '(${detected ?? 'no language detected'}, $sizeKb KB sent). '
        'Speak louder or move closer to the mic.',
      );
    }
    return transcript;
  }

  // ── Batch path (≥ 30 s) ───────────────────────────────────────────────────

  Future<String> _transcribeBatch(
    String key,
    String path,
    String languageCode,
  ) async {
    final mode = (languageCode == 'unknown') ? 'transcribe' : 'codemix';
    final filename = path.split(Platform.pathSeparator).last;

    // 1. Initiate job
    final jobId = await _initiateJob(key, languageCode, mode);
    developer.log('Batch job created: $jobId', name: 'SarvamSTT');

    // 2. Get presigned upload URL
    final uploadUrl = await _getUploadUrl(key, jobId, filename);

    // 3. Upload file to cloud storage (presigned PUT — no API key in headers)
    await _uploadFile(uploadUrl, File(path));
    developer.log('File uploaded', name: 'SarvamSTT');

    // 4. Start job
    await _startJob(key, jobId);
    developer.log('Batch job started', name: 'SarvamSTT');

    // 5. Poll until Completed (3-minute timeout)
    final outputFilename = await _pollUntilComplete(key, jobId);
    developer.log('Job complete, output: $outputFilename', name: 'SarvamSTT');

    // 6. Get presigned download URL
    final downloadUrl = await _getDownloadUrl(key, jobId, outputFilename);

    // 7. Download and parse transcript JSON
    final transcript = await _downloadTranscript(downloadUrl);
    if (transcript.trim().isEmpty) {
      throw const ApiFailure(
        'Sarvam produced no transcript — likely silent audio.',
      );
    }
    return transcript;
  }

  Future<String> _initiateJob(
    String key,
    String languageCode,
    String mode,
  ) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '$_base/speech-to-text/job/v1',
      data: {
        'job_parameters': {
          'model': 'saaras:v3',
          'mode': mode,
          'language_code': languageCode,
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
    if (jobId == null) {
      throw const ApiFailure('Sarvam did not return a job_id.');
    }
    return jobId;
  }

  Future<String> _getUploadUrl(
    String key,
    String jobId,
    String filename,
  ) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '$_base/speech-to-text/job/v1/upload-files',
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
    if (url == null) {
      throw const ApiFailure('Sarvam did not return an upload URL.');
    }
    return url;
  }

  Future<void> _uploadFile(String presignedUrl, File file) async {
    final bytes = await file.readAsBytes();
    // Presigned URLs are self-authenticating — adding the Sarvam key header
    // would break the HMAC signature check on the storage side.
    // x-ms-blob-type is mandatory for Azure Blob PUT (Sarvam's storage
    // backend); without it Azure returns 400 MissingRequiredHeader and the
    // subsequent /start fails with "No files found.".
    final res = await _dio.put<dynamic>(
      presignedUrl,
      data: bytes,
      options: Options(
        headers: {'Content-Type': 'audio/mp4', 'x-ms-blob-type': 'BlockBlob'},
        contentType: 'audio/mp4',
        // Use bytes so any error body is handled by _decodeBody below.
        responseType: ResponseType.bytes,
        sendTimeout: const Duration(minutes: 5),
      ),
    );
    if ((res.statusCode ?? 0) >= 300) {
      final body = _decodeBody(res.data);
      final msg = _extractErrorDetail(body);
      throw ApiFailure('Upload failed (${res.statusCode}): $msg');
    }
  }

  Future<void> _startJob(String key, String jobId) async {
    await _dio.post<dynamic>(
      '$_base/speech-to-text/job/v1/$jobId/start',
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

  /// Polls every 3 s; times out after 20 minutes. Batch jobs for ~1h of
  /// audio routinely take 5-10 minutes to complete on the free tier; a
  /// 3-minute ceiling would kill legitimate jobs.
  Future<String> _pollUntilComplete(String key, String jobId) async {
    const interval = Duration(seconds: 3);
    final deadline = DateTime.now().add(const Duration(minutes: 20));

    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(interval);

      final res = await _dio.get<Map<String, dynamic>>(
        '$_base/speech-to-text/job/v1/$jobId/status',
        options: Options(
          headers: {'API-Subscription-Key': key},
          responseType: ResponseType.json,
        ),
      );

      final body = res.data;
      final jobState = body?['job_state'] as String?;
      developer.log('Job state: $jobState', name: 'SarvamSTT');

      if (jobState == 'Completed') {
        final details = (body?['job_details'] as List?)
            ?.cast<Map<String, dynamic>>();
        final outputs = (details?.firstOrNull?['outputs'] as List?)
            ?.cast<Map<String, dynamic>>();
        final outputFilename = outputs?.firstOrNull?['file_name'] as String?;
        if (outputFilename == null) {
          throw const ApiFailure('Job completed but no output file listed.');
        }
        return outputFilename;
      }

      if (jobState == 'Failed') {
        final msg = body?['error_message'] as String? ?? 'Unknown error';
        throw ApiFailure('Sarvam job failed: $msg');
      }
      // Accepted / Pending / Running → keep polling
    }

    throw const ApiFailure('Transcription timed out. Please try again.');
  }

  Future<String> _getDownloadUrl(
    String key,
    String jobId,
    String outputFilename,
  ) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '$_base/speech-to-text/job/v1/download-files',
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
    if (url == null) {
      throw const ApiFailure('Sarvam did not return a download URL.');
    }
    return url;
  }

  Future<String> _downloadTranscript(String presignedUrl) async {
    final res = await _dio.get<dynamic>(
      presignedUrl,
      options: Options(responseType: ResponseType.plain),
    );

    final raw = res.data?.toString() ?? '';
    final json = jsonDecode(raw) as Map<String, dynamic>?;

    if (kDebugMode) {
      developer.log('Transcript keys: ${json?.keys}', name: 'SarvamSTT');
    }

    // Prefer diarized output so InsightService can label Doctor vs Patient.
    // Sarvam returns `diarized_transcript` as `{"entries":[...]}` (current
    // shape); older docs showed a flat list — handle both.
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

  /// Converts Sarvam diarized segments to "SPEAKER_N: text" lines.
  /// InsightService's regex picks up this format to identify roles.
  String _buildDiarizedText(List segments) {
    final buf = StringBuffer();
    for (final seg in segments.cast<Map<String, dynamic>>()) {
      final id = seg['speaker_id']?.toString() ?? '0';
      final text = (seg['transcript'] as String?)?.trim() ?? '';
      if (text.isNotEmpty) buf.writeln('SPEAKER_$id: $text');
    }
    return buf.toString().trim();
  }

  // ── Error helpers ─────────────────────────────────────────────────────────

  /// Decodes a raw response body to a readable string.
  /// Handles raw byte lists (possibly with UTF-8 BOM), String, or Map.
  String _decodeBody(dynamic data) {
    if (data is List<int>) {
      String text = utf8.decode(data, allowMalformed: true);
      // Strip UTF-8 BOM (EF BB BF → U+FEFF) that Azure storage prepends.
      if (text.startsWith('﻿')) text = text.substring(1);
      return text;
    }
    if (data is String) return data;
    return data?.toString() ?? '';
  }

  /// Extracts a human-readable message from decoded JSON or XML body.
  String _extractErrorDetail(String rawBody) {
    final trimmed = rawBody.trimLeft();
    if (trimmed.startsWith('<')) {
      // XML error from cloud storage (Azure / GCS). Try common tags.
      for (final tag in ['Message', 'message', 'Error', 'error']) {
        final m = RegExp(
          '<$tag>(.*?)</$tag>',
          dotAll: true,
        ).firstMatch(rawBody);
        if (m != null) return m.group(1)?.trim() ?? rawBody;
      }
      return 'Cloud storage error (see logs).';
    }
    try {
      final json = jsonDecode(rawBody) as Map<String, dynamic>?;
      final err = json?['error'];
      if (err is Map) return (err['message'] as String? ?? '').trim();
      return (json?['message'] as String? ?? '').trim();
    } catch (_) {
      // Return a truncated raw string so the doctor sees something useful.
      return rawBody.length > 200 ? '${rawBody.substring(0, 200)}…' : rawBody;
    }
  }

  Failure _mapDioError(DioException e) {
    final code = e.response?.statusCode;
    final rawData = e.response?.data;
    final decoded = _decodeBody(rawData);
    developer.log('Sarvam $code raw: $decoded', name: 'SarvamSTT');

    if (code == 403) {
      String? errCode;
      try {
        final json = jsonDecode(decoded) as Map<String, dynamic>?;
        final err = json?['error'];
        if (err is Map) errCode = err['code']?.toString();
      } catch (_) {}
      if (errCode == 'invalid_api_key_error') {
        return const ApiFailure(
          'Sarvam rejected the API key. Check it in onboarding.',
          statusCode: 403,
        );
      }
      return ApiFailure(
        'Sarvam access denied: ${errCode ?? 'forbidden'}.',
        statusCode: 403,
      );
    }

    if (code != null && code >= 400) {
      final detail = _extractErrorDetail(decoded);
      final msg = detail.isNotEmpty
          ? detail
          : (e.response?.statusMessage ?? 'Bad Request');
      return ApiFailure('Sarvam $code: $msg', statusCode: code);
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return NetworkFailure(
        'Could not reach Sarvam — check your connection.',
        cause: e,
      );
    }
    return UnknownFailure('Transcription failed: ${e.message}', cause: e);
  }
}
