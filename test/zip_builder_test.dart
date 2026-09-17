import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:rxvarta/features/settings/data/zip_builder.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('zip_builder_test_');
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  group('writeZip / extractZip round trip', () {
    test('files and bytes come back byte-for-byte with nested names', () async {
      final source = File(p.join(tmp.path, 'src', 'report.bin'));
      await source.parent.create(recursive: true);
      final binary = Uint8List.fromList(List.generate(5000, (i) => i % 251));
      await source.writeAsBytes(binary);

      final zip = await writeZip(File(p.join(tmp.path, 'out', 'b.zip')), [
        ZipInput.file('attachments/report.bin', source),
        ZipInput.bytes('rxvarta.sqlite', Uint8List.fromList([1, 2, 3])),
        ZipInput.text('manifest.json', '{"version":1}'),
        ZipInput.bytes('profile\\signature.png', Uint8List(0)),
      ]);
      expect(await zip.exists(), isTrue);
      expect(await zip.length(), greaterThan(0));

      expect(
        await listZipEntries(zip),
        unorderedEquals([
          'attachments/report.bin',
          'rxvarta.sqlite',
          'manifest.json',
          'profile/signature.png',
        ]),
      );

      final out = Directory(p.join(tmp.path, 'extracted'));
      final written = await extractZip(zip, out);
      expect(written.length, 4);

      expect(
        await File(p.join(out.path, 'attachments', 'report.bin')).readAsBytes(),
        binary,
      );
      expect(await File(p.join(out.path, 'rxvarta.sqlite')).readAsBytes(), [
        1,
        2,
        3,
      ]);
      expect(
        await File(p.join(out.path, 'manifest.json')).readAsString(),
        '{"version":1}',
      );
      expect(
        await File(p.join(out.path, 'profile', 'signature.png')).length(),
        0,
      );
    });

    test('readZipEntry returns one entry or null', () async {
      final zip = await writeZip(File(p.join(tmp.path, 'r.zip')), [
        ZipInput.text('manifest.json', '{"version":1,"uid":"u1"}'),
        ZipInput.text('other.txt', 'x'),
      ]);
      final manifest = await readZipEntry(zip, 'manifest.json');
      expect(manifest, isNotNull);
      expect(jsonDecode(utf8.decode(manifest!)), {'version': 1, 'uid': 'u1'});
      expect(await readZipEntry(zip, 'missing.txt'), isNull);
    });

    test('filter limits what is extracted', () async {
      final zip = await writeZip(File(p.join(tmp.path, 'f.zip')), [
        ZipInput.text('keep/a.txt', 'a'),
        ZipInput.text('skip/b.txt', 'b'),
      ]);
      final out = Directory(p.join(tmp.path, 'filtered'));
      final written = await extractZip(
        zip,
        out,
        filter: (name) => name.startsWith('keep/'),
      );
      expect(written, ['keep/a.txt']);
      expect(await File(p.join(out.path, 'keep', 'a.txt')).exists(), isTrue);
      expect(await File(p.join(out.path, 'skip', 'b.txt')).exists(), isFalse);
    });

    test('overwrites an existing target file', () async {
      final target = File(p.join(tmp.path, 'same.zip'));
      await target.writeAsString('garbage that is not a zip');
      final zip = await writeZip(target, [ZipInput.text('a.txt', 'hello')]);
      expect(await readZipEntry(zip, 'a.txt'), utf8.encode('hello'));
    });
  });

  group('path traversal', () {
    Future<File> craftedZip(String entryName) async {
      final archive = Archive()
        ..add(ArchiveFile.bytes('ok.txt', utf8.encode('fine')))
        ..add(ArchiveFile.bytes(entryName, utf8.encode('evil')));
      final file = File(p.join(tmp.path, 'crafted.zip'));
      await file.writeAsBytes(ZipEncoder().encodeBytes(archive));
      return file;
    }

    test('refuses ".." segments and writes nothing', () async {
      final zip = await craftedZip('../escaped.txt');
      final out = Directory(p.join(tmp.path, 'sandbox'));
      await expectLater(
        extractZip(zip, out),
        throwsA(isA<UnsafeZipEntryException>()),
      );
      expect(await File(p.join(tmp.path, 'escaped.txt')).exists(), isFalse);
      // Validation happens before any write, so even the safe entry is
      // absent.
      expect(await File(p.join(out.path, 'ok.txt')).exists(), isFalse);
    });

    test('refuses nested ".." and backslash variants', () async {
      for (final name in ['a/../../b.txt', r'..\..\c.txt', 'x/./../../d']) {
        final zip = await craftedZip(name);
        await expectLater(
          extractZip(zip, Directory(p.join(tmp.path, 'sb2'))),
          throwsA(isA<UnsafeZipEntryException>()),
          reason: name,
        );
      }
    });

    test('refuses absolute names', () async {
      for (final name in ['/tmp/abs.txt', r'C:\abs.txt', r'\abs.txt']) {
        final zip = await craftedZip(name);
        await expectLater(
          extractZip(zip, Directory(p.join(tmp.path, 'sb3'))),
          throwsA(isA<UnsafeZipEntryException>()),
          reason: name,
        );
      }
    });

    test('isSafeZipEntryName', () {
      expect(isSafeZipEntryName('a/b/c.txt'), isTrue);
      expect(isSafeZipEntryName('./a.txt'), isTrue);
      expect(isSafeZipEntryName('a..b/c.txt'), isTrue);
      expect(isSafeZipEntryName(''), isFalse);
      expect(isSafeZipEntryName('../a'), isFalse);
      expect(isSafeZipEntryName('a/../../b'), isFalse);
      expect(isSafeZipEntryName('/a'), isFalse);
      expect(isSafeZipEntryName('D:/a'), isFalse);
      expect(isSafeZipEntryName('a\u0000b'), isFalse);
    });
  });
}
