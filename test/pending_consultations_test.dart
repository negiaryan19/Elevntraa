import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxvarta/core/errors/failure.dart';
import 'package:rxvarta/core/network/connectivity_provider.dart';
import 'package:rxvarta/data/db/app_database.dart';
import 'package:rxvarta/data/db/database_provider.dart';
import 'package:rxvarta/data/repositories/patient_repository.dart';
import 'package:rxvarta/data/repositories/visit_repository.dart';
import 'package:rxvarta/domain/models/medical_insight.dart';
import 'package:rxvarta/domain/models/medication.dart';
import 'package:rxvarta/domain/models/patient.dart';
import 'package:rxvarta/domain/models/visit.dart';
import 'package:rxvarta/features/consultation/data/pending_consultations.dart';
import 'package:rxvarta/features/consultation/data/pipeline_service.dart';
import 'package:rxvarta/features/consultation/data/recording_service.dart';
import 'package:rxvarta/features/consultation/presentation/consultation_controller.dart';

/// A clinic's internet drops. A doctor could not start a consultation offline
/// and could not finish one either: Done refused, holding them on the
/// recording screen. Recordings now wait in a queue on the phone and are
/// processed when the connection is back (roadmap items 13, 14).
class _Recorder implements RecordingService {
  @override
  Future<String?> stop() async => '/rec/live.m4a';
  @override
  Future<Duration?> probeDuration(String path) async =>
      const Duration(seconds: 20);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Pipeline implements PipelineService {
  /// What to throw for a given audio path; absent = succeed.
  final failures = <String, Failure>{};
  final calls = <({String audio, String? previous})>[];
  bool empty = false;

  /// When set, a call waits here: lets a test act mid-processing.
  Completer<void>? gate;

  @override
  Future<InsightResult> processConsultation({
    required String audioPath,
    required String languageCode,
    Duration? audioDuration,
    String? previousTranscript,
  }) async {
    calls.add((audio: audioPath, previous: previousTranscript));
    if (gate != null) await gate!.future;
    final failure = failures[audioPath];
    if (failure != null) throw failure;
    return InsightResult(
      transcript: 'Doctor: transcript of $audioPath',
      insight: empty
          ? const MedicalInsight()
          : const MedicalInsight(
              diagnosis: 'Viral fever',
              medications: [
                Medication(name: 'Paracetamol', dosage: '1 tablet'),
              ],
            ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Net extends ConnectivityNotifier {
  _Net(this._initial);
  final ConnectivityStatus _initial;
  @override
  ConnectivityStatus build() => _initial;
  void set(ConnectivityStatus status) => state = status;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late _Pipeline pipeline;
  final missingFiles = <String>{};
  final t0 = DateTime(2026, 9, 22, 9);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    pipeline = _Pipeline();
    missingFiles.clear();
    await PatientRepository(db).upsert(
      PatientProfile(id: 'p1', name: 'Sunita', createdAt: t0, updatedAt: t0),
    );
  });
  tearDown(() async => db.close());

  Future<void> seed(
    String id, {
    int hour = 0,
    PendingState? pending = PendingState.queued,
    MedicalInsight? insight,
    String? transcript,
    String? audio,
  }) => VisitRepository(db).upsert(
    VisitRecord(
      id: id,
      patientId: 'p1',
      createdAt: t0.add(Duration(hours: hour)),
      audioPath: audio ?? '/rec/$id.m4a',
      languageCode: 'hi-IN',
      pendingState: pending,
      insight: insight,
      transcript: transcript,
    ),
  );

  ProviderContainer container(ConnectivityStatus net) {
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        recordingServiceProvider.overrideWithValue(_Recorder()),
        pipelineServiceProvider.overrideWithValue(pipeline),
        connectivityStatusProvider.overrideWith(() => _Net(net)),
        audioFileExistsProvider.overrideWithValue(
          (path) => !missingFiles.contains(path),
        ),
        // Never fires during a test: attempts are driven explicitly.
        pendingRetryIntervalProvider.overrideWithValue(const Duration(days: 1)),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<VisitRecord> visit(String id) async =>
      (await VisitRepository(db).byId(id))!;

  PendingConsultations queue(ProviderContainer c) =>
      c.read(pendingConsultationsProvider.notifier);

  test('offline: a queued consultation waits and nothing is sent', () async {
    await seed('v1');
    final c = container(ConnectivityStatus.offline);
    await queue(c).drain();

    expect(pipeline.calls, isEmpty);
    expect((await visit('v1')).pendingState, PendingState.queued);
  });

  test('when the connection returns the queue drains by itself', () async {
    await seed('v1');
    final c = container(ConnectivityStatus.offline);
    queue(c); // the queue is alive, as it is for the app's whole lifetime
    await pumpEventQueue();
    expect(pipeline.calls, isEmpty);

    (c.read(connectivityStatusProvider.notifier) as _Net).set(
      ConnectivityStatus.online,
    );
    await pumpEventQueue(times: 50);

    final v = await visit('v1');
    expect(v.pendingState, PendingState.ready);
    expect(v.insight!.diagnosis, 'Viral fever');
    expect(v.transcript, 'Doctor: transcript of /rec/v1.m4a');
  });

  test('what an earlier session left behind is processed on start', () async {
    await seed('v1');
    final c = container(ConnectivityStatus.online);
    queue(c);
    await pumpEventQueue(times: 50);
    expect((await visit('v1')).pendingState, PendingState.ready);
  });

  test('oldest first, one at a time', () async {
    await seed('late', hour: 2);
    await seed('early', hour: 1);
    final c = container(ConnectivityStatus.online);
    await queue(c).drain();

    expect(pipeline.calls.map((x) => x.audio), [
      '/rec/early.m4a',
      '/rec/late.m4a',
    ]);
  });

  test('an unreachable backend keeps it queued and stops the drain', () async {
    await seed('first', hour: 1);
    await seed('second', hour: 2);
    pipeline.failures['/rec/first.m4a'] = const NetworkFailure('no route');
    final c = container(ConnectivityStatus.online);
    await queue(c).drain();

    expect((await visit('first')).pendingState, PendingState.queued);
    expect((await visit('second')).pendingState, PendingState.queued);
    expect(pipeline.calls.map((x) => x.audio), [
      '/rec/first.m4a',
    ], reason: 'a dead connection is not hammered with the rest of the queue');

    // Later, it works.
    pipeline.failures.clear();
    await queue(c).drain();
    expect((await visit('first')).pendingState, PendingState.ready);
    expect((await visit('second')).pendingState, PendingState.ready);
  });

  test('an expired session keeps it queued', () async {
    await seed('v1');
    pipeline.failures['/rec/v1.m4a'] = const AuthFailure('Not signed in.');
    final c = container(ConnectivityStatus.online);
    await queue(c).drain();
    expect((await visit('v1')).pendingState, PendingState.queued);
  });

  test('a recording with nothing in it fails, and the next one still '
      'runs', () async {
    await seed('silent', hour: 1);
    await seed('fine', hour: 2);
    final c = container(ConnectivityStatus.online);
    pipeline.empty = true;
    // Only the first call is empty.
    final original = pipeline.calls;
    await queue(c).drain();
    expect(original, hasLength(2));

    final silent = await visit('silent');
    expect(silent.pendingState, PendingState.failed);
    expect(silent.pendingError, FailureCode.invalidAudio.name);
    expect(silent.insight, isNull, reason: 'no blank prescription is saved');
  });

  test('a recording that is no longer on the phone fails without being '
      'sent', () async {
    await seed('gone');
    missingFiles.add('/rec/gone.m4a');
    final c = container(ConnectivityStatus.online);
    await queue(c).drain();

    final v = await visit('gone');
    expect(v.pendingState, PendingState.failed);
    expect(v.pendingError, FailureCode.storage.name);
    expect(pipeline.calls, isEmpty);
  });

  test('a server error is retried; the third one in a row fails it', () async {
    await seed('v1');
    pipeline.failures['/rec/v1.m4a'] = const ApiFailure('HTTP 500');
    final c = container(ConnectivityStatus.online);

    await queue(c).drain();
    expect((await visit('v1')).pendingState, PendingState.queued);
    await queue(c).drain();
    expect((await visit('v1')).pendingState, PendingState.queued);
    await queue(c).drain();

    final v = await visit('v1');
    expect(v.pendingState, PendingState.failed);
    expect(v.pendingError, FailureCode.server.name);
  });

  test('Retry puts a failed consultation back in the queue', () async {
    await seed('v1', pending: PendingState.failed);
    final c = container(ConnectivityStatus.online);
    await queue(c).retry('v1');
    await pumpEventQueue(times: 50);
    expect((await visit('v1')).pendingState, PendingState.ready);
  });

  test('opening a processed consultation makes it an ordinary visit', () async {
    await seed('v1', pending: PendingState.ready);
    final c = container(ConnectivityStatus.online);
    await queue(c).clear('v1');

    expect((await visit('v1')).pendingState, isNull);
    expect(await VisitRepository(db).pending(), isEmpty);
  });

  test('an "Add more" segment recorded offline continues the visit\'s '
      'transcript', () async {
    await seed(
      'v1',
      insight: const MedicalInsight(diagnosis: 'Viral fever'),
      transcript: 'Doctor: bukhar hai.',
    );
    final c = container(ConnectivityStatus.online);
    await queue(c).drain();
    expect(pipeline.calls.single.previous, 'Doctor: bukhar hai.');
  });

  test('a first recording sends no previous transcript', () async {
    await seed('v1');
    final c = container(ConnectivityStatus.online);
    await queue(c).drain();
    expect(pipeline.calls.single.previous, isNull);
  });

  test('signing out while a consultation is processing does not '
      'throw', () async {
    // Sign-out disposes the queue. The run already in flight must finish
    // quietly: it used to touch the disposed provider and throw in a detached
    // future, where nothing could catch it.
    await seed('v1');
    pipeline.gate = Completer<void>();
    final c = container(ConnectivityStatus.online);
    final running = queue(c).drain();
    await pumpEventQueue(times: 20);
    expect(pipeline.calls, hasLength(1), reason: 'processing has started');

    c.dispose();
    pipeline.gate!.complete();
    await running;
    await pumpEventQueue(times: 20);

    // The work that was in flight is still saved.
    expect((await visit('v1')).pendingState, PendingState.ready);
  });

  test('a visit with no recording cannot be queued', () async {
    await VisitRepository(
      db,
    ).upsert(VisitRecord(id: 'bare', patientId: 'p1', createdAt: t0));
    final c = container(ConnectivityStatus.online);
    await expectLater(queue(c).enqueue('bare'), throwsA(isA<StorageFailure>()));
  });

  group('from the recording screen', () {
    test('Done without internet saves the recording and queues the '
        'visit', () async {
      await seed('v1', pending: null, audio: '');
      await VisitRepository(
        db,
      ).upsert(VisitRecord(id: 'live', patientId: 'p1', createdAt: t0));
      final c = container(ConnectivityStatus.offline);
      final ctl = c.read(consultationControllerProvider('live').notifier);
      ctl.setLanguage('hi-IN');

      await ctl.stopAndQueue();

      expect(
        c.read(consultationControllerProvider('live')).stage,
        ConsultationStage.queued,
      );
      final v = await visit('live');
      expect(v.audioPath, '/rec/live.m4a');
      expect(v.languageCode, 'hi-IN');
      expect(v.pendingState, PendingState.queued);
      expect(pipeline.calls, isEmpty);
    });

    test('"Process later" after a failed attempt queues the same '
        'recording', () async {
      await VisitRepository(
        db,
      ).upsert(VisitRecord(id: 'live', patientId: 'p1', createdAt: t0));
      pipeline.failures['/rec/live.m4a'] = const NetworkFailure('timeout');
      final c = container(ConnectivityStatus.online);
      final ctl = c.read(consultationControllerProvider('live').notifier);

      await ctl.stopAndProcess();
      expect(
        c.read(consultationControllerProvider('live')).stage,
        ConsultationStage.error,
      );

      await ctl.queueForLater();
      expect(
        c.read(consultationControllerProvider('live')).stage,
        ConsultationStage.queued,
      );
      expect((await visit('live')).pendingState, PendingState.queued);
    });
  });
}
