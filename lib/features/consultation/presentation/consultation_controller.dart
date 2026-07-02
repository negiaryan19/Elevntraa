import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/errors/failure.dart';
import '../../../data/repositories/visit_repository.dart';
import '../data/pipeline_service.dart';
import '../data/recording_service.dart';

enum ConsultationStage {
  idle,
  recording,
  transcribing,
  extracting,
  done,
  error,
}

/// Transcript accumulated across one consultation's recording sessions — the
/// initial recording plus any "Add More" appends. It is passed to the backend
/// pipeline as `previousTranscript` so adding more audio re-extracts over the
/// whole consultation rather than just the new segment; the pipeline returns
/// the full combined transcript, which is stored back here for the next append.
///
/// Reset to '' when a fresh consultation begins (in the intake screen, before
/// navigating to recording) and when the current one is discarded.
final cumulativeTranscriptProvider = StateProvider<String>((ref) => '');

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

class ConsultationController extends Notifier<ConsultationState> {
  ConsultationController(this.visitId);
  final String visitId;

  @override
  ConsultationState build() => const ConsultationState();

  RecordingService get _recorder => ref.read(recordingServiceProvider);
  VisitRepository get _visits => ref.read(visitRepositoryProvider);

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

  Future<void> stopAndProcess() async {
    try {
      final path = await _recorder.stop();
      if (path == null) throw const StorageFailure('No audio was captured.');

      state = state.copyWith(stage: ConsultationStage.transcribing);

      final visit = await _visits.byId(visitId);
      if (visit == null) {
        throw const StorageFailure('Visit record missing from local DB.');
      }
      await _visits.upsert(
        visit.copyWith(audioPath: path, languageCode: state.languageCode),
      );

      final probed = await _recorder.probeDuration(path);
      final fallback = state.elapsed > Duration.zero ? state.elapsed : null;
      final effectiveDuration = probed ?? fallback;

      // Single unified call — the backend pipeline handles STT + extraction and,
      // when a prior transcript is supplied, the "Add More" accumulation too.
      // The returned result already contains the full combined transcript plus
      // the re-extracted insight, so there is no client-side combining left.
      final previous = ref.read(cumulativeTranscriptProvider);
      final result = await ref
          .read(pipelineServiceProvider)
          .processConsultation(
            audioPath: path,
            languageCode: state.languageCode,
            audioDuration: effectiveDuration,
            previousTranscript: previous.trim().isEmpty ? null : previous,
          );

      final current = await _visits.byId(visitId);
      if (current == null) {
        throw const StorageFailure('Visit record missing from local DB.');
      }
      final updated = current.copyWith(
        transcript: result.transcript,
        insight: result.insight,
      );
      await _visits.upsert(updated);

      // Commit the accumulated transcript only after the DB write succeeds —
      // prevents a failed segment from polluting future "Add More" runs. The
      // backend returns the full combined transcript, so store that verbatim.
      ref.read(cumulativeTranscriptProvider.notifier).state = result.transcript;

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

// Memoized so the same provider instance is returned for a given
// visitId across rebuilds — required for Riverpod to track state correctly.
final _providerCache =
    <String, NotifierProvider<ConsultationController, ConsultationState>>{};

NotifierProvider<ConsultationController, ConsultationState>
consultationControllerProvider(String visitId) {
  return _providerCache.putIfAbsent(
    visitId,
    () => NotifierProvider<ConsultationController, ConsultationState>(
      () => ConsultationController(visitId),
    ),
  );
}
