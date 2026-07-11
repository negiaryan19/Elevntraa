import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxvarta/services/differential_engine.dart';

void main() {
  late DifferentialEngine engine;

  setUpAll(() {
    final jsonString = File(
      'assets/data/differential_rules.json',
    ).readAsStringSync();
    engine = DifferentialEngine.fromJsonString(jsonString);
  });

  group('DifferentialEngine — loading', () {
    test('loads all rules from JSON', () {
      expect(engine.ruleCount, equals(34));
    });
  });

  group('DifferentialEngine — empty / vague input', () {
    test('returns empty for empty symptom list', () {
      expect(engine.suggest([]), isEmpty);
    });

    test('returns empty for blank strings', () {
      expect(engine.suggest(['', '   ', '']), isEmpty);
    });

    test('returns empty for truly vague symptoms with no anchor match', () {
      final results = engine.suggest(['not feeling well', 'unease']);
      expect(results, isEmpty);
    });
  });

  group('DifferentialEngine — anchor gating', () {
    test('TB does NOT fire on just fever + sweating + weight loss', () {
      // These are TB symptoms but NOT anchors — cough/hemoptysis is required
      final results = engine.suggest(['fever', 'night sweats', 'weight loss']);
      final tb = results.where((r) => r.icdCode == 'A15.0');
      expect(tb, isEmpty, reason: 'TB must not fire without cough anchor');
    });

    test('TB DOES fire when persistent cough is present', () {
      final results = engine.suggest([
        'persistent cough',
        'fever',
        'night sweats',
        'weight loss',
      ]);
      final tb = results.where((r) => r.icdCode == 'A15.0');
      expect(tb, isNotEmpty, reason: 'TB should fire with cough anchor');
    });

    test('scabies does NOT fire on generic itching + rash', () {
      // "itching" alone doesn't satisfy "intense itching at night" anchor
      // because direction is ps.contains(anchor) and
      // "itching".contains("intense itching at night") is false.
      final results = engine.suggest(['itching', 'rash']);
      final scabies = results.where((r) => r.icdCode == 'B86');
      expect(
        scabies,
        isEmpty,
        reason: 'Scabies needs nocturnal/finger-web anchor',
      );
    });

    test('scabies DOES fire with nocturnal itching', () {
      final results = engine.suggest([
        'intense itching at night',
        'rash between fingers',
      ]);
      final scabies = results.where((r) => r.icdCode == 'B86');
      expect(scabies, isNotEmpty);
    });
  });

  group('DifferentialEngine — correct substring direction', () {
    test('generic "khujli" does NOT satisfy "raat ko bahut khujli" anchor', () {
      // ps = "khujli", anchor = "raat ko bahut khujli"
      // "khujli".contains("raat ko bahut khujli") → false ✓
      final results = engine.suggest(['khujli', 'daane']);
      final scabies = results.where((r) => r.icdCode == 'B86');
      expect(scabies, isEmpty);
    });

    test('specific "raat ko bahut khujli" DOES satisfy the anchor', () {
      // ps = "raat ko bahut khujli", anchor = "raat ko bahut khujli"
      // "raat ko bahut khujli".contains("raat ko bahut khujli") → true ✓
      final results = engine.suggest([
        'raat ko bahut khujli',
        'ungliyon ke beech daane',
      ]);
      final scabies = results.where((r) => r.icdCode == 'B86');
      expect(scabies, isNotEmpty);
    });
  });

  group('DifferentialEngine — ICD deduplication', () {
    test('at most one entry per ICD code', () {
      final results = engine.suggest([
        'burning urination',
        'frequent urination',
        'fever',
        'lower abdominal pain',
        'cloudy urine',
      ]);
      final icdCounts = <String, int>{};
      for (final r in results) {
        icdCounts[r.icdCode] = (icdCounts[r.icdCode] ?? 0) + 1;
      }
      for (final entry in icdCounts.entries) {
        expect(
          entry.value,
          equals(1),
          reason: '${entry.key} appeared ${entry.value} times',
        );
      }
    });
  });

  group('DifferentialEngine — common presentations', () {
    test('URTI for cold + sore throat + sneezing', () {
      final results = engine.suggest([
        'cold',
        'sore throat',
        'sneezing',
        'mild fever',
      ]);
      expect(results, isNotEmpty);
      expect(results.first.icdCode, equals('J06.9'));
    });

    test('dehydration for dry mouth + decreased urine + thirst', () {
      final results = engine.suggest([
        'dry mouth',
        'decreased urine',
        'thirst',
        'dizziness',
      ]);
      final dehydration = results.where((r) => r.icdCode == 'E86.0');
      expect(dehydration, isNotEmpty);
    });

    test('gastroenteritis for loose motions + vomiting + cramps', () {
      final results = engine.suggest([
        'loose motions',
        'vomiting',
        'abdominal cramps',
      ]);
      final ge = results.where((r) => r.icdCode == 'A09');
      expect(ge, isNotEmpty);
    });

    test('UTI for burning urination + frequency', () {
      final results = engine.suggest([
        'burning urination',
        'frequent urination',
        'lower abdominal pain',
      ]);
      final uti = results.where((r) => r.icdCode == 'N39.0');
      expect(uti, isNotEmpty);
    });

    test('migraine for one-sided headache + nausea + light sensitivity', () {
      final results = engine.suggest([
        'one-sided headache',
        'nausea',
        'light sensitivity',
      ]);
      final migraine = results.where((r) => r.icdCode == 'G43.9');
      expect(migraine, isNotEmpty);
    });

    test(
      'diabetes for frequent urination + excessive thirst + weight loss',
      () {
        final results = engine.suggest([
          'frequent urination',
          'excessive thirst',
          'weight loss',
          'fatigue',
        ]);
        final dm = results.where((r) => r.icdCode == 'E11.9');
        expect(dm, isNotEmpty);
      },
    );
  });

  group('DifferentialEngine — red flags', () {
    test('MI carries a red flag', () {
      final results = engine.suggest([
        'chest pain',
        'sweating',
        'breathlessness',
        'left arm pain',
      ]);
      final mi = results.where((r) => r.icdCode == 'I21.9');
      expect(mi, isNotEmpty);
      expect(mi.first.isRedFlag, isTrue);
      expect(mi.first.redFlag, contains('EMERGENCY'));
    });

    test('appendicitis carries a red flag', () {
      final results = engine.suggest([
        'right lower abdominal pain',
        'nausea',
        'vomiting',
        'fever',
      ]);
      final appendicitis = results.where((r) => r.icdCode == 'K35.9');
      expect(appendicitis, isNotEmpty);
      expect(appendicitis.first.isRedFlag, isTrue);
    });

    test('pneumonia carries a red flag', () {
      final results = engine.suggest([
        'cough with sputum',
        'breathlessness',
        'high fever',
        'chills',
      ]);
      final pneumonia = results.where((r) => r.icdCode == 'J18.9');
      expect(pneumonia, isNotEmpty);
      expect(pneumonia.first.isRedFlag, isTrue);
    });
  });

  group('DifferentialEngine — vernacular / Hinglish', () {
    test('Hindi symptoms resolve correctly', () {
      final results = engine.suggest([
        'bukhar',
        'sardi',
        'khansi',
        'badan dard',
      ]);
      expect(results, isNotEmpty);
      // Should pick up URTI or viral fever
      final codes = results.map((r) => r.icdCode).toSet();
      expect(
        codes.intersection({'J06.9', 'B34.9'}).isNotEmpty,
        isTrue,
        reason: 'Should match URTI or viral fever for Hindi symptoms',
      );
    });

    test('Hindi GI symptoms resolve', () {
      final results = engine.suggest([
        'pet mein jalan',
        'ji machlana',
        'bhook na lagna',
      ]);
      final gastritis = results.where((r) => r.icdCode == 'K29.1');
      expect(gastritis, isNotEmpty);
    });

    test('Hindi dehydration symptoms resolve', () {
      final results = engine.suggest([
        'muh sokhna',
        'kam peshab',
        'bahut pyaas',
      ]);
      final dehydration = results.where((r) => r.icdCode == 'E86.0');
      expect(dehydration, isNotEmpty);
    });
  });

  group('DifferentialEngine — output quality', () {
    test('every suggestion has reason and matched symptoms', () {
      final results = engine.suggest([
        'one-sided headache',
        'nausea',
        'light sensitivity',
      ]);
      for (final r in results) {
        expect(r.reason, isNotEmpty, reason: '${r.name} missing reason');
        expect(
          r.matchedSymptoms,
          isNotEmpty,
          reason: '${r.name} missing matched symptoms',
        );
        expect(r.icdCode, isNotEmpty, reason: '${r.name} missing ICD code');
        expect(r.name, isNotEmpty);
        expect(r.category, isNotEmpty);
      }
    });

    test('results are sorted by score descending', () {
      final results = engine.suggest([
        'fever',
        'cold',
        'sore throat',
        'sneezing',
        'runny nose',
        'body ache',
      ]);
      if (results.length > 1) {
        for (int i = 0; i < results.length - 1; i++) {
          expect(
            results[i].score,
            greaterThanOrEqualTo(results[i + 1].score),
            reason: 'Results should be sorted by score descending',
          );
        }
      }
    });

    test('maxResults limits output', () {
      final results = engine.suggest([
        'fever',
        'cold',
        'sore throat',
        'sneezing',
        'body ache',
        'cough',
      ], maxResults: 2);
      expect(results.length, lessThanOrEqualTo(2));
    });
  });
}
