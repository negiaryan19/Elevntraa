import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rxvarta/app/router.dart';
import 'package:rxvarta/core/errors/failure.dart';
import 'package:rxvarta/core/network/connectivity_provider.dart';
import 'package:rxvarta/data/db/app_database.dart';
import 'package:rxvarta/data/db/database_provider.dart';
import 'package:rxvarta/data/repositories/visit_repository.dart';
import 'package:rxvarta/domain/models/medical_insight.dart';
import 'package:rxvarta/domain/models/medication.dart';
import 'package:rxvarta/domain/models/visit.dart';
import 'package:rxvarta/features/consultation/data/pending_consultations.dart';
import 'package:rxvarta/features/consultation/data/pipeline_service.dart';
import 'package:rxvarta/features/consultation/data/recording_service.dart';
import 'package:rxvarta/features/consultation/presentation/consultation_controller.dart';
import 'package:rxvarta/features/consultation/presentation/recording_screen.dart';
import 'package:rxvarta/l10n/app_localizations.dart';

/// Without internet the recording screen used to refuse to start, to resume
/// and, worst, to FINISH a consultation: the doctor was held on the screen
/// with the next patient waiting (roadmap items 13, 14). These tests drive the
/// real screen offline.
class _Recorder implements RecordingService {
  int starts = 0;
  int stops = 0;

  @override
  Stream<double> get amplitude => const Stream.empty();

  @override
  Future<String> start() async {
    starts++;
    return '/tmp/offline.m4a';
  }

  @override
  Future<String?> stop() async {
    stops++;
    return '/tmp/offline.m4a';
  }

  @override
  Future<Duration?> probeDuration(String path) async =>
      const Duration(seconds: 20);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Pipeline implements PipelineService {
  _Pipeline({this.failure});

  final Failure? failure;
  final processed = <String>[];

  @override
  Future<InsightResult> processConsultation({
    required String audioPath,
    required String languageCode,
    Duration? audioDuration,
    String? previousTranscript,
  }) async {
    processed.add(audioPath);
    if (failure != null) throw failure!;
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
}

const _queuedMessage =
    'Saved on this phone. It will be processed when the internet is back.';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late _Recorder recorder;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    recorder = _Recorder();
    await VisitRepository(db).upsert(
      VisitRecord(id: 'v1', patientId: 'p1', createdAt: DateTime(2026, 9, 22)),
    );
  });
  tearDown(() async => db.close());

  ProviderContainer containerFor(
    _Pipeline pipeline,
    ConnectivityStatus connectivity,
  ) {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        recordingServiceProvider.overrideWithValue(recorder),
        pipelineServiceProvider.overrideWithValue(pipeline),
        connectivityStatusProvider.overrideWith(
          () => _Connectivity(connectivity),
        ),
        // The file is imaginary; the queue must not fail it for being absent.
        audioFileExistsProvider.overrideWithValue((_) => true),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> pumpRecordingScreen(
    WidgetTester tester,
    ProviderContainer c,
  ) async {
    final router = GoRouter(
      initialLocation: '/recording/v1',
      routes: [
        GoRoute(
          path: AppRoute.recording.path,
          builder: (_, s) =>
              RecordingScreen(visitId: s.pathParameters['visitId']!),
        ),
        GoRoute(
          path: AppRoute.review.path,
          builder: (_, _) => const Scaffold(body: Text('REVIEW SCREEN')),
        ),
        GoRoute(
          path: AppRoute.home.path,
          builder: (_, _) => const Scaffold(body: Text('HOME SCREEN')),
        ),
      ],
    );
    addTearDown(router.dispose);
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
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
    await tester.pump(const Duration(milliseconds: 300));
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

  /// The queue keeps a retry timer for as long as its provider lives; the
  /// test framework insists none is left when the test body ends.
  Future<void> finish(WidgetTester tester, ProviderContainer c) async {
    await tester.pumpWidget(const SizedBox());
    c.dispose();
    await tester.pump(const Duration(seconds: 6));
  }

  ConsultationController controller(ProviderContainer c) =>
      c.read(consultationControllerProvider('v1').notifier);

  ConsultationState stateOf(ProviderContainer c) =>
      c.read(consultationControllerProvider('v1'));

  testWidgets('offline, the doctor is told what will happen and can still '
      'start the consultation', (tester) async {
    final c = containerFor(_Pipeline(), ConnectivityStatus.offline);
    await pumpRecordingScreen(tester, c);

    expect(find.byKey(const Key('offline_notice')), findsOneWidget);
    expect(
      find.text(
        "You're offline. The recording will be saved on this phone and "
        'processed when the internet is back.',
      ),
      findsOneWidget,
    );
    // The button says what it does, not "Offline — reconnect".
    expect(find.text('Start Consultation'), findsOneWidget);

    await tester.tap(find.text('Start Consultation'));
    await settle(tester);

    expect(recorder.starts, 1);
    expect(stateOf(c).stage, ConsultationStage.recording);
    await finish(tester, c);
  });

  testWidgets('offline, Done saves the recording, queues the consultation '
      'and returns the doctor to Home', (tester) async {
    final pipeline = _Pipeline();
    final c = containerFor(pipeline, ConnectivityStatus.offline);
    await tester.runAsync(() => controller(c).startRecording());
    controller(c).tickElapsed(const Duration(seconds: 12));
    await pumpRecordingScreen(tester, c);

    await tester.tap(find.text('Done'));
    await settle(tester);

    expect(find.text('HOME SCREEN'), findsOneWidget);
    expect(find.text(_queuedMessage), findsOneWidget);
    expect(find.text('REVIEW SCREEN'), findsNothing);

    final visit = await tester.runAsync(() => VisitRepository(db).byId('v1'));
    expect(visit!.pendingState, PendingState.queued);
    expect(visit.audioPath, '/tmp/offline.m4a');
    expect(recorder.stops, 1);
    expect(
      pipeline.processed,
      isEmpty,
      reason: 'nothing is uploaded while the phone is offline',
    );
    await finish(tester, c);
  });

  testWidgets('online, Done still processes at once and opens the review', (
    tester,
  ) async {
    final pipeline = _Pipeline();
    final c = containerFor(pipeline, ConnectivityStatus.online);
    await tester.runAsync(() => controller(c).startRecording());
    controller(c).tickElapsed(const Duration(seconds: 12));
    await pumpRecordingScreen(tester, c);

    await tester.tap(find.text('Done'));
    await settle(tester);

    expect(find.text('REVIEW SCREEN'), findsOneWidget);
    expect(pipeline.processed, ['/tmp/offline.m4a']);
    final visit = await tester.runAsync(() => VisitRepository(db).byId('v1'));
    expect(visit!.pendingState, isNull);
    expect(visit.insight!.diagnosis, 'Viral fever');
    await finish(tester, c);
  });

  testWidgets('after a failed attempt, "Process later" queues the saved '
      'recording instead of holding the doctor on the screen', (tester) async {
    final pipeline = _Pipeline(
      failure: const NetworkFailure('Could not reach backend'),
    );
    final c = containerFor(pipeline, ConnectivityStatus.offline);
    await tester.runAsync(() => controller(c).stopAndProcess());
    expect(stateOf(c).stage, ConsultationStage.error);
    await pumpRecordingScreen(tester, c);

    await tester.tap(find.byKey(const Key('process_later_button')));
    await settle(tester);

    expect(find.text('HOME SCREEN'), findsOneWidget);
    expect(find.text(_queuedMessage), findsOneWidget);
    final visit = await tester.runAsync(() => VisitRepository(db).byId('v1'));
    expect(visit!.pendingState, PendingState.queued);
    expect(recorder.stops, 1, reason: 'the same recording, not a new one');
    expect(pipeline.processed, hasLength(1), reason: 'only the failed attempt');
    await finish(tester, c);
  });
}
