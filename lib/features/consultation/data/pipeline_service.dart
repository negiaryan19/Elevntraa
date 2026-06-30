import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/failure.dart';
import '../../../domain/models/medical_insight.dart';
import 'insight_service.dart';

/// Backend pipeline service — replaces the on-device Sarvam + Gemini pair.
///
/// Uploads the audio to the consultation-audio bucket, invokes the
/// process-consultation Edge Function, and handles the sync/async response
/// modes. Async mode polls check-job-status until completion or timeout.
class PipelineService {
  static const _bucket = 'consultation-audio';
  static const _pollInterval = Duration(seconds: 3);
  static const _maxPollDuration = Duration(minutes: 20);

  Future<InsightResult> processConsultation({
    required String audioPath,
    required String languageCode,
    Duration? audioDuration,
  }) async {
    final client = Supabase.instance.client;

    final session = client.auth.currentSession;
    if (session == null) {
      throw const ApiFailure('Not authenticated with backend.');
    }
    final userId = session.user.id;

    final jobUuid = const Uuid().v4();
    final ext = audioPath.contains('.')
        ? audioPath.substring(audioPath.lastIndexOf('.'))
        : '.m4a';
    final storagePath = '$userId/$jobUuid$ext';

    // Step 1 — upload audio
    try {
      final bytes = await File(audioPath).readAsBytes();
      await client.storage
          .from(_bucket)
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'audio/mp4',
              upsert: false,
            ),
          );
    } on StorageException catch (e) {
      throw ApiFailure('Audio upload failed: ${e.message}', cause: e);
    } catch (e) {
      throw NetworkFailure('Audio upload failed: $e', cause: e);
    }

    // Step 2 — invoke Edge Function
    final FunctionResponse response;
    try {
      response = await client.functions.invoke(
        'process-consultation',
        body: {
          'audioPath': storagePath,
          'languageCode': languageCode,
          if (audioDuration != null)
            'audioDurationSeconds': audioDuration.inSeconds,
        },
      );
    } on FunctionException catch (e) {
      throw ApiFailure('Pipeline function error: ${e.details}', cause: e);
    } catch (e) {
      throw NetworkFailure('Could not reach backend: $e', cause: e);
    }

    if (response.status != 200) {
      final body = response.data;
      final msg = body is Map
          ? (body['error'] ?? body.toString())
          : body.toString();
      throw ApiFailure(
        'Pipeline returned HTTP ${response.status}: $msg',
        statusCode: response.status,
      );
    }

    // Step 3 — handle sync vs async response
    final data = response.data as Map<String, dynamic>;
    final mode = data['mode'] as String?;

    if (mode == 'sync') {
      return _parseResult(data);
    }

    if (mode == 'async') {
      final jobId = data['jobId'] as String;
      return _pollUntilDone(jobId);
    }

    throw ApiFailure('Unknown pipeline response mode: $mode');
  }

  Future<InsightResult> _pollUntilDone(String jobId) async {
    final client = Supabase.instance.client;
    final deadline = DateTime.now().add(_maxPollDuration);

    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(_pollInterval);

      final FunctionResponse poll;
      try {
        poll = await client.functions.invoke(
          'check-job-status',
          body: {'jobId': jobId},
        );
      } on FunctionException catch (e) {
        throw ApiFailure('Status check error: ${e.details}', cause: e);
      } catch (e) {
        throw NetworkFailure('Could not reach backend: $e', cause: e);
      }

      final result = poll.data as Map<String, dynamic>;
      final status = result['status'] as String?;

      if (status == 'running') continue;

      if (status == 'done') return _parseResult(result);

      if (status == 'failed') {
        final err = result['error'] as String? ?? 'Unknown pipeline error';
        throw ApiFailure('Transcription failed: $err');
      }

      throw ApiFailure('Unexpected job status: $status');
    }

    throw const ApiFailure('Transcription timed out after 20 minutes.');
  }

  InsightResult _parseResult(Map<String, dynamic> data) {
    final transcript = data['transcript'] as String? ?? '';
    final insightJson = data['insight'] as Map<String, dynamic>? ?? {};
    final insight = MedicalInsight.fromJson(insightJson);
    return InsightResult(transcript: transcript, insight: insight);
  }
}

final pipelineServiceProvider = Provider<PipelineService>((ref) {
  return PipelineService();
});
