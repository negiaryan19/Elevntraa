import 'package:flutter_test/flutter_test.dart';
import 'package:rxvarta/domain/models/medical_insight.dart';

/// The extraction comes from a language model that does not always honour
/// the schema. A strict decoder threw on the first mismatch and the entire
/// recorded consultation was lost. These tests pin that a mismatch is
/// coerced instead, and that nothing the doctor dictated is dropped.
void main() {
  group('MedicalInsight.fromJson tolerates model output', () {
    test('a comma-separated string of symptoms becomes a list', () {
      final insight = MedicalInsight.fromJson({
        'diagnosis': 'Viral fever',
        'symptoms': 'fever, cough; body ache',
      });
      expect(insight.symptoms, ['fever', 'cough', 'body ache']);
    });

    test('a numeric-string follow-up is parsed', () {
      expect(MedicalInsight.fromJson({'followUpDays': '5'}).followUpDays, 5);
      expect(
        MedicalInsight.fromJson({'followUpDays': '7 days'}).followUpDays,
        7,
      );
      expect(MedicalInsight.fromJson({'followUpDays': 3.0}).followUpDays, 3);
    });

    test('a non-numeric follow-up becomes null rather than throwing', () {
      expect(
        MedicalInsight.fromJson({'followUpDays': 'soon'}).followUpDays,
        isNull,
      );
    });

    test('a numeric diagnosis is kept as text', () {
      expect(MedicalInsight.fromJson({'diagnosis': 2}).diagnosis, '2');
    });

    test('a medicine with no name is kept, not fatal', () {
      final insight = MedicalInsight.fromJson({
        'medications': [
          {'dosage': '650mg', 'frequency': '1-0-1'},
        ],
      });
      expect(insight.medications, hasLength(1));
      expect(insight.medications.single.name, '');
      expect(insight.medications.single.dosage, '650mg');
    });

    test('medicines given as plain strings are kept as rows', () {
      final insight = MedicalInsight.fromJson({
        'medications': ['Paracetamol 650', 'Cetirizine 10'],
      });
      expect(insight.medications.map((m) => m.name), [
        'Paracetamol 650',
        'Cetirizine 10',
      ]);
    });

    test('medicines given as one string are split into rows', () {
      final insight = MedicalInsight.fromJson({
        'medications': 'Paracetamol 650\nCetirizine 10',
      });
      expect(insight.medications, hasLength(2));
    });

    test('a string needsReview flag is understood', () {
      final insight = MedicalInsight.fromJson({
        'medications': [
          {'name': 'Taxim', 'needsReview': 'true'},
        ],
      });
      expect(insight.medications.single.needsReview, isTrue);
    });

    test('well-formed JSON still round-trips exactly', () {
      final original = MedicalInsight.fromJson({
        'consultationSummary': 'Fever for three days.',
        'symptoms': ['fever'],
        'diagnosis': 'Viral fever',
        'medications': [
          {
            'name': 'Paracetamol',
            'dosage': '650mg',
            'frequency': '1-0-1',
            'duration': '3 days',
            'timing': 'After food',
            'needsReview': false,
          },
        ],
        'followUpDays': 3,
        'icdCode': 'B34.9',
      });
      expect(MedicalInsight.fromJson(original.toJson()), original);
    });
  });
}
