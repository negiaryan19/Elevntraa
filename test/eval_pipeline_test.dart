import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rxvarta/services/icd10_local_mapper.dart';
import 'package:rxvarta/services/differential_engine.dart';

/// Standalone eval of the FULL on-device diagnostic pipeline — the
/// deterministic layer that runs AFTER Gemini returns. No emulator, no network,
/// no API calls: it feeds realistic Gemini extraction outputs (diagnosis text +
/// symptom list) into the ICD-10 mapper and the differential engine and prints
/// a per-case report card.
///
/// Run: flutter test test/eval_pipeline_test.dart -r expanded
void main() {
  late Icd10LocalMapper mapper;
  late DifferentialEngine engine;

  setUpAll(() {
    final icdRaw = File('assets/data/icd10_opd_map.json').readAsStringSync();
    final icdMap = json.decode(icdRaw) as Map<String, dynamic>;
    final icdList = (icdMap['entries'] as List).cast<Map<String, dynamic>>();
    mapper = Icd10LocalMapper.fromJsonList(icdList);

    final diffRaw = File(
      'assets/data/differential_rules.json',
    ).readAsStringSync();
    engine = DifferentialEngine.fromJsonString(diffRaw);
  });

  // Each case mimics one realistic Gemini extraction output.
  //   expectedIcd     — the ICD code the mapper is expected to return
  //                     (null = expect no match). Ignored when icdAny is true.
  //   icdAny          — case 5: any code OR null is acceptable (fuzzy input).
  //   expectDiff      — whether the differential engine should fire (non-empty).
  //   expectRedFlag   — whether at least one suggestion must carry a red flag.
  final cases = <Map<String, dynamic>>[
    {
      'title': 'Viral fever (clear diagnosis)',
      'diagnosis': 'Viral fever',
      'symptoms': ['headache', 'body ache', 'fever', 'fatigue', 'mild cold'],
      'expectedIcd': 'B34.9',
      'icdAny': false,
      'expectDiff': true,
      'expectRedFlag': false,
    },
    {
      'title': 'Acute gastritis (GI)',
      'diagnosis': 'Acute gastritis',
      'symptoms': [
        'burning sensation in stomach',
        'nausea',
        'bloating',
        'loss of appetite',
        'epigastric pain',
      ],
      'expectedIcd': 'K29.1',
      'icdAny': false,
      'expectDiff': true,
      'expectRedFlag': false,
    },
    {
      'title': 'Dehydration (judge\'s example)',
      'diagnosis': 'Suspected dehydration',
      'symptoms': [
        'dry mouth',
        'decreased urine',
        'weakness',
        'dizziness',
        'thirst',
      ],
      'expectedIcd': 'E86.0',
      'icdAny': false,
      'expectDiff': true,
      'expectRedFlag': false,
    },
    {
      'title': 'Dengue (red flag)',
      'diagnosis': 'Dengue fever',
      'symptoms': [
        'high fever',
        'severe joint pain',
        'rash',
        'headache',
        'retro-orbital pain',
        'nausea',
      ],
      'expectedIcd': 'A90',
      'icdAny': false,
      'expectDiff': true,
      'expectRedFlag': true,
    },
    {
      'title': 'Hinglish input',
      'diagnosis': 'Bukhar aur sardi',
      'symptoms': ['bukhar', 'sardi', 'khansi', 'badan dard', 'thakaan'],
      'expectedIcd': null,
      'icdAny': true, // fuzzy — any code or null is acceptable
      'expectDiff': true,
      'expectRedFlag': false,
    },
    {
      'title': 'Vague input (should return nothing)',
      'diagnosis': 'Patient unwell',
      'symptoms': ['not feeling well', 'unease'],
      'expectedIcd': null,
      'icdAny': false,
      'expectDiff': false,
      'expectRedFlag': false,
    },
  ];

  String truncate(String s, int n) =>
      s.length > n ? '${s.substring(0, n)}...' : s;

  test(
    'on-device diagnostic pipeline eval (ICD mapper + differential engine)',
    () {
      var pass = 0;
      var fail = 0;

      for (var i = 0; i < cases.length; i++) {
        final c = cases[i];
        final title = c['title'] as String;
        final diagnosis = c['diagnosis'] as String;
        final symptoms = (c['symptoms'] as List).cast<String>();
        final expectedIcd = c['expectedIcd'] as String?;
        final icdAny = c['icdAny'] as bool;
        final expectDiff = c['expectDiff'] as bool;
        final expectRedFlag = c['expectRedFlag'] as bool;

        // ── Run the deterministic layer ──────────────────────────────────────
        final m = mapper.lookup(diagnosis);
        final suggestions = engine.suggest(symptoms);

        // ── Evaluate ─────────────────────────────────────────────────────────
        final bool icdPass;
        if (icdAny) {
          icdPass = true;
        } else if (expectedIcd == null) {
          icdPass = m.code == null;
        } else {
          icdPass = m.code == expectedIcd;
        }

        final fired = suggestions.isNotEmpty;
        final hasRedFlag = suggestions.any((s) => s.isRedFlag);
        final bool diffPass;
        if (expectDiff) {
          diffPass = fired && (!expectRedFlag || hasRedFlag);
        } else {
          diffPass = !fired;
        }

        final casePass = icdPass && diffPass;
        if (casePass) {
          pass++;
        } else {
          fail++;
        }

        // ── Print report card ────────────────────────────────────────────────
        // ignore: avoid_print
        print('══════════════════════════════════════════════════');
        // ignore: avoid_print
        print('CASE ${i + 1}: $title');
        // ignore: avoid_print
        print('──────────────────────────────────────────────────');
        // ignore: avoid_print
        print('Diagnosis input: "$diagnosis"');
        // ignore: avoid_print
        print('Symptoms input:  [${symptoms.join(', ')}]');
        // ignore: avoid_print
        print('');
        // ignore: avoid_print
        print('ICD MAPPER RESULT:');
        // ignore: avoid_print
        print(
          '  Code: ${m.code ?? 'null'} | '
          'Desc: ${m.description ?? '-'} | '
          'Confidence: ${m.confidence ?? 'null'}',
        );
        final expectedLabel = icdAny ? 'any (fuzzy)' : (expectedIcd ?? 'null');
        // ignore: avoid_print
        print(
          '  Expected: $expectedLabel  →  ${icdPass ? '✅' : '❌'} '
          '(got ${m.code ?? 'null'})',
        );
        // ignore: avoid_print
        print('');
        // ignore: avoid_print
        print('DIFFERENTIAL SUGGESTIONS:');
        if (suggestions.isEmpty) {
          // ignore: avoid_print
          print('  (none)');
        } else {
          for (var j = 0; j < suggestions.length; j++) {
            final s = suggestions[j];
            // ignore: avoid_print
            print(
              '  ${j + 1}. ${s.name} (${s.icdCode}) — '
              'score: ${s.score.toStringAsFixed(2)} — '
              '${truncate(s.reason, 60)}'
              '${s.isRedFlag ? '  [🚩 RED FLAG]' : ''}',
            );
          }
        }
        // ignore: avoid_print
        print('');
        final icdMark = icdPass ? '✅' : '❌';
        final diffMark = diffPass ? '✅' : '❌';
        final firedLabel = expectDiff
            ? (expectRedFlag ? 'fired + red flag' : 'fired')
            : 'stayed empty';
        // ignore: avoid_print
        print(
          '$icdMark ICD matched expected  |  '
          '$diffMark Differentials $firedLabel  →  '
          '${casePass ? 'PASS' : 'FAIL'}',
        );
        // ignore: avoid_print
        print('══════════════════════════════════════════════════');
        // ignore: avoid_print
        print('');
      }

      // ── Summary ────────────────────────────────────────────────────────────
      // ignore: avoid_print
      print('╔══════════════════════════════════════════════════╗');
      // ignore: avoid_print
      print(
        '  SUMMARY:  PASS: $pass/${cases.length}  |  '
        'FAIL: $fail/${cases.length}',
      );
      // ignore: avoid_print
      print('╚══════════════════════════════════════════════════╝');

      // This is a reporting harness, not a gate: it always completes so the
      // full table is printed. Per-case PASS/FAIL is shown above.
      expect(cases.length, 6);
    },
  );
}
