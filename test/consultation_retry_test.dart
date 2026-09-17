import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rxvarta/core/errors/failure.dart';
import 'package:rxvarta/core/network/connectivity_provider.dart';
import 'package:rxvarta/data/db/app_database.dart';
import 'package:rxvarta/data/db/database_provider.dart';
import 'package:rxvarta/data/repositories/visit_repository.dart';
import 'package:rxvarta/domain/models/medical_insight.dart';
import 'package:rxvarta/domain/models/medication.dart';
import 'package:rxvarta/domain/models/visit.dart';
import 'package:rxvarta/features/consultation/data/pipeline_service.dart';
import 'package:rxvarta/features/consultation/data/recording_service.dart';
import 'package:rxvarta/features/consultation/presentation/consultation_controller.dart';
import 'package:rxvarta/features/consultation/presentation/recording_screen.dart';
import 'package:rxvarta/l10n/app_localizations.dart';

/// When upload or AI processing failed, the only way forward was to record
/// the whole consultation again, and the doctor was shown raw text such as
/// "Could not reach backend: SocketException ..." (roadmap items 10, 11).
class _Recorder implements RecordingService {
  int stops = 0;
  int pauses = 0;

  @override
  Future<void> pause() async => pauses++;

  @override
  Stream<double> get amplitude => const Stream.empty();

  @override
  Future<String> start() async => '/tmp/second.m4a';

  @override
  Future<String?> stop() async {
    stops++;
    return '/tmp/visit.m4a';
  }

  @override
  Future<Duration?> probeDuration(String path) async =>
      const Duration(seconds: 20);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fails with [failure] until [fail] is switched off; records every audio
/// file it was asked to process.
class _Pipeline implements PipelineService {
  _Pipeline(this.failure);

  final Failure failure;
  bool fail = true;
  final processed = <String>[];

  @override
  Future<InsightResult> processConsultation({
    required String audioPath,
    required String languageCode,
    Duration? audioDuration,
    String? previousTranscript,
  }) async {
    processed.add(audioPath);
    if (fail) throw failure;
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

class _Online extends ConnectivityNotifier {
  @override
  ConnectivityStatus build() => ConnectivityStatus.online;

  void set(ConnectivityStatus status) => state = status;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late _Recorder recorder;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    recorder = _Recorder();
    await VisitRepository(db).upsert(
      VisitRecord(id: 'v1', patientId: 'p1', createdAt: DateTime(2026, 9, 17)),
    );
  });
  tearDown(() async => db.close());

  ProviderContainer containerFor(_Pipeline pipeline) {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        recordingServiceProvider.overrideWithValue(recorder),
        pipelineServiceProvider.overrideWithValue(pipeline),
        connectivityStatusProvider.overrideWith(_Online.new),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  ConsultationController controller(ProviderContainer c) =>
      c.read(consultationControllerProvider('v1').notifier);

  ConsultationState stateOf(ProviderContainer c) =>
      c.read(consultationControllerProvider('v1'));

  group('Retry', () {
    test('a failed run keeps the recording and Retry processes that same '
        'recording', () async {
      final pipeline = _Pipeline(
        const NetworkFailure('Could not reach backend: SocketException'),
      );
      final c = containerFor(pipeline);

      await controller(c).stopAndProcess();
      expect(stateOf(c).stage, ConsultationStage.error);
      expect(stateOf(c).errorCode, FailureCode.network);
      expect(stateOf(c).canRetryProcessing, isTrue);
      expect(
        (await VisitRepository(db).byId('v1'))!.audioPath,
        '/tmp/visit.m4a',
      );

      pipeline.fail = false;
      await controller(c).retryProcessing();

      expect(stateOf(c).stage, ConsultationStage.done);
      expect(pipeline.processed, ['/tmp/visit.m4a', '/tmp/visit.m4a']);
      expect(recorder.stops, 1, reason: 'no second recording was needed');
      final visit = await VisitRepository(db).byId('v1');
      expect(visit!.insight!.diagnosis, 'Viral fever');
    });

    test('a recording with nothing in it is not offered for retry', () async {
      final pipeline = _Pipeline(
        const ApiFailure(
          'Sarvam produced no transcript',
          code: FailureCode.invalidAudio,
        ),
      );
      final c = containerFor(pipeline);
      await controller(c).stopAndProcess();
      expect(stateOf(c).nothingHeard, isTrue);
      expect(stateOf(c).canRetryProcessing, isFalse);
    });

    test('recording again replaces the failed recording', () async {
      final c = containerFor(_Pipeline(const NetworkFailure('offline')));
      await controller(c).stopAndProcess();
      await controller(c).startRecording();
      expect(stateOf(c).stage, ConsultationStage.recording);
      expect(stateOf(c).audioPath, isNull);
      expect(stateOf(c).errorCode, isNull);
      expect(stateOf(c).canRetryProcessing, isFalse);
    });
  });

  testWidgets('losing the internet while recording does not pause the '
      'recording', (tester) async {
    final c = containerFor(_Pipeline(const NetworkFailure('offline')));
    final connectivity = c.read(connectivityStatusProvider.notifier);
    await tester.runAsync(() => controller(c).startRecording());

    final router = GoRouter(
      initialLocation: '/recording/v1',
      routes: [
        GoRoute(
          path: '/recording/:visitId',
          builder: (_, s) =>
              RecordingScreen(visitId: s.pathParameters['visitId']!),
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

    // Android closes a locked phone's connections; a clinic network drops.
    (connectivity as _Online).set(ConnectivityStatus.offline);
    await tester.pump(const Duration(milliseconds: 300));

    expect(recorder.pauses, 0);
    expect(stateOf(c).stage, ConsultationStage.recording);
    expect(
      find.text(
        'No internet. Recording continues; the consultation is processed '
        'once you are back online.',
      ),
      findsOneWidget,
    );
    // Leave the recording screen cleanly.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the recording screen explains the failure and retries with '
      'the saved recording', (tester) async {
    final pipeline = _Pipeline(
      const NetworkFailure('Could not reach backend: SocketException'),
    );
    final c = containerFor(pipeline);
    await tester.runAsync(() => controller(c).stopAndProcess());

    final router = GoRouter(
      initialLocation: '/recording/v1',
      routes: [
        GoRoute(
          path: '/recording/:visitId',
          builder: (_, s) =>
              RecordingScreen(visitId: s.pathParameters['visitId']!),
        ),
        GoRoute(
          path: '/review/:visitId',
          builder: (_, _) => const Scaffold(body: Text('REVIEW SCREEN')),
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

    expect(
      find.text(
        'No internet connection. Your recording is saved on this phone; '
        'tap Retry when you are back online.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('SocketException'), findsNothing);
    expect(find.text('Record again'), findsOneWidget);

    pipeline.fail = false;
    await tester.tap(find.text('Retry with this recording'));
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('REVIEW SCREEN'), findsOneWidget);
    expect(recorder.stops, 1);
  });
}
