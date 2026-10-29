import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rxvarta/app/app.dart';
import 'package:rxvarta/core/network/connectivity_provider.dart';
import 'package:rxvarta/core/prefs/shared_preferences_provider.dart';
import 'package:rxvarta/data/db/app_database.dart';
import 'package:rxvarta/data/db/database_provider.dart';
import 'package:rxvarta/data/repositories/visit_repository.dart';
import 'package:rxvarta/domain/models/medical_insight.dart';
import 'package:rxvarta/domain/models/medication.dart';
import 'package:rxvarta/domain/models/visit.dart';
import 'package:rxvarta/features/consultation/data/pending_consultations.dart';
import 'package:rxvarta/features/consultation/data/pipeline_service.dart';
import 'package:rxvarta/features/consultation/data/recording_service.dart';

/// The queue must not depend on which screen is open. If only the Home card
/// kept it alive, a consultation recorded offline would wait for the doctor
/// to happen to be looking at Home when the internet came back.
class _Recorder implements RecordingService {
  @override
  Future<Duration?> probeDuration(String path) async =>
      const Duration(seconds: 20);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Pipeline implements PipelineService {
  final processed = <String>[];

  @override
  Future<InsightResult> processConsultation({
    required String audioPath,
    required String languageCode,
    Duration? audioDuration,
    String? previousTranscript,
  }) async {
    processed.add(audioPath);
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
}

void main() {
  testWidgets('the app itself drains the queue, with Home nowhere on screen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.runAsync(
      () => VisitRepository(db).upsert(
        VisitRecord(
          id: 'v1',
          patientId: 'p1',
          createdAt: DateTime(2026, 9, 22),
          audioPath: '/tmp/v1.m4a',
          pendingState: PendingState.queued,
        ),
      ),
    );
    final pipeline = _Pipeline();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(db),
        recordingServiceProvider.overrideWithValue(_Recorder()),
        pipelineServiceProvider.overrideWithValue(pipeline),
        connectivityStatusProvider.overrideWith(_Online.new),
        audioFileExistsProvider.overrideWithValue((_) => true),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RxvartaApp(),
      ),
    );
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Without a backend the app sits on the login screen: no Home, no card.
    expect(find.text('App not configured'), findsOneWidget);
    expect(find.byKey(const Key('pending_consultations_card')), findsNothing);

    expect(pipeline.processed, ['/tmp/v1.m4a']);
    final visit = await tester.runAsync<VisitRecord?>(
      () => VisitRepository(db).byId('v1'),
    );
    expect(visit!.pendingState, PendingState.ready);

    // The queue's retry timer lives as long as its provider.
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await tester.pump(const Duration(seconds: 1));
  });
}
