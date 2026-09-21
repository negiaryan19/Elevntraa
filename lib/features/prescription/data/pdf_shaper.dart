import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/painting.dart';
import 'package:pdf/widgets.dart' as pw;

/// One styled piece of a line, e.g. a bold "Diagnosis:" and a regular value.
class PdfRun {
  const PdfRun(this.text, this.style);
  final String text;
  final pw.TextStyle style;
}

/// Puts text in Indian scripts on the prescription PDF correctly spelled.
///
/// Hindi, Marathi, Bengali, Gujarati, Tamil, Telugu and Kannada need
/// shaping: a vowel sign typed after its consonant is drawn before it
/// (कि, தே), two-part vowels wrap around the consonant (தொ), and consonant
/// clusters join (क्ष, ప్ర). The pdf package draws one glyph per character in
/// typing order, so these words printed misspelled. Lines that contain such
/// text are laid out by Flutter's text engine, which shapes them the same
/// way it does on screen, and are embedded as sharp images. Latin-only lines
/// stay ordinary PDF text.
///
/// Layout code runs twice with one shaper: the first pass records every
/// line that needs shaping (and gets empty placeholders), [shapePending]
/// renders them, and the second pass receives the images.
class PdfShaper {
  /// [locale] is the prescription's language. It decides letterforms that
  /// the same script draws differently per language: Marathi and Hindi share
  /// Devanagari, but the Noto font gives Marathi its own ल and श through
  /// OpenType `locl`, which the text engine only applies when it knows the
  /// text is Marathi. Without it a Marathi prescription printed Hindi shapes
  /// while the review screen, which knows its locale, showed Marathi ones.
  PdfShaper({this.locale});

  final ui.Locale? locale;

  /// Devanagari (U+0900) through Malayalam (U+0D7F): every Indian script.
  static final _complexScript = RegExp(r'[\u0900-\u0D7F]');

  static bool needsShaping(String text) => _complexScript.hasMatch(text);

  /// Pixels per PDF point: 4 × 72 = 288 dpi, sharp in print.
  static const _scale = 4.0;

  /// Font families registered in pubspec.yaml from the bundled Noto fonts.
  @visibleForTesting
  static const family = 'RxNotoSans';
  @visibleForTesting
  static const fallback = [
    'RxNotoSansDevanagari',
    'RxNotoSansBengali',
    'RxNotoSansGujarati',
    'RxNotoSansKannada',
    'RxNotoSansTamil',
    'RxNotoSansTelugu',
  ];

  /// Shaped lines kept across prescriptions: the labels repeat on every one.
  /// Least recently used first. Holds only PNG bytes: a pdf ImageProvider
  /// keeps the whole document it last drew into alive, so providers live on
  /// the shaper, which lives for one document.
  static final _cache = <String, _Shaped>{};
  @visibleForTesting
  static int maxCached = 500;

  @visibleForTesting
  static void clearCache() => _cache.clear();

  /// The shared cache's keys, which carry each shaped line's text: lets a
  /// test check that a given label really went through the shaper.
  @visibleForTesting
  static Iterable<String> get cachedKeys => _cache.keys;

  final _pending = <String, _Request>{};

  /// Every shaped line this document uses. The shared cache may evict one
  /// between the two passes (so may another document built at the same
  /// time), and the second pass must still find it.
  final _used = <String, _Shaped>{};

  /// One image per line in this document: a line repeated on every page,
  /// like the footer, is embedded once.
  final _images = <String, pw.ImageProvider>{};

  /// [text] in [style]. Wraps within [maxWidth] points when given.
  pw.Widget text(
    String text,
    pw.TextStyle style, {
    double? maxWidth,
    pw.TextAlign align = pw.TextAlign.left,
  }) => runs([PdfRun(text, style)], maxWidth: maxWidth, align: align);

  /// Several differently styled pieces laid out as one line (or paragraph,
  /// when [maxWidth] is given).
  pw.Widget runs(
    List<PdfRun> runs, {
    double? maxWidth,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    if (!needsShaping(runs.map((r) => r.text).join())) {
      if (runs.length == 1) {
        return pw.Text(
          runs.single.text,
          style: runs.single.style,
          textAlign: align,
        );
      }
      return pw.RichText(
        textAlign: align,
        text: pw.TextSpan(
          children: [
            for (final r in runs) pw.TextSpan(text: r.text, style: r.style),
          ],
        ),
      );
    }
    // The cache is shared across documents, so the language is part of the
    // key: a Hindi prescription must never reuse a Marathi-shaped line.
    final key = '${locale?.toLanguageTag()}|${_key(runs, maxWidth, align)}';
    final shaped = _used[key] ?? _touch(key);
    if (shaped == null) {
      _pending[key] = _Request(runs, maxWidth, align, locale);
      return pw.SizedBox();
    }
    _used[key] = shaped;
    return pw.Image(
      _images.putIfAbsent(key, () => pw.MemoryImage(shaped.png)),
      width: shaped.width,
      height: shaped.height,
    );
  }

  /// Renders every line the first pass recorded.
  Future<void> shapePending() async {
    final requests = Map.of(_pending);
    _pending.clear();
    for (final entry in requests.entries) {
      final shaped = _used[entry.key] = await _render(entry.value);
      _cache.remove(entry.key);
      while (_cache.isNotEmpty && _cache.length >= maxCached) {
        _cache.remove(_cache.keys.first);
      }
      _cache[entry.key] = shaped;
    }
  }

  /// The cached line for [key], moved to the most recently used end.
  static _Shaped? _touch(String key) {
    final shaped = _cache.remove(key);
    if (shaped != null) _cache[key] = shaped;
    return shaped;
  }

  static String _key(List<PdfRun> runs, double? maxWidth, pw.TextAlign align) {
    final b = StringBuffer('${maxWidth?.toStringAsFixed(1)}|${align.index}');
    for (final r in runs) {
      final s = r.style;
      b
        ..write('|')
        ..write(s.fontSize)
        ..write(',')
        ..write(s.fontWeight?.index)
        ..write(',')
        ..write(s.color?.toInt())
        ..write(',')
        ..write(r.text);
    }
    return b.toString();
  }

  static Future<_Shaped> _render(_Request r) async {
    final painter = TextPainter(
      text: TextSpan(
        children: [
          for (final run in r.runs)
            TextSpan(text: run.text, style: _flutterStyle(run.style)),
        ],
      ),
      textDirection: TextDirection.ltr,
      // Becomes the paragraph's locale, which the spans inherit; that is
      // what makes the shaper apply the language's `locl` letterforms.
      locale: r.locale,
      textAlign: switch (r.align) {
        pw.TextAlign.center => TextAlign.center,
        pw.TextAlign.right => TextAlign.right,
        _ => TextAlign.left,
      },
      textScaler: TextScaler.noScaling,
    )..layout(maxWidth: r.maxWidth ?? double.infinity);
    try {
      final width = painter.width;
      final height = painter.height;
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder)..scale(_scale);
      painter.paint(canvas, Offset.zero);
      final image = await recorder.endRecording().toImage(
        (width * _scale).ceil().clamp(1, 1 << 14),
        (height * _scale).ceil().clamp(1, 1 << 14),
      );
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return _Shaped(png!.buffer.asUint8List(), width, height);
    } finally {
      painter.dispose();
    }
  }

  static TextStyle _flutterStyle(pw.TextStyle s) {
    final color = s.color;
    return TextStyle(
      fontFamily: family,
      fontFamilyFallback: fallback,
      fontSize: s.fontSize ?? 10,
      fontWeight: s.fontWeight == pw.FontWeight.bold
          ? FontWeight.w700
          : FontWeight.w400,
      color: color == null ? const Color(0xFF000000) : Color(color.toInt()),
    );
  }
}

class _Request {
  const _Request(this.runs, this.maxWidth, this.align, this.locale);
  final List<PdfRun> runs;
  final double? maxWidth;
  final pw.TextAlign align;
  final ui.Locale? locale;
}

class _Shaped {
  const _Shaped(this.png, this.width, this.height);
  final Uint8List png;
  final double width;
  final double height;
}
