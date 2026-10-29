import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/errors/failure.dart';
import '../../../data/repositories/visit_repository.dart';
import '../../../services/differential_engine.dart';
import '../data/consultation_processor.dart';
import '../data/pending_consultations.dart';
import '../data/recording_service.dart';

// These lived here before the processing moved to ConsultationProcessor;
// screens and tests still import them from this file.
export '../data/consultation_processor.dart'
    show icd10MapperProvider, drugCorrectorProvider, differentialEngineProvider;

enum ConsultationStage {
  idle,
  recording,
  transcribing,
  extracting,
  done,
  error,

  /// Recorded without internet (or the doctor chose "process later"): the
  /// recording is safe on the phone and waits in the queue.
  queued,
}

/// Transcript accumulated across one consultation's recording sessions — the
/// initial recording plus any "Add More" appends. It is passed to the backend
/// pipeline as `previousTranscript` so adding more audio re-extracts over the
/// whole consultation rather than just the new segment; the pipeline returns
/// the full combined transcript, which is stored back here for the next append.
///
/// Reset to '' when a fresh consultation begins (in the intake screen, before
/// navigating to recording), when the current one is discarded, and when a
/// different doctor signs in, so one doctor's consultation never carries into
/// another's.
final cumulativeTranscriptProvider = StateProvider<String>((ref) {
  ref.watch(currentUserIdProvider);
  return '';
});

class ConsultationState {
  const ConsultationState({
    this.stage = ConsultationStage.idle,
    this.languageCode = 'unknown',
    this.elapsed = Duration.zero,
    this.error,
    this.errorCode,
    this.audioPath,
    this.differentialSuggestions = const [],
  });

  final ConsultationStage stage;
  final String languageCode;
  final Duration elapsed;

  /// Developer-readable detail of the last failure, for logs.
  final String? error;

  /// What kind of failure [error] is, so the screen can explain it in the
  /// doctor's language and offer the right recovery.
  final FailureCode? errorCode;

  /// The last finished recording. Kept when processing fails so the doctor can
  /// retry with the same audio instead of recording the consultation again.
  final String? audioPath;

  /// The recording held no consultation (muted mic, only noise).
  bool get nothingHeard => errorCode == FailureCode.invalidAudio;

  /// Processing failed for a reason a second attempt can fix (connection,
  /// server, session). Retrying a recording with nothing in it cannot help.
  bool get canRetryProcessing =>
      stage == ConsultationStage.error && audioPath != null && !nothingHeard;

  /// Doctor-only differential-diagnosis suggestions from [DifferentialEngine],
  /// computed from the extracted symptoms after processing. These are decision
  /// support: they never auto-fill the diagnosis and never reach the patient
  /// PDF (they live only on this transient state, not on the visit/insight).
  final List<DifferentialMatch> differentialSuggestions;

  ConsultationState copyWith({
    ConsultationStage? stage,
    String? languageCode,
    Duration? elapsed,
    String? error,
    FailureCode? errorCode,
    bool clearError = false,
    String? audioPath,
    bool clearAudio = false,
    List<DifferentialMatch>? differentialSuggestions,
  }) {
    return ConsultationState(
      stage: stage ?? this.stage,
      languageCode: languageCode ?? this.languageCode,
      elapsed: elapsed ?? this.elapsed,
      error: clearError ? null : (error ?? this.error),
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      audioPath: clearAudio ? null : (audioPath ?? this.audioPath),
      // Differential suggestions are decision support tied to a completed
      // consultation. Preserve them only while the state remains (or becomes)
      // `done`; any other stage transition clears them so stale suggestions
      // never leak into a new recording/processing cycle.
      differentialSuggestions:
          differentialSuggestions ??
          ((stage ?? this.stage) == ConsultationStage.done
              ? this.differentialSuggestions
              : const <DifferentialMatch>[]),
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
        clearAudio: true,
      );
      await _recorder.start();
    } catch (e) {
      _fail(e, 'Could not start recording');
    }
  }

  Future<void> stopAndProcess() async {
    final path = await _stopAndSaveRecording();
    if (path != null) await _process(path);
  }

  /// Finishes a consultation recorded without internet: the recording is kept
  /// on the phone and the visit joins the queue, to be processed when the
  /// connection is back (roadmap items 13, 14). The doctor is free to see the
  /// next patient instead of being held on this screen.
  Future<void> stopAndQueue() async {
    final path = await _stopAndSaveRecording();
    if (path != null) await _queue();
  }

  /// "Process later" after a failed attempt: the recording already saved
  /// joins the queue instead of being retried now.
  Future<void> queueForLater() async {
    if (state.audioPath == null || state.stage != ConsultationStage.error) {
      return;
    }
    await _queue();
  }

  Future<void> _queue() async {
    try {
      await ref.read(pendingConsultationsProvider.notifier).enqueue(visitId);
      state = state.copyWith(stage: ConsultationStage.queued, clearError: true);
    } catch (e) {
      _fail(e, 'Could not save the recording for later');
    }
  }

  /// Stops the recorder and stores the file on the visit. Returns null (with
  /// the state already in `error`) when that fails.
  Future<String?> _stopAndSaveRecording() async {
    try {
      final stopped = await _recorder.stop();
      if (stopped == null) {
        throw const StorageFailure('No audio was captured.');
      }
      state = state.copyWith(stage: ConsultationStage.transcribing);
      final visit = await _visits.byId(visitId);
      if (visit == null) {
        throw const StorageFailure('Visit record missing from local DB.');
      }
      await _visits.upsert(
        visit.copyWith(audioPath: stopped, languageCode: state.languageCode),
      );
      state = state.copyWith(audioPath: stopped);
      return stopped;
    } catch (e) {
      _fail(e, 'Could not save the recording');
      return null;
    }
  }

  /// Processes the recording that failed last time again, without recording
  /// the consultation a second time (roadmap item 10).
  Future<void> retryProcessing() async {
    final path = state.audioPath;
    if (path == null || state.stage != ConsultationStage.error) return;
    await _process(path);
  }

  Future<void> _process(String path) async {
    try {
      state = state.copyWith(
        stage: ConsultationStage.transcribing,
        clearError: true,
      );

      final probed = await _recorder.probeDuration(path);
      final fallback = state.elapsed > Duration.zero ? state.elapsed : null;

      // Pipeline + on-device post-processing, shared with the offline queue
      // so both produce the same prescription. On "nothing heard" it throws
      // and leaves the stored visit and transcript as they were, so an
      // "Add More" consultation keeps what it already had.
      final processed = await ref
          .read(consultationProcessorProvider)
          .process(
            visitId: visitId,
            audioPath: path,
            languageCode: state.languageCode,
            audioDuration: probed ?? fallback,
            previousTranscript: ref.read(cumulativeTranscriptProvider),
          );

      // Commit the accumulated transcript only after the DB write succeeds —
      // prevents a failed segment from polluting future "Add More" runs. The
      // backend returns the full combined transcript, so store that verbatim.
      ref.read(cumulativeTranscriptProvider.notifier).state =
          processed.visit.transcript ?? '';

      state = state.copyWith(
        stage: ConsultationStage.done,
        differentialSuggestions: processed.suggestions,
      );
    } catch (e) {
      _fail(e, 'Processing failed');
    }
  }

  void _fail(Object e, String what) {
    debugPrint('[consultation] $what: $e');
    state = state.copyWith(
      stage: ConsultationStage.error,
      error: e is Failure ? e.message : '$what: $e',
      errorCode: e is Failure ? e.code : FailureCode.unknown,
    );
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
