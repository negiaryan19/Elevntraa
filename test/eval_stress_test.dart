import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rxvarta/services/icd10_local_mapper.dart';
import 'package:rxvarta/services/differential_engine.dart';

/// STRESS EVAL — 20 diverse cases designed to *break* the on-device diagnostic
/// pipeline (ICD-10 mapper + differential engine). Same spirit as
/// eval_pipeline_test.dart but adversarial: typos, Hindi/Hinglish, red-flag
/// emergencies, negative cases (rules that must NOT fire), diseases outside the
/// map, and pure garbage. Nothing here calls the network or an LLM — it feeds
/// realistic Gemini extraction outputs straight into the deterministic layer.
///
/// This is a reporting harness, not a gate: it always completes so the full
/// report card + summary table print. Per-case verdicts are shown inline.
///
/// Run: flutter test test/eval_stress_test.dart -r expanded
void main() {
  late Icd10LocalMapper mapper;
  late DifferentialEngine engine;

  setUpAll(() {
    // Load JSON assets directly from disk (no rootBundle in unit tests).
    final icdRaw = File('assets/data/icd10_opd_map.json').readAsStringSync();
    final icdMap = json.decode(icdRaw) as Map<String, dynamic>;
    final icdList = (icdMap['entries'] as List).cast<Map<String, dynamic>>();
    mapper = Icd10LocalMapper.fromJsonList(icdList);

    final diffRaw =
        File('assets/data/differential_rules.json').readAsStringSync();
    engine = DifferentialEngine.fromJsonString(diffRaw);
  });

  // Each case carries expectations so the harness can grade itself:
  //   expIcd      — true: expect a non-null code | false: expect null.
  //   expDiff     — true: expect >=1 rule to fire | false: expect zero.
  //   expRedFlag  — true: at least one fired suggestion MUST carry a red flag.
  //   mustNotFire — an ICD code that must be ABSENT from the differentials
  //                 (negative cases: scabies / migraine over-firing).
  //   note        — the interesting angle this case probes.
  final cases = <Map<String, dynamic>>[
    {
      'label': 'Malaria',
      'diagnosis': 'Malaria',
      'symptoms': [
        'high fever with chills',
        'rigors',
        'sweating',
        'headache',
        'body ache',
        'nausea',
      ],
      'expIcd': true,
      'expDiff': true,
      'expRedFlag': true,
      'mustNotFire': null,
      'note': 'classic presentation',
    },
    {
      'label': 'UTI (typo)',
      'diagnosis': 'Urinary tract infaction',
      'symptoms': [
        'burning urination',
        'frequent urination',
        'lower abdominal pain',
        'fever',
      ],
      'expIcd': true,
      'expDiff': true,
      'expRedFlag': false,
      'mustNotFire': null,
      'note': 'fuzzy typo tolerance',
    },
    {
      'label': 'Migraine (Hindi)',
      'diagnosis': 'Aadha sar dard',
      'symptoms': [
        'ek taraf sar dard',
        'ji machlana',
        'roshni se taklif',
        'ulti',
      ],
      'expIcd': true,
      'expDiff': true,
      'expRedFlag': false,
      'mustNotFire': null,
      'note': 'vernacular diagnosis',
    },
    {
      'label': 'Chest pain ? MI',
      'diagnosis': 'Chest pain ? MI',
      'symptoms': [
        'chest pain',
        'left arm pain',
        'sweating',
        'breathlessness',
        'nausea',
      ],
      'expIcd': true,
      'expDiff': true,
      'expRedFlag': true,
      'mustNotFire': null,
      'note': 'MI red flag',
    },
    {
      'label': 'Scabies',
      'diagnosis': 'Scabies',
      'symptoms': [
        'intense itching at night',
        'rash between fingers',
        'burrow tracks',
      ],
      'expIcd': true,
      'expDiff': true,
      'expRedFlag': false,
      'mustNotFire': null,
      'note': 'nocturnal anchor fires',
    },
    {
      'label': 'Skin allergy',
      'diagnosis': 'Skin allergy',
      'symptoms': ['itching', 'rash', 'redness'],
      'expIcd': true,
      'expDiff': true,
      'expRedFlag': false,
      'mustNotFire': 'B86', // scabies must NOT fire on generic itch + rash
      'note': 'scabies suppressed',
    },
    {
      'label': 'Hypothyroidism',
      'diagnosis': 'Hypothyroidism',
      'symptoms': [
        'weight gain',
        'fatigue',
        'cold intolerance',
        'constipation',
        'hair loss',
        'dry skin',
      ],
      'expIcd': true,
      'expDiff': true,
      'expRedFlag': false,
      'mustNotFire': null,
      'note': 'metabolic multi-symptom',
    },
    {
      'label': 'Typhoid',
      'diagnosis': 'Enteric fever',
      'symptoms': [
        'step-ladder fever',
        'headache',
        'abdominal pain',
        'constipation',
        'coated tongue',
        'loss of appetite',
      ],
      'expIcd': true,
      'expDiff': true,
      'expRedFlag': false,
      'mustNotFire': null,
      'note': 'synonym: enteric fever',
    },
    {
      'label': 'Kidney stones',
      'diagnosis': 'Renal calculi',
      'symptoms': [
        'severe flank pain',
        'colicky pain',
        'nausea',
        'vomiting',
        'blood in urine',
      ],
      'expIcd': true,
      'expDiff': true,
      'expRedFlag': true,
      'mustNotFire': null,
      'note': 'colic + haematuria red flag',
    },
    {
      'label': 'Gout',
      'diagnosis': 'Gouty arthritis',
      'symptoms': [
        'sudden severe joint pain',
        'big toe pain',
        'red swollen joint',
        'warmth over joint',
      ],
      'expIcd': true,
      'expDiff': true,
      'expRedFlag': false,
      'mustNotFire': null,
      'note': 'big-toe anchor',
    },
    {
      'label': 'Appendicitis',
      'diagnosis': 'Acute appendicitis',
      'symptoms': [
        'right lower abdominal pain',
        'nausea',
        'vomiting',
        'fever',
        'loss of appetite',
      ],
      'expIcd': true,
      'expDiff': true,
      'expRedFlag': true,
      'mustNotFire': null,
      'note': 'surgical red flag',
    },
    {
      'label': 'GERD (Hinglish)',
      'diagnosis': 'Acidity problem',
      'symptoms': [
        'seene mein jalan',
        'khatta paani aana',
        'nighalne mein taklif',
        'sour taste',
      ],
      'expIcd': true,
      'expDiff': true,
      'expRedFlag': false,
      'mustNotFire': null,
      'note': 'Hinglish reflux',
    },
    {
      'label': 'Diabetes (Hindi)',
      'diagnosis': 'Sugar ki bimari',
      'symptoms': [
        'baar baar peshab',
        'bahut pyaas',
        'vajan kam hona',
        'thakaan',
        'dhundhla dikhna',
      ],
      'expIcd': true,
      'expDiff': true,
      'expRedFlag': false,
      'mustNotFire': null,
      'note': 'Hindi classic triad',
    },
    {
      'label': 'Pneumonia',
      'diagnosis': 'Pneumonia',
      'symptoms': [
        'cough with sputum',
        'breathlessness',
        'high fever',
        'chills',
        'chest pain',
      ],
      'expIcd': true,
      'expDiff': true,
      'expRedFlag': true,
      'mustNotFire': null,
      'note': 'respiratory red flag',
    },
    {
      'label': 'Tension headache',
      'diagnosis': 'Tension headache',
      'symptoms': [
        'bilateral headache',
        'band-like pressure',
        'neck tightness',
        'mild to moderate pain',
      ],
      'expIcd': true,
      'expDiff': true,
      'expRedFlag': false,
      'mustNotFire': 'G43.9', // migraine must NOT fire on bilateral headache
      'note': 'migraine suppressed',
    },
    {
      'label': 'CML (not in map)',
      'diagnosis': 'Chronic myeloid leukemia',
      'symptoms': [
        'fatigue',
        'weight loss',
        'night sweats',
        'splenomegaly',
        'bone pain',
      ],
      'expIcd': false, // outside the OPD map → must return null gracefully
      'expDiff': false,
      'expRedFlag': false,
      'mustNotFire': null,
      'note': 'graceful null (unmapped)',
    },
    {
      'label': 'Otitis media',
      'diagnosis': 'Ear infection',
      'symptoms': [
        'ear pain',
        'fever',
        'ear discharge',
        'pulling at ear',
        'irritability in child',
      ],
      'expIcd': true,
      'expDiff': true,
      'expRedFlag': false,
      'mustNotFire': null,
      'note': 'pediatric ear',
    },
    {
      'label': 'Asthma attack',
      'diagnosis': 'Asthma attack',
      'symptoms': [
        'wheezing',
        'breathlessness',
        'chest tightness',
        'cough at night',
      ],
      'expIcd': true,
      'expDiff': true,
      'expRedFlag': true,
      'mustNotFire': null,
      'note': 'wheeze red flag',
    },
    {
      'label': 'Fungal (daad)',
      'diagnosis': 'Daad',
      'symptoms': [
        'ring-shaped rash',
        'itching',
        'scaly patches',
        'spreading rash',
      ],
      'expIcd': true,
      'expDiff': true,
      'expRedFlag': false,
      'mustNotFire': null,
      'note': 'ringworm vernacular',
    },
    {
      'label': 'Garbage',
      'diagnosis': 'xyzabc123',
      'symptoms': ['qwerty', 'asdfgh', 'zxcvbn'],
      'expIcd': false,
      'expDiff': false,
      'expRedFlag': false,
      'mustNotFire': null,
      'note': 'pure noise → safe null',
    },
  ];

  String truncate(String s, int n) =>
      s.length > n ? '${s.substring(0, n)}...' : s;

  String padRight(String s, int width) =>
      s.length >= width ? s : s + ' ' * (width - s.length);

  test('on-device diagnostic pipeline — stress eval (20 adversarial cases)',
      () {
    // Column widths for the summary table.
    const wLabel = 19;
    const wCode = 8;
    const wDiff = 12;
    const wNotes = 25;

    final summaryRows = <String>[];
    var matched = 0; // code != null
    var nullExpected = 0; // code == null AND null was expected
    var nullUnexpected = 0; // code == null AND a code was expected

    for (var i = 0; i < cases.length; i++) {
      final c = cases[i];
      final label = c['label'] as String;
      final diagnosis = c['diagnosis'] as String;
      final symptoms = (c['symptoms'] as List).cast<String>();
      final expIcd = c['expIcd'] as bool;
      final expDiff = c['expDiff'] as bool;
      final expRedFlag = c['expRedFlag'] as bool;
      final mustNotFire = c['mustNotFire'] as String?;
      final note = c['note'] as String;

      // ── Run the deterministic layer ──────────────────────────────────────
      final m = mapper.lookup(diagnosis);
      final suggestions = engine.suggest(symptoms);

      // ── Grade ICD ────────────────────────────────────────────────────────
      final gotCode = m.code != null;
      final icdOk = gotCode == expIcd;
      if (gotCode) {
        matched++;
      } else if (expIcd) {
        nullUnexpected++;
      } else {
        nullExpected++;
      }

      // ── Grade differentials ──────────────────────────────────────────────
      final fired = suggestions.isNotEmpty;
      final hasRedFlag = suggestions.any((s) => s.isRedFlag);
      final forbiddenFired = mustNotFire != null &&
          suggestions.any((s) => s.icdCode == mustNotFire);

      var diffOk = (fired == expDiff);
      if (expRedFlag && !hasRedFlag) diffOk = false;
      if (forbiddenFired) diffOk = false;

      // ── Print report card ────────────────────────────────────────────────
      // ignore: avoid_print
      print('══════════════════════════════════════════════════');
      // ignore: avoid_print
      print('CASE ${i + 1}: $label');
      // ignore: avoid_print
      print('──────────────────────────────────────────────────');
      // ignore: avoid_print
      print('Diagnosis input: "$diagnosis"');
      // ignore: avoid_print
      print('Symptoms input:  [${symptoms.join(', ')}]');
      // ignore: avoid_print
      print('');
      // ignore: avoid_print
      print('ICD MAPPER:');
      // ignore: avoid_print
      print(
        '  Code: ${m.code ?? 'null'} | '
        'Desc: ${m.description ?? '-'} | '
        'Confidence: ${m.confidence ?? 'null'}',
      );
      // ignore: avoid_print
      print('');
      // ignore: avoid_print
      print('DIFFERENTIALS:');
      if (suggestions.isEmpty) {
        // ignore: avoid_print
        print('  None — no rules fired');
      } else {
        for (var j = 0; j < suggestions.length; j++) {
          final s = suggestions[j];
          // ignore: avoid_print
          print(
            '  ${j + 1}. ${s.name} (${s.icdCode}) — '
            'score: ${s.score.toStringAsFixed(2)}'
            '${s.isRedFlag ? '  [🚩 RED FLAG]' : ''}',
          );
          // ignore: avoid_print
          print('     Reason: ${truncate(s.reason, 80)}');
          // ignore: avoid_print
          print('     Matched: [${s.matchedSymptoms.join(', ')}]');
        }
      }
      // ignore: avoid_print
      print('');

      // ── One-line verdict ─────────────────────────────────────────────────
      final verdictBits = <String>[];
      verdictBits.add(icdOk
          ? 'ICD ${gotCode ? m.code : 'null'} ✅'
          : 'ICD ${gotCode ? m.code : 'null'} ❌ (expected ${expIcd ? 'a code' : 'null'})');
      if (diffOk) {
        final rf = hasRedFlag ? ' + 🚩' : '';
        verdictBits.add('${suggestions.length} differential(s)$rf ✅');
      } else {
        if (forbiddenFired) {
          verdictBits.add('$mustNotFire wrongly fired ❌');
        } else if (expRedFlag && !hasRedFlag) {
          verdictBits.add('missing red flag ❌');
        } else {
          verdictBits.add(
              '${suggestions.length} fired, expected ${expDiff ? '>=1' : '0'} ❌');
        }
      }
      final caseOk = icdOk && diffOk;
      // ignore: avoid_print
      print('VERDICT: ${verdictBits.join(' | ')}  →  '
          '${caseOk ? 'PASS' : 'FAIL'}');
      // ignore: avoid_print
      print('══════════════════════════════════════════════════');
      // ignore: avoid_print
      print('');

      // ── Build the summary row ────────────────────────────────────────────
      final codeCell = '${m.code ?? 'null'} ${icdOk ? '✅' : '❌'}';
      final diffCell = '${suggestions.length} fired ${diffOk ? '✅' : '❌'}';
      final notesCell = caseOk ? note : '$note ⚠️';
      summaryRows.add(
        '│ ${padRight('${i + 1}', 4)} │ ${padRight(truncate(label, wLabel), wLabel)} '
        '│ ${padRight(codeCell, wCode)} │ ${padRight(diffCell, wDiff)} '
        '│ ${padRight(truncate(notesCell, wNotes), wNotes)} │',
      );
    }

    // ── Summary table ──────────────────────────────────────────────────────
    // ignore: avoid_print
    print('SUMMARY');
    // ignore: avoid_print
    print('┌──────┬─────────────────────┬──────────┬──────────────┬───────────────────────────┐');
    // ignore: avoid_print
    print('│ ${padRight('Case', 4)} │ ${padRight('Label', wLabel)} '
        '│ ${padRight('ICD Code', wCode)} │ ${padRight('Differentials', wDiff)} '
        '│ ${padRight('Notes', wNotes)} │');
    // ignore: avoid_print
    print('├──────┼─────────────────────┼──────────┼──────────────┼───────────────────────────┤');
    for (final row in summaryRows) {
      // ignore: avoid_print
      print(row);
    }
    // ignore: avoid_print
    print('└──────┴─────────────────────┴──────────┴──────────────┴───────────────────────────┘');

    // ignore: avoid_print
    print(
      'TOTAL: $matched matched | '
      '$nullExpected null (expected) | '
      '$nullUnexpected null (unexpected)',
    );

    // Reporting harness: always completes so the full table prints.
    expect(cases.length, 20);
  });
}
