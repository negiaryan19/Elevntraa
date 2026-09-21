import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rxvarta/services/drug_name_corrector.dart';

/// A medicine name can carry its strength ("Metformin 500", "Augmentin 625",
/// "Propranolol 10 mg"): that is how doctors dictate it and how the extractor
/// is told to return it, so the dosage column stays free for the amount taken
/// each time ("1 tablet"). The corrector writes its result straight onto the
/// prescription, so it must never lose that strength, and a brand must stay a
/// brand whether or not a strength follows it.
void main() {
  late DrugNameCorrector corrector;

  setUpAll(() {
    final raw = File('assets/data/drug_dictionary.json').readAsStringSync();
    final entries =
        ((json.decode(raw) as Map<String, dynamic>)['entries'] as List)
            .cast<Map<String, dynamic>>();
    corrector = DrugNameCorrector.fromJsonList(entries);
  });

  /// The name that would end up on the prescription.
  String resolved(String spoken) {
    final match = corrector.correct(spoken);
    return match == null ? spoken : match.canonical;
  }

  group('a generic keeps its strength', () {
    for (final name in [
      'Metformin 500',
      'Azithromycin 500',
      'Propranolol 10 mg',
      'Propranolol 10mg',
      'Amoxicillin 250 mg',
    ]) {
      test(name, () => expect(resolved(name), name));
    }
  });

  group('a brand with a strength is still that brand', () {
    // Without the strength these are kept verbatim by the brand guard; adding
    // "625" must not turn Augmentin into its generic.
    for (final name in ['Augmentin 625', 'Dolo 650', 'Telma 40', 'Pan 40']) {
      test(name, () {
        expect(resolved(name.split(' ').first), name.split(' ').first);
        expect(resolved(name), name);
      });
    }
  });

  group('a misspelt generic is corrected and keeps its strength', () {
    test('Parcetamol 650', () {
      expect(resolved('parcetamol'), 'Paracetamol', reason: 'precondition');
      expect(resolved('Parcetamol 650'), 'Paracetamol 650');
    });
    test('the unit is kept as dictated', () {
      expect(resolved('Parcetamol 650 mg'), 'Paracetamol 650 mg');
      expect(resolved('Parcetamol 650mg'), 'Paracetamol 650mg');
    });
  });

  group('not mistaken for a strength', () {
    test('a bare number is not a medicine', () {
      expect(corrector.correct('500'), isNull);
      expect(corrector.correct('650 mg'), isNull);
    });
    test('a name with no strength behaves as before', () {
      expect(resolved('parcetamol'), 'Paracetamol');
      expect(resolved('Crocin'), 'Crocin');
    });
  });
}
