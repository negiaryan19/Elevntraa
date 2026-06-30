import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/errors/failure.dart';
import '../../../data/repositories/visit_repository.dart';
import '../data/insight_service.dart';
import '../data/pipeline_service.dart';
import '../data/recording_service.dart';
import '../data/stt_service.dart';

// ⚠️ DEBUG ONLY — set to false (or remove) before any release build.
// When true, STT is skipped and a hardcoded Hindi/English transcript is used
// so the full Review → Share → Add-More flow can be exercised on the emulator
// (which cannot capture Mac speaker audio through its virtual mic).
const bool kDebugSkipStt = false;
const String _kDebugTranscript = '''
Patient ko do din se bahut zyada headache ho raha hai. Body mein dard bhi hai aur thakaan lag rahi hai. Bukhar bhi hai, kal raat 101 degrees tha. Thodi sardi hai, khansi nahi.
Impression: viral fever with body ache.
Paracetamol 500mg din mein do baar khana khane ke baad teen din tak lena.
Cetirizine 10mg raat ko sone se pehle teen din tak lena.
Vitamin C 500mg subah ek baar teen din tak lena.
Paani zyada piyo, aaram karo. Teen din baad follow up.
''';

enum ConsultationStage {
  idle,
  recording,
  transcribing,
  extracting,
  done,
  error,
}

/// Raw STT transcript accumulated across one consultation's recording
/// sessions — the initial recording plus any "Add More" appends. The combined
/// text is what gets sent to Gemini for extraction, so adding more audio
/// re-processes the whole consultation rather than just the new segment.
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
  // ignore: unused_element — _stt is retained for kDebugSkipStt path; removed in Phase 8 cleanup.
  SttService get _stt => ref.read(sttServiceProvider);
  InsightService get _insight => ref.read(insightServiceProvider);
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

      // result      → what's written to the visit DB (labeled transcript + insight)
      // cumulativeToStore → raw accumulated text committed to cumulativeTranscriptProvider
      //                     so future "Add More" segments are appended correctly.
      final InsightResult result;
      final String cumulativeToStore;

      if (kDebugSkipStt) {
        // Debug path: skip backend, run on-device extraction with hardcoded transcript.
        // Keeps emulator testing working without network/auth dependency.
        state = state.copyWith(stage: ConsultationStage.extracting);
        final previous = ref.read(cumulativeTranscriptProvider);
        final combined = previous.trim().isEmpty
            ? _kDebugTranscript
            : '$previous\n$_kDebugTranscript';
        result = await _insight.extract(combined);
        cumulativeToStore = combined;
      } else {
        // Production path — call backend pipeline.
        state = state.copyWith(stage: ConsultationStage.transcribing);
        final backendResult = await ref
            .read(pipelineServiceProvider)
            .processConsultation(
              audioPath: path,
              languageCode: state.languageCode,
              audioDuration: effectiveDuration,
            );

        final previous = ref.read(cumulativeTranscriptProvider);
        if (previous.trim().isEmpty) {
          // Fresh consultation — backend result is final.
          result = backendResult;
          cumulativeToStore = backendResult.transcript;
        } else {
          // "Add More" mode — re-extract on combined transcript using on-device
          // InsightService. The backend only processes the new audio segment, so
          // we append its transcript to the prior session(s) and re-run extraction
          // client-side. This avoids passing server state across requests while
          // keeping accumulation semantics identical to the old path.
          // cumulativeToStore holds the raw accumulated text (not relabeled) so
          // the next "Add More" appends cleanly.
          state = state.copyWith(stage: ConsultationStage.extracting);
          final combined = '$previous\n${backendResult.transcript}';
          result = await _insight.extract(combined);
          cumulativeToStore = combined;
        }
      }

      final current = await _visits.byId(visitId);
      if (current == null) {
        throw const StorageFailure('Visit record missing from local DB.');
      }
      final updated = current.copyWith(
        transcript: result.transcript,
        insight: result.insight,
      );
      await _visits.upsert(updated);

      // Commit the accumulated transcript only after extraction and DB write
      // succeed — prevents a failed segment from polluting future "Add More" runs.
      ref.read(cumulativeTranscriptProvider.notifier).state = cumulativeToStore;

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
