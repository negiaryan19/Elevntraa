import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxvarta/services/icd10_local_mapper.dart';

void main() {
  late Icd10LocalMapper mapper;

  setUpAll(() {
    // Load the JSON directly from disk for the test (no rootBundle).
    final raw = File('assets/data/icd10_opd_map.json').readAsStringSync();
    final map = json.decode(raw) as Map<String, dynamic>;
    final list = (map['entries'] as List).cast<Map<String, dynamic>>();
    mapper = Icd10LocalMapper.fromJsonList(list);
  });

  group('confident matches', () {
    final cases = <String, String>{
      'Viral fever': 'B34.9',
      'suspected dehydration': 'E86.0',
      'Type 2 diabetes mellitus': 'E11.9',
      'sugar': 'E11.9',
      'kamar dard': 'M54.5',
      'acidity': 'K21.9',
      'high bp': 'I10',
      'loose motion': 'A09',
      'daad': 'B35.9',
      'peshab me jalan': 'N39.0',
      'sar dard': 'R51',
      'aankh aana': 'H10.9',
      'pcod': 'E28.2',
    };
    cases.forEach((input, expected) {
      test('"$input" -> $expected', () {
        final m = mapper.lookup(input);
        expect(m.code, expected);
        expect(m.confidence, isNotNull);
      });
    });
  });

  group('typo tolerance', () {
    test('"diabetis" resolves to E11.9', () {
      expect(mapper.lookup('diabetis').code, 'E11.9');
    });
    test('"dengu" resolves to A90', () {
      expect(mapper.lookup('dengu').code, 'A90');
    });
  });

  group('safe null fallback (never guess)', () {
    for (final vague in const [
      'kuch theek nahi lag raha',
      'not feeling well',
      'asymptomatic follow up',
      '',
    ]) {
      test('"$vague" -> no match', () {
        final m = mapper.lookup(vague);
        expect(m.hasMatch, isFalse);
        expect(m.code, isNull);
      });
    }
  });
}
