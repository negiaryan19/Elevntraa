import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart' show ArchiveException;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/config/app_config.dart';
import '../../../core/errors/failure.dart';
import '../../../core/prefs/shared_preferences_provider.dart';
import '../../../core/utils/app_paths.dart';
import '../../../data/db/database_provider.dart';
import '../../../domain/models/doctor_profile.dart';
import 'doctor_profile_repository.dart';
import 'zip_builder.dart';

/// Stage names reported through `onProgress` by [BackupService.backupNow]
/// and [BackupService.restore]; the sheet maps them to localized text.
abstract final class BackupStage {
  static const collecting = 'collecting';
  static const zipping = 'zipping';
  static const uploading = 'uploading';
  static const downloading = 'downloading';
  static const restoring = 'restoring';
}

/// One backup archive in the doctor's private folder of the `backups`
/// bucket.
class BackupEntry {
  const BackupEntry({
    required this.name,
    required this.createdAt,
    required this.sizeBytes,
    required this.storagePath,
  });

  /// File name, e.g. `rxvarta-backup-20260916-103000.zip`.
  final String name;
  final DateTime createdAt;
  final int sizeBytes;

  /// Object path inside the bucket: `<uid>/<name>`.
  final String storagePath;

  @override
  String toString() => 'BackupEntry($storagePath, $sizeBytes B, $createdAt)';
}

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(ref),
);

/// Cloud backup of everything on this device (roadmap item 24): the SQLite
/// database (patients, visits, prescriptions), attached report images and
/// the doctor's profile + signature, zipped and uploaded to the signed-in
/// doctor's own folder of the private `backups` bucket (RLS: `<uid>/…`).
/// Audio recordings are deliberately excluded (large, and already uploaded
/// for processing). The newest [keepNewest] archives are kept per doctor.
///
/// Every public method throws a [Failure] subtype so the UI never sees raw
/// exceptions: [AuthFailure] (not signed in / session rejected),
/// [NetworkFailure] (no backend, no connectivity), [ApiFailure] (Supabase
/// Storage error) or [StorageFailure] (device disk / damaged archive).
class BackupService {
  BackupService(
    this._ref, {
    SupabaseClient? client,
    Future<Directory> Function()? tempDir,
  }) : _clientOverride = client,
       _tempDirOverride = tempDir;

  static const bucket = 'backups';
  static const keepNewest = 5;
  static const manifestVersion = 1;
  static const manifestName = 'manifest.json';
  static const databaseFileName = AppPaths.databaseFileName;
  static const attachmentsPrefix = 'attachments';
  static const profilePrefix = 'profile';
  static const profileFileName = 'doctor_profile.json';
  static const _namePrefix = 'rxvarta-backup-';

  static String prefsKey(String uid) => 'last_backup_at_$uid';

  final Ref _ref;
  final SupabaseClient? _clientOverride;
  final Future<Directory> Function()? _tempDirOverride;

  SupabaseClient get _client => _clientOverride ?? Supabase.instance.client;
  StorageFileApi get _storage => _client.storage.from(bucket);

  Future<Directory> _tempDir() =>
      _tempDirOverride?.call() ?? getTemporaryDirectory();

  // ── Public API ────────────────────────────────────────────────────────

  /// When this device last completed a backup for the signed-in doctor, or
  /// null (never, or signed out).
  Future<DateTime?> lastBackupAt() async {
    final uid = _ref.read(currentUserIdProvider);
    if (uid == null) return null;
    try {
      final prefs = await _prefs();
      final raw = prefs.getString(prefsKey(uid));
      if (raw == null) return null;
      return DateTime.tryParse(raw)?.toLocal();
    } catch (e) {
      debugPrint('[backup] lastBackupAt unreadable: $e');
      return null;
    }
  }

  /// Backups in the doctor's cloud folder, newest first.
  Future<List<BackupEntry>> listRemote() async {
    final uid = _requireUid();
    _requireBackend();
    try {
      final objects = await _storage.list(
        path: uid,
        searchOptions: const SearchOptions(
          limit: 100,
          sortBy: SortBy(column: 'created_at', order: 'desc'),
        ),
      );
      final entries = [
        for (final o in objects)
          if (o.name.toLowerCase().endsWith('.zip')) _toEntry(uid, o),
      ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return entries;
    } on Failure {
      rethrow;
    } catch (e) {
      throw mapBackupError(e, 'Could not list backups');
    }
  }

  /// Collects, zips and uploads a fresh backup, prunes old ones and records
  /// the time. [onProgress] receives a [BackupStage] name as work advances.
  Future<BackupEntry> backupNow({
    void Function(String stage)? onProgress,
  }) async {
    final uid = _requireUid();
    _requireBackend();
    final now = DateTime.now();
    final name = '$_namePrefix${backupTimestamp(now)}.zip';
    File? zip;
    try {
      onProgress?.call(BackupStage.collecting);
      final inputs = await _collect(uid, now);

      onProgress?.call(BackupStage.zipping);
      zip = await writeZip(await _tempFile(name), inputs);
      final bytes = await zip.readAsBytes();

      onProgress?.call(BackupStage.uploading);
      final storagePath = '$uid/$name';
      await _storage.uploadBinary(
        storagePath,
        bytes,
        fileOptions: const FileOptions(contentType: 'application/zip'),
      );
      await _prune(uid);
      await _saveLastBackupAt(uid, now);
      return BackupEntry(
        name: name,
        createdAt: now,
        sizeBytes: bytes.length,
        storagePath: storagePath,
      );
    } on Failure {
      rethrow;
    } catch (e) {
      throw mapBackupError(e, 'Backup failed');
    } finally {
      await _deleteQuietly(zip);
    }
  }

  /// Downloads [entry], validates it and replaces this device's database,
  /// attachments (merged) and profile files with its contents. The database
  /// is closed for the copy and its provider invalidated afterwards — also
  /// on failure — so the app reopens whatever is on disk.
  Future<void> restore(
    BackupEntry entry, {
    void Function(String stage)? onProgress,
  }) async {
    final uid = _requireUid();
    _requireBackend();
    if (!entry.storagePath.startsWith('$uid/')) {
      throw const StorageFailure(
        'This backup belongs to a different account.',
        code: FailureCode.invalidBackup,
      );
    }
    final stamp = backupTimestamp(DateTime.now());
    File? zip;
    Directory? staging;
    try {
      onProgress?.call(BackupStage.downloading);
      final Uint8List bytes;
      try {
        bytes = await _storage.download(entry.storagePath);
      } on Failure {
        rethrow;
      } catch (e) {
        throw mapBackupError(e, 'Could not download backup');
      }
      zip = await _tempFile('rxvarta-restore-$stamp.zip');
      await zip.writeAsBytes(bytes, flush: true);
      await _validateArchive(zip);

      onProgress?.call(BackupStage.restoring);
      staging = Directory(
        p.join((await _tempDir()).path, 'rxvarta-restore-$stamp'),
      );
      await staging.create(recursive: true);
      await extractZip(zip, staging);
      await _applyExtracted(staging, uid);
    } on Failure {
      rethrow;
    } catch (e) {
      throw mapBackupError(e, 'Restore failed');
    } finally {
      await _deleteQuietly(zip);
      await _deleteQuietly(staging);
    }
  }

  // ── Collect ───────────────────────────────────────────────────────────

  Future<List<ZipInput>> _collect(String uid, DateTime now) async {
    // Fold the write-ahead log into the main file so rxvarta.sqlite alone
    // is a complete, consistent snapshot.
    try {
      await _ref
          .read(appDatabaseProvider)
          .customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
    } catch (e) {
      debugPrint('[backup] wal_checkpoint failed (continuing): $e');
    }

    final inputs = <ZipInput>[];
    try {
      final dbFile = File(AppPaths.databasePath(uid));
      if (!await dbFile.exists()) {
        throw const StorageFailure('Database file not found on this device.');
      }
      inputs.add(ZipInput.file(databaseFileName, dbFile));
      // If the checkpoint could not run, a non-empty WAL still holds
      // committed data; ship it too so the restore replays it.
      final wal = File('${dbFile.path}-wal');
      if (await wal.exists() && await wal.length() > 0) {
        inputs.add(ZipInput.file('$databaseFileName-wal', wal));
      }

      final attachments = Directory(AppPaths.attachmentsDir(uid));
      if (await attachments.exists()) {
        await for (final entity in attachments.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is! File) continue;
          final rel = p
              .relative(entity.path, from: attachments.path)
              .replaceAll(p.separator, '/');
          inputs.add(ZipInput.file('$attachmentsPrefix/$rel', entity));
        }
      }

      final userDir = AppPaths.userDir(uid);
      for (final fileName in [
        profileFileName,
        DoctorProfile.defaultSignatureFileName,
      ]) {
        final f = File(p.join(userDir, fileName));
        if (await f.exists()) {
          inputs.add(ZipInput.file('$profilePrefix/$fileName', f));
        }
      }
    } on FileSystemException catch (e) {
      throw StorageFailure('Could not read app data: ${e.message}', cause: e);
    }

    final manifest = <String, Object?>{
      'version': manifestVersion,
      'createdAt': now.toUtc().toIso8601String(),
      'uid': uid,
      'appVersion': await _appVersion(),
      'files': [for (final i in inputs) i.nameInZip],
    };
    inputs.add(ZipInput.text(manifestName, jsonEncode(manifest)));
    return inputs;
  }

  // ── Restore ───────────────────────────────────────────────────────────

  Future<void> _validateArchive(File zip) async {
    final Uint8List? raw;
    final List<String> names;
    try {
      raw = await readZipEntry(zip, manifestName);
      names = await listZipEntries(zip);
    } on ArchiveException catch (e) {
      throw StorageFailure(
        'The backup file is damaged.',
        cause: e,
        code: FailureCode.invalidBackup,
      );
    }
    if (raw == null) {
      throw const StorageFailure(
        'Not a Rxvarta backup (manifest missing).',
        code: FailureCode.invalidBackup,
      );
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(raw));
    } catch (e) {
      throw StorageFailure(
        'The backup manifest is unreadable.',
        cause: e,
        code: FailureCode.invalidBackup,
      );
    }
    if (decoded is! Map) {
      throw const StorageFailure(
        'The backup manifest is unreadable.',
        code: FailureCode.invalidBackup,
      );
    }
    final version = decoded['version'];
    if (version is! int || version < 1) {
      throw const StorageFailure(
        'The backup manifest is unreadable.',
        code: FailureCode.invalidBackup,
      );
    }
    if (version > manifestVersion) {
      throw const StorageFailure(
        'This backup was made by a newer app version. Update the app first.',
        code: FailureCode.backupFromNewerApp,
      );
    }
    if (!names.contains(databaseFileName)) {
      throw const StorageFailure(
        'The backup contains no database.',
        code: FailureCode.invalidBackup,
      );
    }
  }

  Future<void> _applyExtracted(Directory staging, String uid) async {
    try {
      await _ref.read(appDatabaseProvider).close();
    } catch (e) {
      // Reopen whatever we have; nothing on disk was touched yet.
      _ref.invalidate(appDatabaseProvider);
      throw StorageFailure('Could not close the database: $e', cause: e);
    }
    try {
      final target = File(AppPaths.databasePath(uid));
      for (final suffix in const ['-wal', '-shm', '-journal']) {
        final stale = File('${target.path}$suffix');
        if (await stale.exists()) await stale.delete();
      }
      await File(p.join(staging.path, databaseFileName)).copy(target.path);
      final wal = File(p.join(staging.path, '$databaseFileName-wal'));
      if (await wal.exists()) await wal.copy('${target.path}-wal');

      final srcAttachments = Directory(p.join(staging.path, attachmentsPrefix));
      if (await srcAttachments.exists()) {
        await _copyTree(
          srcAttachments,
          Directory(AppPaths.attachmentsDir(uid)),
        );
      }

      final srcProfile = Directory(p.join(staging.path, profilePrefix));
      if (await srcProfile.exists()) {
        await _copyTree(srcProfile, Directory(AppPaths.userDir(uid)));
      }
    } on FileSystemException catch (e) {
      throw StorageFailure(
        'Could not write restored files: ${e.message}',
        cause: e,
      );
    } finally {
      // Whatever happened, the old handle is closed: hand out a fresh one
      // and re-read the profile from disk.
      _ref.invalidate(appDatabaseProvider);
      _ref.invalidate(doctorProfileProvider);
    }
  }

  Future<void> _copyTree(Directory from, Directory to) async {
    await to.create(recursive: true);
    await for (final entity in from.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final rel = p.relative(entity.path, from: from.path);
      final dest = File(p.join(to.path, rel));
      await dest.parent.create(recursive: true);
      await entity.copy(dest.path);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  String _requireUid() {
    final uid = _ref.read(currentUserIdProvider);
    if (uid == null) throw const AuthFailure('Not signed in.');
    return uid;
  }

  void _requireBackend() {
    if (!AppConfig.hasBackend) {
      throw const NetworkFailure('Backend is not configured.');
    }
  }

  Future<SharedPreferences> _prefs() async {
    SharedPreferences? injected;
    try {
      injected = _ref.read(sharedPreferencesProvider);
    } catch (_) {
      // Not overridden (tests, tools): fall back to the platform instance.
      injected = null;
    }
    return injected ?? await SharedPreferences.getInstance();
  }

  Future<void> _saveLastBackupAt(String uid, DateTime at) async {
    try {
      final prefs = await _prefs();
      await prefs.setString(prefsKey(uid), at.toUtc().toIso8601String());
    } catch (e) {
      debugPrint('[backup] could not record lastBackupAt: $e');
    }
  }

  Future<void> _prune(String uid) async {
    try {
      final entries = await listRemote();
      final stale = [for (final e in entries.skip(keepNewest)) e.storagePath];
      if (stale.isNotEmpty) await _storage.remove(stale);
    } catch (e) {
      // The new backup is already safe; pruning can wait for next time.
      debugPrint('[backup] prune skipped: $e');
    }
  }

  Future<String> _appVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version}+${info.buildNumber}';
    } catch (_) {
      return 'unknown';
    }
  }

  Future<File> _tempFile(String name) async =>
      File(p.join((await _tempDir()).path, name));

  Future<void> _deleteQuietly(FileSystemEntity? entity) async {
    if (entity == null) return;
    try {
      if (await entity.exists()) await entity.delete(recursive: true);
    } catch (e) {
      debugPrint('[backup] temp cleanup failed: $e');
    }
  }

  BackupEntry _toEntry(String uid, FileObject o) {
    final created =
        DateTime.tryParse(o.createdAt ?? '')?.toLocal() ??
        DateTime.tryParse(o.updatedAt ?? '')?.toLocal() ??
        backupTimestampFromName(o.name) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return BackupEntry(
      name: o.name,
      createdAt: created,
      sizeBytes: _sizeOf(o.metadata),
      storagePath: '$uid/${o.name}',
    );
  }

  static int _sizeOf(Map<String, dynamic>? metadata) {
    final raw = metadata?['size'] ?? metadata?['contentLength'];
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw) ?? 0;
    return 0;
  }

  /// `yyyyMMdd-HHmmss` in local time, used in archive names.
  static String backupTimestamp(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year.toString().padLeft(4, '0')}${two(d.month)}${two(d.day)}'
        '-${two(d.hour)}${two(d.minute)}${two(d.second)}';
  }

  /// Inverse of [backupTimestamp] for `rxvarta-backup-<stamp>.zip` names;
  /// null when the name does not follow the pattern.
  static DateTime? backupTimestampFromName(String name) {
    final m = RegExp(
      r'^rxvarta-backup-(\d{4})(\d{2})(\d{2})-(\d{2})(\d{2})(\d{2})\.zip$',
    ).firstMatch(name);
    if (m == null) return null;
    int g(int i) => int.parse(m.group(i)!);
    try {
      return DateTime(g(1), g(2), g(3), g(4), g(5), g(6));
    } catch (_) {
      return null;
    }
  }
}

/// Translates anything thrown while talking to Supabase Storage or the disk
/// into a [Failure]; [what] prefixes the developer-readable message.
Failure mapBackupError(Object e, String what) {
  if (e is Failure) return e;
  if (e is StorageException) {
    final status = int.tryParse(e.statusCode ?? '');
    if (status == 401 || status == 403) {
      return AuthFailure('$what: please sign in again.', cause: e);
    }
    return ApiFailure('$what: ${e.message}', cause: e);
  }
  if (e is SocketException || e is TimeoutException || e is HttpException) {
    return NetworkFailure('$what: no connection.', cause: e);
  }
  if (e is FileSystemException) {
    return StorageFailure('$what: ${e.message}', cause: e);
  }
  if (e is UnsafeZipEntryException ||
      e is ArchiveException ||
      e is FormatException) {
    return StorageFailure(
      '$what: the backup file is damaged.',
      cause: e,
      code: FailureCode.invalidBackup,
    );
  }
  final text = e.toString().toLowerCase();
  if (text.contains('socketexception') ||
      text.contains('clientexception') ||
      text.contains('failed host lookup') ||
      text.contains('connection')) {
    return NetworkFailure('$what: no connection.', cause: e);
  }
  return UnknownFailure('$what: $e', cause: e);
}
