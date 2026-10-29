import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rxvarta/app/router.dart';
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
import 'package:rxvarta/features/home/presentation/pending_consultations_card.dart';
import 'package:rxvarta/l10n/app_localizations.dart';

/// A consultation recorded offline is no use to anyone if the doctor cannot
/// see what became of it (roadmap items 13, 14). These tests drive the Home
/// card over a real database and the real queue.
class _Recorder implements RecordingService {
  @override
  Future<Duration?> probeDuration(String path) async =>
      const Duration(seconds: 20);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Pipeline implements PipelineService {
  /// When set, processing waits here: the test sees the "in progress" state.
  Completer<void>? gate;
  final processed = <String>[];

  @override
  Future<InsightResult> processConsultation({
    required String audioPath,
    required String languageCode,
    Duration? audioDuration,
    String? previousTranscript,
  }) async {
    processed.add(audioPath);
    await gate?.future;
    return const InsightResult(
      transcript: 'Paracetamol 650 mg three times a day for three days.',
      insight: MedicalInsight(
        diagnosis: 'Viral fever',
        medications: [Medication(name: 'Paracetamol', dosage: '650 mg')],
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Connectivity extends ConnectivityNotifier {
  _Connectivity(this._initial);

  final ConnectivityStatus _initial;

  @override
  ConnectivityStatus build() => _initial;

  void set(ConnectivityStatus status) => state = status;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late _Pipeline pipeline;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    pipeline = _Pipeline();
    final now = DateTime(2026, 9, 22);
    for (final (id, name) in [('p1', 'Asha Kulkarni'), ('p2', 'Ravi Menon')]) {
      await PatientRepository(db).upsert(
        PatientProfile(id: id, name: name, createdAt: now, updatedAt: now),
      );
    }
  });
  tearDown(() async => db.close());

  Future<void> addVisit(
    String id, {
    String patientId = 'p1',
    PendingState? pending,
    String? error,
    int minute = 0,
  }) => VisitRepository(db).upsert(
    VisitRecord(
      id: id,
      patientId: patientId,
      createdAt: DateTime(2026, 9, 22, 10, minute),
      audioPath: '/tmp/$id.m4a',
      pendingState: pending,
      pendingError: error,
    ),
  );

  ProviderContainer containerFor(ConnectivityStatus connectivity) {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        recordingServiceProvider.overrideWithValue(_Recorder()),
        pipelineServiceProvider.overrideWithValue(pipeline),
        connectivityStatusProvider.overrideWith(
          () => _Connectivity(connectivity),
        ),
        audioFileExistsProvider.overrideWithValue((_) => true),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Lets real async work (the in-memory database) finish between frames.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pumpHome(WidgetTester tester, ProviderContainer c) async {
    final router = GoRouter(
      initialLocation: AppRoute.home.path,
      routes: [
        GoRoute(
          path: AppRoute.home.path,
          builder: (_, _) => Scaffold(
            body: ListView(children: const [PendingConsultationsCard()]),
          ),
        ),
        GoRoute(
          path: AppRoute.review.path,
          builder: (_, s) =>
              Scaffold(body: Text('REVIEW ${s.pathParameters['visitId']}')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await settle(tester);
  }

  /// The queue keeps a retry timer for as long as its provider lives; the
  /// test framework insists none is left when the test body ends.
  Future<void> finish(WidgetTester tester, ProviderContainer c) async {
    await tester.pumpWidget(const SizedBox());
    c.dispose();
    await tester.pump(const Duration(seconds: 1));
  }

  Future<VisitRecord?> visit(WidgetTester tester, String id) =>
      tester.runAsync<VisitRecord?>(() => VisitRepository(db).byId(id));

  const card = Key('pending_consultations_card');

  testWidgets('takes no space when nothing is pending', (tester) async {
    await tester.runAsync(() => addVisit('v1'));
    final c = containerFor(ConnectivityStatus.online);
    await pumpHome(tester, c);

    expect(find.byKey(card), findsNothing);
    expect(find.text('Waiting to be processed'), findsNothing);
    await finish(tester, c);
  });

  testWidgets('offline, each queued consultation is listed with its patient, '
      'oldest first', (tester) async {
    await tester.runAsync(() async {
      await addVisit(
        'v2',
        patientId: 'p2',
        pending: PendingState.queued,
        minute: 30,
      );
      await addVisit('v1', pending: PendingState.queued, minute: 5);
    });
    final c = containerFor(ConnectivityStatus.offline);
    await pumpHome(tester, c);

    expect(find.byKey(card), findsOneWidget);
    expect(find.text('Waiting to be processed'), findsOneWidget);
    expect(find.text('Waiting for internet'), findsNWidgets(2));
    final asha = tester.getTopLeft(find.text('Asha Kulkarni')).dy;
    final ravi = tester.getTopLeft(find.text('Ravi Menon')).dy;
    expect(asha, lessThan(ravi), reason: 'the 10:05 visit before the 10:30');
    expect(pipeline.processed, isEmpty);
    await finish(tester, c);
  });

  testWidgets('when the internet returns the consultation is processed by '
      'itself: waiting, then processing, then ready', (tester) async {
    await tester.runAsync(() => addVisit('v1', pending: PendingState.queued));
    pipeline.gate = Completer<void>();
    final c = containerFor(ConnectivityStatus.offline);
    await pumpHome(tester, c);
    expect(find.text('Waiting for internet'), findsOneWidget);

    (c.read(connectivityStatusProvider.notifier) as _Connectivity).set(
      ConnectivityStatus.online,
    );
    await settle(tester);
    expect(find.text('Processing…'), findsOneWidget);
    expect(find.text('Waiting for internet'), findsNothing);

    pipeline.gate!.complete();
    await settle(tester);
    expect(find.text('Ready to review'), findsOneWidget);
    expect(find.text('Processing…'), findsNothing);
    expect(pipeline.processed, ['/tmp/v1.m4a']);
    final saved = await visit(tester, 'v1');
    expect(saved!.pendingState, PendingState.ready);
    expect(saved.insight!.diagnosis, 'Viral fever');
    await finish(tester, c);
  });

  testWidgets('a processed consultation opens for review and leaves the list', (
    tester,
  ) async {
    await tester.runAsync(() => addVisit('v1', pending: PendingState.ready));
    final c = containerFor(ConnectivityStatus.online);
    await pumpHome(tester, c);

    await tester.tap(find.byKey(const Key('pending_row_v1')));
    await settle(tester);

    expect(find.text('REVIEW v1'), findsOneWidget);
    expect((await visit(tester, 'v1'))!.pendingState, isNull);
    await finish(tester, c);
  });

  testWidgets('a waiting consultation does not open: there is nothing to '
      'review yet', (tester) async {
    await tester.runAsync(() => addVisit('v1', pending: PendingState.queued));
    final c = containerFor(ConnectivityStatus.offline);
    await pumpHome(tester, c);

    await tester.tap(find.byKey(const Key('pending_row_v1')));
    await settle(tester);

    expect(find.text('REVIEW v1'), findsNothing);
    expect((await visit(tester, 'v1'))!.pendingState, PendingState.queued);
    await finish(tester, c);
  });

  testWidgets('a failed consultation says why, and Retry queues it again', (
    tester,
  ) async {
    await tester.runAsync(
      () => addVisit('v1', pending: PendingState.failed, error: 'server'),
    );
    final c = containerFor(ConnectivityStatus.offline);
    await pumpHome(tester, c);

    expect(
      find.text(
        'Could not be processed · Something went wrong. Please try again.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('pending_retry_v1')));
    await settle(tester);

    final saved = await visit(tester, 'v1');
    expect(saved!.pendingState, PendingState.queued);
    expect(saved.pendingError, isNull);
    expect(find.text('Waiting for internet'), findsOneWidget);
    await finish(tester, c);
  });

  testWidgets('Dismiss makes a failed consultation an ordinary visit and the '
      'card goes away', (tester) async {
    await tester.runAsync(
      () => addVisit('v1', pending: PendingState.failed, error: 'storage'),
    );
    final c = containerFor(ConnectivityStatus.online);
    await pumpHome(tester, c);
    expect(find.textContaining('Files on this phone'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pending_dismiss_v1')));
    await settle(tester);

    final saved = await visit(tester, 'v1');
    expect(saved!.pendingState, isNull);
    expect(saved.audioPath, '/tmp/v1.m4a', reason: 'the visit itself is kept');
    expect(find.byKey(card), findsNothing);
    await finish(tester, c);
  });

  testWidgets('a recording in which nothing was heard is not offered for '
      'retry', (tester) async {
    await tester.runAsync(
      () => addVisit('v1', pending: PendingState.failed, error: 'invalidAudio'),
    );
    final c = containerFor(ConnectivityStatus.online);
    await pumpHome(tester, c);

    expect(
      find.textContaining('No consultation was heard in this recording'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('pending_retry_v1')), findsNothing);
    expect(find.byKey(const Key('pending_dismiss_v1')), findsOneWidget);
    await finish(tester, c);
  });

  testWidgets('a reason this build does not know, and a patient who is gone, '
      'still produce a readable row', (tester) async {
    await tester.runAsync(
      () => addVisit(
        'v1',
        patientId: 'deleted',
        pending: PendingState.failed,
        error: 'somethingFromANewerBuild',
      ),
    );
    final c = containerFor(ConnectivityStatus.online);
    await pumpHome(tester, c);

    expect(find.text('Patient'), findsOneWidget);
    expect(
      find.text(
        'Could not be processed · Something went wrong. Please try again.',
      ),
      findsOneWidget,
    );
    await finish(tester, c);
  });
}
