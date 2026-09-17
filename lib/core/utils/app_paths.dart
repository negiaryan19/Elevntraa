import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Resolves on-device file locations. The documents directory is cached once
/// at startup so the rest of the app can build absolute paths synchronously
/// (image widgets and the PDF builder need a path immediately).
///
/// Every doctor's data lives under `users/<uid>/` (roadmap item 6): their
/// database, scanned reports, recordings, profile and signature. Doctor A
/// signed in on a phone never reads a file that belongs to Doctor B.
///
/// Attachments are stored as *relative* file names (e.g. `<uuid>.jpg`) so a
/// reinstall or OS container-path change can't orphan them — they are
/// resolved against the doctor's attachments folder at read time.
class AppPaths {
  AppPaths._();

  static String? _documentsDir;

  static const databaseFileName = 'rxvarta.sqlite';

  /// The database's write-ahead log, shared-memory and rollback files, which
  /// must always move and be deleted together with it.
  static const databaseSidecars = ['', '-wal', '-shm', '-journal'];

  /// Must be called once during app startup, before any file is read.
  /// [documentsDir] replaces the platform documents directory.
  static Future<void> init({String? documentsDir}) async {
    _documentsDir =
        documentsDir ?? (await getApplicationDocumentsDirectory()).path;
  }

  static String get documentsDir {
    final dir = _documentsDir;
    if (dir == null) {
      throw StateError('AppPaths.init() must be called before use.');
    }
    return dir;
  }

  /// Root of one doctor's private data on this device. Created on demand.
  static String userDir(String uid) {
    final dir = p.join(documentsDir, 'users', uid);
    final d = Directory(dir);
    if (!d.existsSync()) d.createSync(recursive: true);
    return dir;
  }

  /// The doctor's patients, consultations and prescriptions.
  static String databasePath(String uid) =>
      p.join(userDir(uid), databaseFileName);

  /// Scanned report images the doctor attached to consultations.
  static String attachmentsDir(String uid) =>
      p.join(userDir(uid), 'attachments');

  /// Consultation audio recorded on this device.
  static String recordingsDir(String uid) => p.join(userDir(uid), 'recordings');

  /// Turns a stored attachment reference into an absolute path inside
  /// [attachmentsDir]. Older builds stored absolute paths into the shared
  /// folder that has since moved into the doctor's own folder; those resolve
  /// by file name when the old path no longer exists.
  static String resolveAttachment(
    String stored, {
    required String attachmentsDir,
  }) {
    if (!p.isAbsolute(stored)) return p.join(attachmentsDir, stored);
    if (File(stored).existsSync()) return stored;
    return p.join(attachmentsDir, p.basename(stored));
  }

  /// Builds before per-doctor storage kept one database, one attachments
  /// folder and one recordings folder for the whole phone, under a shared
  /// login that belonged to no account. The first doctor to sign in
  /// afterwards takes them over, so an upgrade loses nothing; every other
  /// doctor starts with an empty database.
  static Future<void> claimSharedData(String uid) async {
    final docs = documentsDir;
    final target = File(databasePath(uid));
    if (await target.exists()) return;

    // `medscribe.sqlite` is the database from before the Rxvarta rename.
    for (final name in const [databaseFileName, 'medscribe.sqlite']) {
      final shared = File(p.join(docs, name));
      if (!await shared.exists()) continue;
      for (final suffix in databaseSidecars) {
        final file = File('${shared.path}$suffix');
        if (await file.exists()) await file.rename('${target.path}$suffix');
      }
      await _moveDir(
        Directory(p.join(docs, 'attachments')),
        Directory(attachmentsDir(uid)),
      );
      await _moveDir(
        Directory(p.join(docs, 'recordings')),
        Directory(recordingsDir(uid)),
      );
      return;
    }
  }

  static Future<void> _moveDir(Directory from, Directory to) async {
    if (!await from.exists()) return;
    if (!await to.exists()) {
      await from.rename(to.path);
      return;
    }
    await for (final entity in from.list(followLinks: false)) {
      await entity.rename(p.join(to.path, p.basename(entity.path)));
    }
    await from.delete(recursive: true);
  }
}
