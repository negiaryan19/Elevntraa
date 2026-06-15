import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../../data/repositories/visit_repository.dart';
import '../data/insight_service.dart';
import '../data/recording_service.dart';
import '../data/stt_service.dart';

enum ConsultationStage {
  idle,
  recording,
  transcribing,
  extracting,
  done,
  error,
}

class ConsultationState {
  const ConsultationState({
    this.stage = ConsultationStage.idle,
    this.languageCode = 'unknown',
    this.elapsed = Duration.zero,
    this.error,
  });

  final ConsultationStage stage;
  final String languageCode;
  final Duration elapsed;
  final String? error;

  ConsultationState copyWith({
    ConsultationStage? stage,
    String? languageCode,
    Duration? elapsed,
    String? error,
    bool clearError = false,
  }) {
    return ConsultationState(
      stage: stage ?? this.stage,
      languageCode: languageCode ?? this.languageCode,
      elapsed: elapsed ?? this.elapsed,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Per-visit notifier — created with `family` so each visit gets its own
/// state and we don't leak between consultations.
class ConsultationController extends StateNotifier<ConsultationState> {
  ConsultationController(this._ref, this.visitId)
    : super(const ConsultationState());

  final Ref _ref;
  final String visitId;

  RecordingService get _recorder => _ref.read(recordingServiceProvider);
  SttService get _stt => _ref.read(sttServiceProvider);
  InsightService get _insight => _ref.read(insightServiceProvider);
  VisitRepository get _visits => _ref.read(visitRepositoryProvider);

  void setLanguage(String code) =>
      state = state.copyWith(languageCode: code, clearError: true);

  Future<void> startRecording() async {
    try {
      state = state.copyWith(
        stage: ConsultationStage.recording,
        elapsed: Duration.zero,
        clearError: true,
      );
      await _recorder.start();
    } catch (e) {
      state = state.copyWith(
        stage: ConsultationStage.error,
        error: e is Failure ? e.message : 'Could not start recording: $e',
      );
    }
  }

  /// Stop recording and run the full pipeline. On success the visit row
  /// has audioPath, transcript, languageCode, and insightJson filled in,
  /// and [state.stage] becomes [ConsultationStage.done] — the screen then
  /// navigates to /review/:visitId.
  Future<void> stopAndProcess() async {
    try {
      final path = await _recorder.stop();
      if (path == null) {
        throw const StorageFailure('No audio was captured.');
      }

      state = state.copyWith(stage: ConsultationStage.transcribing);

      final visit = await _visits.byId(visitId);
      if (visit == null) {
        throw const StorageFailure('Visit record missing from local DB.');
      }
      await _visits.upsert(
        visit.copyWith(audioPath: path, languageCode: state.languageCode),
      );

      // Probe the actual file duration — the UI timer (`state.elapsed`)
      // drifts under jank and pause/resume, so it can't be trusted to
      // pick the REST (<30s) vs Batch (>30s) path. If the probe fails
      // and the UI timer never started, pass null so STT defaults to
      // the safe Batch path.
      final probed = await _recorder.probeDuration(path);
      final fallback = state.elapsed > Duration.zero ? state.elapsed : null;
      final effectiveDuration = probed ?? fallback;

      final transcript = await _stt.transcribe(
        path,
        languageCode: state.languageCode,
        audioDuration: effectiveDuration,
      );

      state = state.copyWith(stage: ConsultationStage.extracting);

      final result = await _insight.extract(transcript);

      final updated = (await _visits.byId(visitId))!.copyWith(
        // Store the re-labeled transcript (Doctor:/Patient: lines) so the
        // Review screen shows a human-readable conversation.
        transcript: result.transcript,
        insight: result.insight,
      );
      await _visits.upsert(updated);

      state = state.copyWith(stage: ConsultationStage.done);
    } catch (e) {
      state = state.copyWith(
        stage: ConsultationStage.error,
        error: e is Failure ? e.message : 'Processing failed: $e',
      );
    }
  }

  Future<void> pauseRecording() => _recorder.pause();

  Future<void> resumeRecording() => _recorder.resume();

  Future<void> cancelRecording() async {
    await _recorder.cancel();
    state = state.copyWith(
      stage: ConsultationStage.idle,
      elapsed: Duration.zero,
    );
  }

  void tickElapsed(Duration d) {
    if (state.stage == ConsultationStage.recording) {
      state = state.copyWith(elapsed: d);
    }
  }

  void reset() => state = const ConsultationState();
}

final consultationControllerProvider =
    StateNotifierProvider.family<
      ConsultationController,
      ConsultationState,
      String
    >((ref, visitId) {
      return ConsultationController(ref, visitId);
    });
