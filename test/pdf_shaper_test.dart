import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:rxvarta/features/prescription/data/pdf_shaper.dart';

/// The pdf package draws Indian-script text one character at a time in
/// typing order, which misspells it (a vowel sign typed after its consonant
/// must be drawn before it, clusters must join). PdfShaper routes such text
/// through Flutter's shaping text engine instead.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // `flutter test` renders with a placeholder test font. Load the bundled
  // Noto fonts under the family names pubspec.yaml gives them, as the app
  // does, so these checks see real glyphs and real shaping.
  setUpAll(_loadBundledFonts);

  final style = pw.TextStyle(fontSize: 10);

  group('needsShaping', () {
    test('every Indian script the app supports needs shaping', () {
      for (final text in [
        'निदान', // Hindi / Marathi
        'রোগনির্ণয়', // Bengali
        'નિદાન', // Gujarati
        'ರೋಗನಿರ್ಣಯ', // Kannada
        'நோயாளி', // Tamil
        'నిర్ధారణ', // Telugu
        'Diagnosis: निदान', // mixed
      ]) {
        expect(PdfShaper.needsShaping(text), isTrue, reason: text);
      }
    });

    test('Latin, digits and symbols do not', () {
      for (final text in [
        'Paracetamol 650 mg',
        '18/09/2026',
        '℞',
        '•  CBC',
        '',
      ]) {
        expect(PdfShaper.needsShaping(text), isFalse, reason: text);
      }
    });
  });

  test('pubspec bundles every font family the shaper asks for', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final family in [PdfShaper.family, ...PdfShaper.fallback]) {
      expect(
        RegExp(
          '^\\s+- family: $family\\s*\$',
          multiLine: true,
        ).hasMatch(pubspec),
        isTrue,
        reason: family,
      );
    }
  });

  test('Latin text stays real PDF text', () {
    final w = PdfShaper().text('Viral fever', style);
    expect(w, isA<pw.Text>());
  });

  test('Latin label and value stay one rich-text line', () {
    final w = PdfShaper().runs([
      PdfRun('Diagnosis: ', style),
      PdfRun('Viral fever', style),
    ]);
    expect(w, isA<pw.RichText>());
  });

  test('Indian-script text becomes a visible shaped image', () async {
    PdfShaper.clearCache();
    final shaper = PdfShaper();
    const text = 'நோயாளி';
    expect(
      shaper.text(text, style),
      isNot(isA<pw.Image>()),
      reason: 'placeholder before shaping',
    );

    await shaper.shapePending();
    final shaped = shaper.text(text, style);
    expect(shaped, isA<pw.Image>());
    expect(await _hasInk(shaped), isTrue, reason: 'the image is not blank');
  });

  test('consonant clusters are joined, not drawn letter by letter', () async {
    final shaper = PdfShaper();
    shaper.text('क्ष', style);
    shaper.text('कष', style);
    await shaper.shapePending();
    // Shaped, क + ् + ष is one conjunct glyph, narrower than क and ष side by
    // side. Drawn letter by letter it would be the wider of the two.
    final joined = shaper.text('क्ष', style) as pw.Image;
    final apart = shaper.text('कष', style) as pw.Image;
    expect(joined.width!, lessThan(apart.width!));
  });

  test(
    'a line mixing a Latin label and a Hindi value is shaped as one',
    () async {
      final shaper = PdfShaper();
      List<PdfRun> line() => [
        PdfRun('Diagnosis: ', style),
        PdfRun('वायरल बुखार', style),
      ];
      shaper.runs(line(), maxWidth: 500);
      await shaper.shapePending();
      expect(shaper.runs(line(), maxWidth: 500), isA<pw.Image>());
    },
  );

  test('a shaped line is reused by the next prescription', () async {
    final a = PdfShaper();
    a.text('सलाह', style);
    await a.shapePending();

    // A new document's shaper finds it without shaping again.
    final b = PdfShaper();
    expect(b.text('सलाह', style), isA<pw.Image>());
  });

  test('each document gets its own image of a shared line', () async {
    final a = PdfShaper();
    a.text('जाँच', style);
    await a.shapePending();
    final b = PdfShaper();

    final inA = (a.text('जाँच', style) as pw.Image).image;
    // A pdf image remembers the document it was drawn into, so sharing one
    // across documents would keep old prescriptions in memory.
    expect(identical(inA, (b.text('जाँच', style) as pw.Image).image), isFalse);
    // Within one document a repeated line (the footer) is embedded once.
    expect(identical(inA, (a.text('जाँच', style) as pw.Image).image), isTrue);
  });

  group('language', () {
    // ल and श are drawn differently for Marathi than for Hindi: the Noto
    // font swaps them through OpenType `locl`, which applies only when the
    // text engine is told the language.
    const text = 'ल श';

    Future<List<int>> pixelsIn(String? lang) async {
      PdfShaper.clearCache();
      final s = PdfShaper(locale: lang == null ? null : ui.Locale(lang));
      s.text(text, style);
      await s.shapePending();
      return _rgba(s.text(text, style));
    }

    test('shaping is deterministic, so a difference means something', () async {
      expect(await pixelsIn('hi'), equals(await pixelsIn('hi')));
    });

    test('Marathi text gets Marathi letterforms, not Hindi ones', () async {
      expect(await pixelsIn('mr'), isNot(equals(await pixelsIn('hi'))));
    });

    test('a line shaped for one language is not reused for another', () async {
      PdfShaper.clearCache();
      final hindi = PdfShaper(locale: const ui.Locale('hi'));
      hindi.text(text, style);
      await hindi.shapePending();

      // Same text, same style, other language: must be shaped afresh, not
      // served the Hindi image from the shared cache.
      final marathi = PdfShaper(locale: const ui.Locale('mr'));
      expect(marathi.text(text, style), isNot(isA<pw.Image>()));
    });
  });

  test('a line the document already uses survives cache eviction', () async {
    PdfShaper.clearCache();
    PdfShaper.maxCached = 2;
    addTearDown(() {
      PdfShaper.maxCached = 500;
      PdfShaper.clearCache();
    });

    final earlier = PdfShaper();
    earlier.text('पुराना एक', style);
    earlier.text('पुराना दो', style);
    await earlier.shapePending();

    // First pass: one cached line, two new ones. Shaping the new ones
    // evicts both old lines from the full cache.
    final doc = PdfShaper();
    doc.text('पुराना एक', style);
    doc.text('नया एक', style);
    doc.text('नया दो', style);
    await doc.shapePending();

    // Second pass still prints all three.
    expect(doc.text('पुराना एक', style), isA<pw.Image>());
    expect(doc.text('नया एक', style), isA<pw.Image>());
    expect(doc.text('नया दो', style), isA<pw.Image>());
  });
}

Future<void> _loadBundledFonts() async {
  final family = RegExp(r'^\s+- family: (\S+)');
  final asset = RegExp(r'^\s+- asset: (\S+)');
  FontLoader? loader;
  for (final line in File('pubspec.yaml').readAsLinesSync()) {
    final f = family.firstMatch(line);
    if (f != null) {
      await loader?.load();
      loader = FontLoader(f.group(1)!);
      continue;
    }
    final a = asset.firstMatch(line);
    if (a != null) loader?.addFont(rootBundle.load(a.group(1)!));
  }
  await loader?.load();
}

/// Whether a shaped line's PNG has any non-transparent pixel.
Future<bool> _hasInk(pw.Widget shaped) async {
  final bytes = await _rgba(shaped);
  for (var i = 3; i < bytes.length; i += 4) {
    if (bytes[i] > 0) return true;
  }
  return false;
}

/// A shaped line's decoded pixels (RGBA), for comparing what was drawn
/// rather than how the PNG happened to be encoded.
Future<List<int>> _rgba(pw.Widget shaped) async {
  final png = ((shaped as pw.Image).image as pw.MemoryImage).bytes;
  final codec = await ui.instantiateImageCodec(png);
  final frame = await codec.getNextFrame();
  final rgba = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
  frame.image.dispose();
  codec.dispose();
  return rgba!.buffer.asUint8List();
}
