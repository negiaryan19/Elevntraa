import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/errors/failure.dart';
import '../../../core/network/connectivity_provider.dart';
import '../../../data/repositories/visit_repository.dart';
import '../../../domain/models/visit.dart';
import 'consultation_processor.dart';
import 'recording_service.dart';

/// Whether a recording is still on the phone. A provider so tests can answer
/// without touching the disk.
final audioFileExistsProvider = Provider<bool Function(String path)>(
  (ref) =>
      (path) => File(path).existsSync(),
);

/// How often the queue tries again by itself while something is waiting.
/// "Online" only means the internet is reachable; the backend can still be
/// down, and nothing else would prompt another attempt.
final pendingRetryIntervalProvider = Provider<Duration>(
  (ref) => const Duration(minutes: 2),
);

/// What the queue is doing right now.
class PendingQueueState {
  const PendingQueueState({this.processingVisitId});

  /// The consultation being processed, if any.
  final String? processingVisitId;
}

/// Consultations recorded without internet, processed when it comes back
/// (roadmap items 13, 14).
///
/// A clinic's connection drops. Before this, a doctor could not start a
/// consultation offline and, worse, could not FINISH one: Done refused to
/// proceed, so they were held on the recording screen while patients waited.
/// Now the recording is kept on the phone, the visit is marked
/// [PendingState.queued], and the doctor moves on.
///
/// The state lives on the visit row, in the signed-in doctor's own database:
/// it survives a restart and never crosses doctors. The queue drains oldest
/// first, one at a time, through the same [ConsultationProcessor] a live
/// consultation uses.
///
/// * processed → [PendingState.ready], until the doctor opens it;
/// * the backend cannot be reached, or the session expired → it stays queued
///   and the drain stops: that is not the recording's fault, and hammering a
///   dead connection helps nobody;
/// * the recording cannot be processed (nothing was heard, the file is gone)
///   → [PendingState.failed] with the reason, for the doctor to decide.
class PendingConsultations extends Notifier<PendingQueueState> {
  bool _draining = false;
  bool _drainAgain = false;
  Timer? _timer;

  /// Server errors seen per visit in this session. A 5xx is usually
  /// transient; the same recording failing three times is not.
  final _serverFailures = <String, int>{};
  static const _maxServerFailures = 3;

  @override
  PendingQueueState build() {
    // Rebuilt when another doctor signs in: the repository below then reads
    // that doctor's database, and their queue is the one that drains.
    ref.watch(currentUserIdProvider);
    ref.listen<ConnectivityStatus>(connectivityStatusProvider, (_, next) {
      if (next == ConnectivityStatus.online) unawaited(drain());
    });
    _timer?.cancel();
    _timer = Timer.periodic(
      ref.read(pendingRetryIntervalProvider),
      (_) => unawaited(drain()),
    );
    ref.onDispose(() => _timer?.cancel());
    // Whatever the last session left behind.
    Future<void>.microtask(drain);
    return const PendingQueueState();
  }

  VisitRepository get _visits => ref.read(visitRepositoryProvider);

  /// Adds [visitId] to the queue. Its recording must already be saved on it.
  Future<void> enqueue(String visitId) async {
    final visit = await _visits.byId(visitId);
    if (visit == null) {
      throw const StorageFailure('Visit record missing from local DB.');
    }
    if (visit.audioPath == null) {
      throw const StorageFailure('This visit has no recording to process.');
    }
    await _visits.upsert(
      visit.copyWith(pendingState: PendingState.queued, pendingError: null),
    );
    _serverFailures.remove(visitId);
    unawaited(drain());
  }

  /// The doctor asked to try a failed consultation again.
  Future<void> retry(String visitId) => enqueue(visitId);

  /// The doctor opened a processed consultation, or dismissed a failed one:
  /// it is an ordinary visit from here on.
  Future<void> clear(String visitId) async {
    final visit = await _visits.byId(visitId);
    if (visit == null || visit.pendingState == null) return;
    await _visits.upsert(
      visit.copyWith(pendingState: null, pendingError: null),
    );
  }

  /// Processes everything that is queued, if the phone is online. Safe to
  /// call at any time and from anywhere: overlapping calls collapse into one
  /// run, plus one more pass for anything queued meanwhile.
  Future<void> drain() async {
    if (_draining) {
      _drainAgain = true;
      return;
    }
    _draining = true;
    try {
      var finished = true;
      do {
        _drainAgain = false;
        finished = await _drainOnce();
        // A pass that stopped early met a dead connection, an expired
        // session or a struggling server. Going round again at once, just
        // because another drain was requested meanwhile, would hammer exactly
        // what the policy says to leave alone; the next trigger will do.
      } while (finished && _drainAgain);
      _drainAgain = false;
    } catch (e) {
      debugPrint('[queue] drain stopped: $e');
    } finally {
      _draining = false;
      // The doctor may have signed out while a consultation was processing:
      // this provider is then disposed and its state must not be touched.
      if (ref.mounted) state = const PendingQueueState();
    }
  }

  /// One pass over the queue. Returns false when it stopped early.
  ///
  /// `ref` is only used while the provider is known to be mounted, and never
  /// after an await inside [_processOne]: a sign-out can dispose this provider
  /// in the middle of a consultation being processed.
  Future<bool> _drainOnce() async {
    if (!ref.mounted) return false;
    final visits = _visits;
    final queued = (await visits.pending()).where(
      (v) => v.pendingState == PendingState.queued,
    );
    for (final visit in queued) {
      if (!ref.mounted ||
          ref.read(connectivityStatusProvider) != ConnectivityStatus.online) {
        return false;
      }
      state = PendingQueueState(processingVisitId: visit.id);
      final carryOn = await _processOne(
        visit,
        visits: visits,
        processor: ref.read(consultationProcessorProvider),
        recorder: ref.read(recordingServiceProvider),
        fileExists: ref.read(audioFileExistsProvider),
      );
      if (!carryOn) return false;
    }
    return true;
  }

  /// Returns false when the drain should stop (the backend is unreachable or
  /// the session is gone), true to carry on with the next consultation.
  Future<bool> _processOne(
    VisitRecord visit, {
    required VisitRepository visits,
    required ConsultationProcessor processor,
    required RecordingService recorder,
    required bool Function(String path) fileExists,
  }) async {
    final path = visit.audioPath;
    if (path == null || !fileExists(path)) {
      await _fail(visits, visit.id, FailureCode.storage);
      return true;
    }
    try {
      final processed = await processor.process(
        visitId: visit.id,
        audioPath: path,
        languageCode: visit.languageCode,
        audioDuration: await recorder.probeDuration(path),
        // An "Add more" segment recorded offline: the visit already has a
        // processed transcript, which the new audio continues.
        previousTranscript: visit.insight == null ? null : visit.transcript,
      );
      await visits.upsert(
        processed.visit.copyWith(
          pendingState: PendingState.ready,
          pendingError: null,
        ),
      );
      _serverFailures.remove(visit.id);
      return true;
    } on Failure catch (f) {
      debugPrint('[queue] ${visit.id} not processed: ${f.code.name}');
      switch (f.code) {
        case FailureCode.network:
        case FailureCode.auth:
          // Not the recording's fault. Keep it queued and stop for now.
          return false;
        case FailureCode.server:
          final seen = (_serverFailures[visit.id] ?? 0) + 1;
          _serverFailures[visit.id] = seen;
          if (seen >= _maxServerFailures) {
            await _fail(visits, visit.id, f.code);
          }
          // Either way, give the server a rest before the next one.
          return false;
        default:
          await _fail(visits, visit.id, f.code);
          return true;
      }
    } catch (e) {
      debugPrint('[queue] ${visit.id} not processed: $e');
      await _fail(visits, visit.id, FailureCode.unknown);
      return true;
    }
  }

  Future<void> _fail(
    VisitRepository visits,
    String visitId,
    FailureCode code,
  ) async {
    // Re-read: after a sign-out this database may no longer hold the visit,
    // in which case there is nothing to mark.
    final visit = await visits.byId(visitId);
    if (visit == null) return;
    await visits.upsert(
      visit.copyWith(
        pendingState: PendingState.failed,
        pendingError: code.name,
      ),
    );
  }
}

final pendingConsultationsProvider =
    NotifierProvider<PendingConsultations, PendingQueueState>(
      PendingConsultations.new,
    );

/// Live list of the signed-in doctor's pending consultations, oldest first.
final pendingVisitsProvider = StreamProvider<List<VisitRecord>>(
  (ref) => ref.watch(visitRepositoryProvider).watchPending(),
);
