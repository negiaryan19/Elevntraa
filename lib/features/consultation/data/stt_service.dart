import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import 'gemini_audio_stt_service.dart';
import 'sarvam_stt_service.dart';

/// Single seam for speech-to-text engines. Swapping the implementation is
/// a one-line provider change (see [sttServiceProvider]).
abstract class SttService {
  /// Transcribes the audio file at [path].
  ///
  /// [languageCode] is BCP-47 (`hi-IN`, `od-IN`, …) or `'unknown'` for
  /// auto-detect.
  ///
  /// [audioDuration] is the known recording length. Implementations may use
  /// it to choose between a fast REST path (≤30 s) and an async Batch path
  /// (>30 s). Pass `null` when the duration is unknown — the implementation
  /// will fall back to the safe Batch path.
  Future<String> transcribe(
    String path, {
    String languageCode = 'unknown',
    Duration? audioDuration,
  });
}

/// Production default — Sarvam Saaras v3. To benchmark Gemini's audio
/// model, change this to `GeminiAudioSttService(...)` and rebuild.
final sttServiceProvider = Provider<SttService>((ref) {
  return SarvamSttService(ref.watch(dioProvider));
});

/// Same-shape provider for the alternative engine — pre-wired so the
/// review screen could A/B them without touching consultation code.
final geminiAudioSttServiceProvider = Provider<SttService>((ref) {
  return GeminiAudioSttService(ref.watch(dioProvider));
});
