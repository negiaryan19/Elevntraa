import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/errors/failure.dart';
import '../../../data/repositories/visit_repository.dart';
import '../../../services/differential_engine.dart';
import '../../../services/icd10_local_mapper.dart';
import '../../../services/drug_name_corrector.dart';
import '../data/pipeline_service.dart';
import '../data/recording_service.dart';

/// On-device WHO ICD-10 lookup table, loaded once from the bundled asset and
/// cached for the app's lifetime. The LLM extracts the diagnosis TEXT only;
/// this deterministic mapper assigns the code. See [Icd10LocalMapper].
final icd10MapperProvider = FutureProvider<Icd10LocalMapper>(
  (ref) => Icd10LocalMapper.load(),
);

/// Loads the romanization-aware drug-name corrector. Maps mangled / romanized
/// STT drug names to their canonical forms on-device, so mangled names get
/// fixed regardless of which STT produced them. See [DrugNameCorrector].
final drugCorrectorProvider = FutureProvider<DrugNameCorrector>(
  (ref) => DrugNameCorrector.load(),
);

/// On-device differential-diagnosis engine, loaded once from the bundled
/// rules asset. Turns the extracted symptoms into ranked, doctor-only
/// decision-support suggestions. See [DifferentialEngine].
final differentialEngineProvider = FutureProvider<DifferentialEngine>(
  (ref) => DifferentialEngine.load(),
);

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
    this.differentialSuggestions = const [],
  });

  final ConsultationStage stage;
  final String languageCode;
  final Duration elapsed;
  final String? error;

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
    bool clearError = false,
    List<DifferentialMatch>? differentialSuggestions,
  }) {
    return ConsultationState(
      stage: stage ?? this.stage,
      languageCode: languageCode ?? this.languageCode,
      elapsed: elapsed ?? this.elapsed,
      error: clearError ? null : (error ?? this.error),
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

      // NOTE: There is no validateExtraction() step in this controller, so
      // POINT B does not exist — data cannot be lost to validation here.

      // ICD-10 is assigned on-device from a curated WHO map, not by the LLM.
      // The mapper output ALWAYS overwrites the extractor's ICD fields —
      // including clearing all three when there is no confident match — so the
      // doctor never sees a guessed code. On IcdMatch.none the field is left
      // null for the doctor to fill, exactly like today.
      // Correct mangled / romanized drug names to canonical forms on-device.
      // Same matching engine the backend validateExtraction uses, so a name
      // gets fixed no matter which STT produced it.
      final corrector = await ref.read(drugCorrectorProvider.future);
      final correctedMeds = [
        for (final med in result.insight.medications)
          () {
            final corrected = corrector.correct(med.name);
            return corrected != null && corrected.canonical != med.name
                ? med.copyWith(
                    name: corrected.canonical,
                    originalName: med.name,
                  )
                : med;
          }(),
      ];

      final mapper = await ref.read(icd10MapperProvider.future);
      final icd = mapper.lookup(result.insight.diagnosis);
      final insight = result.insight.copyWith(
        medications: correctedMeds,
        icdCode: icd.code,
        icdDescription: icd.description,
        icdConfidence: icd.confidence,
      );

      // Differential-diagnosis decision support — computed on-device from the
      // extracted symptoms. Doctor-only: held on transient state, never written
      // to the visit/insight and never rendered on the patient PDF, and it
      // never auto-fills the diagnosis field.
      final diffEngine = await ref.read(differentialEngineProvider.future);
      final suggestions = diffEngine.suggest(result.insight.symptoms);

      final current = await _visits.byId(visitId);
      if (current == null) {
        throw const StorageFailure('Visit record missing from local DB.');
      }
      final updated = current.copyWith(
        transcript: result.transcript,
        insight: insight,
      );
      await _visits.upsert(updated);

      // Commit the accumulated transcript only after the DB write succeeds —
      // prevents a failed segment from polluting future "Add More" runs. The
      // backend returns the full combined transcript, so store that verbatim.
      ref.read(cumulativeTranscriptProvider.notifier).state = result.transcript;

      state = state.copyWith(
        stage: ConsultationStage.done,
        differentialSuggestions: suggestions,
      );
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
