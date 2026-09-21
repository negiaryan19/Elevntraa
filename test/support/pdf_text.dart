import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// A PDF's objects as searchable text: the raw file plus every
/// Flate-compressed stream inflated (the pdf package packs dictionaries,
/// such as image objects, into compressed object streams).
String pdfText(Uint8List bytes) {
  final out = StringBuffer(latin1.decode(bytes, allowInvalid: true));
  final raw = latin1.decode(bytes, allowInvalid: true);
  var from = 0;
  while (true) {
    final start = raw.indexOf('stream', from);
    if (start < 0) break;
    var dataStart = start + 'stream'.length;
    if (raw.startsWith('\r\n', dataStart)) {
      dataStart += 2;
    } else if (raw.startsWith('\n', dataStart)) {
      dataStart += 1;
    }
    final end = raw.indexOf('endstream', dataStart);
    if (end < 0) break;
    try {
      final inflated = ZLibDecoder().convert(bytes.sublist(dataStart, end));
      out.write(latin1.decode(inflated, allowInvalid: true));
    } catch (_) {
      // Not a Flate stream (or an image's pixel data): skip it.
    }
    from = end + 'endstream'.length;
  }
  return out.toString();
}

/// A ToUnicode entry mapping a glyph to a code point in U+0900-U+0D7F: an
/// Indian-script letter drawn by the pdf package's own (unshaped) text path.
final _indicInToUnicode = RegExp(
  r'<[0-9A-F]{4}> <0(?:[9ABC][0-9A-F]|D[0-7])[0-9A-F]>',
);

bool drawsIndicAsText(String pdf) => _indicInToUnicode.hasMatch(pdf);

/// Shaped lines are PNGs with transparency: each embeds as one image with
/// one soft mask.
int shapedImageCount(String pdf) =>
    RegExp(r'/SMask \d+ 0 R').allMatches(pdf).length;
