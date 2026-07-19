import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rxvarta/services/drug_name_corrector.dart';

/// On-device drug-name corrector eval — the Flutter counterpart to the Deno
/// drug_matcher_test.ts. Proves the brand-guard behaves identically on-device.
///
/// The controller keeps a medicine's original name when [correct] returns null
/// (brand / brand look-alike / no confident match), so "null" here means
/// "recognized but NOT rewritten — name stays as the doctor said it".
///
/// Run: flutter test test/drug_name_corrector_eval_test.dart -r expanded
void main() {
  late DrugNameCorrector corrector;

  setUpAll(() {
    final raw = File('assets/data/drug_dictionary.json').readAsStringSync();
    final map = json.decode(raw) as Map<String, dynamic>;
    final list = (map['entries'] as List).cast<Map<String, dynamic>>();
    corrector = DrugNameCorrector.fromJsonList(list);
  });

  test('case 1 — crocin survives unchanged (brand, not rewritten)', () {
    expect(
      corrector.correct('Crocin'),
      isNull,
      reason: 'crocin is a brand → kept verbatim, not rewritten to Paracetamol',
    );
  });

  test('case 2 — parcetamol corrects to Paracetamol', () {
    final m = corrector.correct('parcetamol');
    expect(m, isNotNull);
    expect(m!.canonical, 'Paracetamol');
  });

  test('case 4 — dollo recognized but NOT rewritten', () {
    expect(
      corrector.correct('Dollo'),
      isNull,
      reason: 'dollo romanNorm → "dolo" (a brand) → kept, not rewritten',
    );
  });

  test('sanity — a plain generic misspelling still corrects', () {
    expect(corrector.correct('paracitamol')?.canonical, 'Paracetamol');
    expect(corrector.correct('azithromicin')?.canonical, 'Azithromycin');
  });
}
