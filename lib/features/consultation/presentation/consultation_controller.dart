import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/errors/failure.dart';
import '../../../data/repositories/visit_repository.dart';
import '../data/insight_service.dart';
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

      final newTranscript = kDebugSkipStt
          ? _kDebugTranscript
          : await _stt.transcribe(
              path,
              languageCode: state.languageCode,
              audioDuration: effectiveDuration,
            );

      state = state.copyWith(stage: ConsultationStage.extracting);

      // Accumulate across recording sessions. For a fresh consultation the
      // provider was reset to '' before recording started, so `combined`
      // equals `newTranscript`. In "Add More" mode it holds the prior
      // session(s), and the new segment is appended before re-extraction.
      final previous = ref.read(cumulativeTranscriptProvider);
      final combined = previous.trim().isEmpty
          ? newTranscript
          : '$previous\n$newTranscript';

      final result = await _insight.extract(combined);

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
      ref.read(cumulativeTranscriptProvider.notifier).state = combined;

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
