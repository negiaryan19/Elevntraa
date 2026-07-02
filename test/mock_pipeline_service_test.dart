import 'package:flutter_test/flutter_test.dart';

import 'package:rxvarta/features/consultation/data/mock_pipeline_service.dart';

/// [MockPipelineService] is the emulator/debug stand-in wired in when
/// `--dart-define=DEBUG_SKIP_STT=true`. It must return the fixed insight the
/// smoke test asserts on, without any network or AI calls.
void main() {
  group('MockPipelineService', () {
    final service = MockPipelineService();

    test('returns the hardcoded viral-fever insight', () async {
      final result = await service.processConsultation(
        audioPath: '/tmp/fake.m4a',
        languageCode: 'unknown',
      );

      final insight = result.insight;
      expect(insight.diagnosis, 'Viral fever with body ache');
      expect(insight.followUpDays, 3);

      final medNames = insight.medications.map((m) => m.name).toList();
      expect(medNames, containsAll(['Paracetamol', 'Cetirizine', 'Vitamin C']));

      final paracetamol = insight.medications.firstWhere(
        (m) => m.name == 'Paracetamol',
      );
      expect(paracetamol.dosage, '500mg');

      final cetirizine = insight.medications.firstWhere(
        (m) => m.name == 'Cetirizine',
      );
      expect(cetirizine.dosage, '10mg');

      final vitaminC = insight.medications.firstWhere(
        (m) => m.name == 'Vitamin C',
      );
      expect(vitaminC.dosage, '500mg');

      expect(result.transcript, isNotEmpty);
    });

    test('appends to the previous transcript in "Add More" mode', () async {
      final result = await service.processConsultation(
        audioPath: '/tmp/fake.m4a',
        languageCode: 'unknown',
        previousTranscript: 'Doctor: Earlier segment.',
      );

      // The combined transcript keeps the prior text and grows.
      expect(result.transcript, startsWith('Doctor: Earlier segment.'));
      expect(result.transcript.length, greaterThan('Doctor: Earlier segment.'.length));
      // Insight is still the fixed mock payload.
      expect(result.insight.followUpDays, 3);
    });
  });
}
