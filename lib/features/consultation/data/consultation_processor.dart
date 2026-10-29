import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../../data/repositories/visit_repository.dart';
import '../../../domain/models/medical_insight.dart';
import '../../../domain/models/visit.dart';
import '../../../services/differential_engine.dart';
import '../../../services/drug_name_corrector.dart';
import '../../../services/icd10_local_mapper.dart';
import 'pipeline_service.dart';

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

/// What one processed recording produced.
class ProcessedConsultation {
  const ProcessedConsultation({required this.visit, required this.suggestions});

  /// The visit as saved: transcript and insight filled in.
  final VisitRecord visit;

  /// Doctor-only differential suggestions. Decision support: never written to
  /// the visit, never printed, never auto-filled into the diagnosis.
  final List<DifferentialMatch> suggestions;
}

/// Turns one recording into the visit's transcript and insight: the backend
/// pipeline (speech-to-text + extraction), then the on-device steps — drug
/// names corrected to their canonical form, the ICD-10 code assigned from the
/// curated map, differential suggestions computed.
///
/// One implementation on purpose. It runs while the doctor waits
/// (`ConsultationController`) and later, in the background, for a recording
/// made without internet (`PendingConsultations`); a consultation must come
/// out the same either way.
class ConsultationProcessor {
  ConsultationProcessor(this._ref);

  final Ref _ref;

  /// Processes [audioPath] for [visitId] and saves the result on the visit.
  ///
  /// Throws a [Failure]: [FailureCode.invalidAudio] when the recording held no
  /// consultation (the visit is left exactly as it was, so an "Add more"
  /// consultation keeps what it already had), [FailureCode.network] when the
  /// backend could not be reached, and so on. Nothing is saved on failure.
  Future<ProcessedConsultation> process({
    required String visitId,
    required String audioPath,
    required String languageCode,
    Duration? audioDuration,
    String? previousTranscript,
  }) async {
    final previous = previousTranscript?.trim() ?? '';

    // Everything this run needs is taken NOW, before the first await. The
    // pipeline call below can take minutes; if the doctor signs out meanwhile,
    // `visitRepositoryProvider` starts pointing at another database and this
    // provider's ref may be gone. A run in flight must finish against the
    // database it started with, or not at all.
    final pipeline = _ref.read(pipelineServiceProvider);
    final visits = _ref.read(visitRepositoryProvider);
    final correctorLoading = _ref.read(drugCorrectorProvider.future);
    final mapperLoading = _ref.read(icd10MapperProvider.future);
    final diffEngineLoading = _ref.read(differentialEngineProvider.future);

    // Single unified call — the backend pipeline handles STT + extraction and,
    // when a prior transcript is supplied, the "Add More" accumulation too.
    // The returned result already contains the full combined transcript plus
    // the re-extracted insight, so there is no client-side combining left.
    final result = await pipeline.processConsultation(
      audioPath: audioPath,
      languageCode: languageCode,
      audioDuration: audioDuration,
      previousTranscript: previous.isEmpty ? null : previous,
    );

    // Nothing clinical came back: the microphone caught no consultation
    // (muted, blocked, or only noise that speech-to-text turned into a stray
    // sentence). Say so rather than produce a blank prescription.
    if (!result.insight.hasClinicalContent) {
      throw const ApiFailure(
        'No consultation was heard in this recording.',
        code: FailureCode.invalidAudio,
      );
    }

    // Correct mangled / romanized drug names to canonical forms on-device.
    // Same matching engine the backend validateExtraction uses, so a name
    // gets fixed no matter which STT produced it.
    final corrector = await correctorLoading;
    final correctedMeds = [
      for (final med in result.insight.medications)
        () {
          final corrected = corrector.correct(med.name);
          return corrected != null && corrected.canonical != med.name
              ? med.copyWith(name: corrected.canonical, originalName: med.name)
              : med;
        }(),
    ];

    // ICD-10 is assigned on-device from a curated WHO map, not by the LLM.
    // The mapper output ALWAYS overwrites the extractor's ICD fields —
    // including clearing all three when there is no confident match — so the
    // doctor never sees a guessed code.
    final mapper = await mapperLoading;
    final icd = mapper.lookup(result.insight.diagnosis);
    final insight = result.insight.copyWith(
      medications: correctedMeds,
      icdCode: icd.code,
      icdDescription: icd.description,
      icdConfidence: icd.confidence,
    );

    // Differential-diagnosis decision support — computed on-device from the
    // extracted symptoms.
    final diffEngine = await diffEngineLoading;
    final suggestions = diffEngine.suggest(result.insight.symptoms);

    final current = await visits.byId(visitId);
    if (current == null) {
      throw const StorageFailure('Visit record missing from local DB.');
    }
    final updated = current.copyWith(
      transcript: result.transcript,
      insight: insight,
    );
    await visits.upsert(updated);
    return ProcessedConsultation(visit: updated, suggestions: suggestions);
  }
}

final consultationProcessorProvider = Provider<ConsultationProcessor>(
  ConsultationProcessor.new,
);
