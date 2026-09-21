import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rxvarta/services/drug_name_corrector.dart';

/// Safety regressions for the on-device drug-name corrector.
///
/// The consultation controller writes the corrected name straight onto the
/// prescription, so a wrong rewrite changes what the patient is given. These
/// cases pin the two failure shapes found in the field:
///   * a combination product collapsing into one of its ingredients, which
///     silently deletes the other ingredient;
///   * a longer molecule collapsing into a shorter, different one that
///     happens to be spelled inside it.
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

  group('combination products keep every ingredient', () {
    for (final combo in [
      'Ibuprofen + Paracetamol',
      'Aspirin + Clopidogrel',
      'Montelukast + Levocetirizine',
      'Amlodipine/Atenolol',
      'Paracetamol & Caffeine',
    ]) {
      test('"$combo" is not collapsed to a single drug', () {
        final out = resolved(combo).toLowerCase();
        final parts = combo
            .toLowerCase()
            .split(RegExp(r'\s*[+/&]\s*'))
            .where((p) => p.isNotEmpty);
        for (final part in parts) {
          expect(
            out,
            contains(part),
            reason: '"$combo" lost "$part" and became "${resolved(combo)}"',
          );
        }
      });
    }

    test('two drugs dictated without a separator are left as spoken', () {
      expect(resolved('ibuprofen paracetamol'), 'ibuprofen paracetamol');
    });
  });

  group('a longer molecule is never turned into a shorter one', () {
    for (final pair in const [
      ['Levocetirizine', 'Cetirizine'],
      ['Escitalopram', 'Citalopram'],
      ['Dexamethasone', 'Methasone'],
    ]) {
      test('"${pair[0]}" does not become "${pair[1]}"', () {
        expect(resolved(pair[0]).toLowerCase(), isNot(pair[1].toLowerCase()));
      });
    }
  });

  group('genuine corrections still work', () {
    test('a misspelled generic is corrected', () {
      expect(resolved('parcetamol'), 'Paracetamol');
    });

    test('dosage-form noise is stripped; the strength is kept', () {
      // "tab" is noise. "500mg" is not: it is the only record of the strength
      // once the name is rewritten (see drug_name_corrector_strength_test).
      expect(resolved('tab paracetamol 500mg'), 'Paracetamol 500mg');
      expect(resolved('tab paracetamol'), 'Paracetamol');
    });

    test('an exact generic is returned unchanged', () {
      expect(resolved('Paracetamol'), 'Paracetamol');
    });
  });
}
