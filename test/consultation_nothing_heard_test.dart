import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxvarta/core/errors/failure.dart';
import 'package:rxvarta/data/db/app_database.dart';
import 'package:rxvarta/data/db/database_provider.dart';
import 'package:rxvarta/data/repositories/visit_repository.dart';
import 'package:rxvarta/domain/models/medical_insight.dart';
import 'package:rxvarta/domain/models/medication.dart';
import 'package:rxvarta/domain/models/visit.dart';
import 'package:rxvarta/features/consultation/data/pipeline_service.dart';
import 'package:rxvarta/features/consultation/data/recording_service.dart';
import 'package:rxvarta/features/consultation/presentation/consultation_controller.dart';

/// A recording with no consultation in it (a muted or broken microphone, the
/// emulator's test tone) came back as a made-up sentence and an empty
/// extraction. The app still opened Review, and the doctor got a blank
/// prescription with no hint that nothing had been heard.
class _FakeRecorder implements RecordingService {
  @override
  Future<String?> stop() async => '/tmp/visit.m4a';

  @override
  Future<Duration?> probeDuration(String path) async =>
      const Duration(seconds: 20);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePipeline implements PipelineService {
  _FakePipeline(this.respond);

  final Future<InsightResult> Function() respond;

  @override
  Future<InsightResult> processConsultation({
    required String audioPath,
    required String languageCode,
    Duration? audioDuration,
    String? previousTranscript,
  }) => respond();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await VisitRepository(db).upsert(
      VisitRecord(id: 'v1', patientId: 'p1', createdAt: DateTime(2026, 9, 17)),
    );
  });
  tearDown(() async => db.close());

  Future<ProviderContainer> run(
    Future<InsightResult> Function() respond,
  ) async {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        recordingServiceProvider.overrideWithValue(_FakeRecorder()),
        pipelineServiceProvider.overrideWithValue(_FakePipeline(respond)),
      ],
    );
    addTearDown(container.dispose);
    await container
        .read(consultationControllerProvider('v1').notifier)
        .stopAndProcess();
    return container;
  }

  Future<ProviderContainer> process(InsightResult result) =>
      run(() async => result);

  test('an empty extraction says nothing was heard instead of opening '
      'a blank prescription', () async {
    final container = await process(
      const InsightResult(
        transcript: 'મ્યુઝિક ઉશ્મિ આવે છે ત્યાં સામે.',
        insight: MedicalInsight.empty,
      ),
    );

    final state = container.read(consultationControllerProvider('v1'));
    expect(state.stage, ConsultationStage.error);
    expect(state.nothingHeard, isTrue);
    // The meaningless transcript must not become the consultation.
    expect(container.read(cumulativeTranscriptProvider), isEmpty);
    final visit = await VisitRepository(db).byId('v1');
    expect(visit!.insight, isNull);
    expect(visit.transcript, isNull);
  });

  test('a real consultation still goes on to Review', () async {
    final container = await process(
      const InsightResult(
        transcript: 'Paracetamol 500 mg twice a day for three days.',
        insight: MedicalInsight(
          diagnosis: 'Viral fever',
          medications: [Medication(name: 'Paracetamol', dosage: '500 mg')],
        ),
      ),
    );

    final state = container.read(consultationControllerProvider('v1'));
    expect(state.stage, ConsultationStage.done);
    expect(state.nothingHeard, isFalse);
    final visit = await VisitRepository(db).byId('v1');
    expect(visit!.insight!.diagnosis, 'Viral fever');
  });

  test('Sarvam finding no speech is reported as nothing heard', () async {
    // What the device showed: the raw backend text, in red.
    final container = await run(
      () => Future.error(
        ApiFailure(
          'Pipeline function error: {error: Sarvam produced no transcript '
          '— likely silent audio.}',
          code: pipelineErrorCode({
            'error': 'Sarvam produced no transcript — likely silent audio.',
          }),
        ),
      ),
    );
    final state = container.read(consultationControllerProvider('v1'));
    expect(state.stage, ConsultationStage.error);
    expect(state.nothingHeard, isTrue);
  });

  test('other pipeline failures are not mistaken for silence', () async {
    final container = await run(
      () => Future.error(
        ApiFailure(
          'Pipeline returned HTTP 500: Gemini 503',
          code: pipelineErrorCode({'error': 'Gemini 503 overloaded'}),
        ),
      ),
    );
    final state = container.read(consultationControllerProvider('v1'));
    expect(state.stage, ConsultationStage.error);
    expect(state.nothingHeard, isFalse);
  });

  test('both of Sarvam\'s no-speech errors are recognised', () {
    for (final message in [
      'Sarvam produced no transcript — likely silent audio.',
      'Sarvam heard audio but produced no transcript (no language detected).',
    ]) {
      expect(pipelineErrorCode({'error': message}), FailureCode.invalidAudio);
      expect(
        pipelineErrorCode('Transcription failed: $message'),
        FailureCode.invalidAudio,
      );
    }
    expect(pipelineErrorCode(null), FailureCode.server);
    expect(pipelineErrorCode({'error': 'Sarvam REST 401'}), FailureCode.server);
  });

  test('clinical content is anything the doctor dictated', () {
    expect(MedicalInsight.empty.hasClinicalContent, isFalse);
    expect(
      const MedicalInsight(
        doctorNotes: '',
        differentials: [],
      ).hasClinicalContent,
      isFalse,
    );
    for (final insight in const [
      MedicalInsight(consultationSummary: 'Counselled on diet.'),
      MedicalInsight(symptoms: ['cough']),
      MedicalInsight(diagnosis: 'Hypertension'),
      MedicalInsight(medications: [Medication(name: 'Amlodipine')]),
      MedicalInsight(tests: ['CBC']),
      MedicalInsight(advice: ['Walk daily']),
      MedicalInsight(instructions: ['Return if fever persists']),
      MedicalInsight(followUpDays: 7),
    ]) {
      expect(insight.hasClinicalContent, isTrue, reason: '$insight');
    }
  });
}
