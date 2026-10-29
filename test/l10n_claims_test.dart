import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The Home screen footer told doctors, in seven of the app's eight
/// languages, that Rxvarta is "HIPAA compliant" and "end-to-end encrypted".
/// Neither is true: nobody has certified the app against HIPAA (a US law),
/// and the recording is read by the speech-to-text and extraction services, so
/// it is encrypted in transit, not end to end. The English text had been
/// corrected; the translations had not.
///
/// A claim like that must never come back in any language, in any string.
void main() {
  // "End-to-end" as each language's ARB transliterates it.
  const endToEnd = [
    'end-to-end',
    'end to end',
    'एंड-टू-एंड',
    'এন্ড-টু-এন্ড',
    'એન્ડ-ટુ-એન્ડ',
    'ಎಂಡ್-ಟು-ಎಂಡ್',
    'எண்ட்-டு-எண்ட்',
    'ఎండ్-టు-ఎండ్',
  ];

  final arbs = Directory(
    'lib/l10n',
  ).listSync().whereType<File>().where((f) => f.path.endsWith('.arb')).toList();

  test('all eight languages are checked', () => expect(arbs, hasLength(8)));

  for (final file in arbs) {
    final name = file.uri.pathSegments.last;
    test(
      '$name makes no compliance or encryption claim the app cannot back',
      () {
        final strings = (json.decode(file.readAsStringSync()) as Map).entries
            .where((e) => !'${e.key}'.startsWith('@') && e.value is String);
        for (final e in strings) {
          final text = '${e.value}'.toLowerCase();
          expect(text, isNot(contains('hipaa')), reason: '$name: ${e.key}');
          for (final phrase in endToEnd) {
            expect(
              text,
              isNot(contains(phrase.toLowerCase())),
              reason: '$name: ${e.key} claims end-to-end encryption',
            );
          }
        }
      },
    );
  }
}
