import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/locale/locale_provider.dart';
import '../../../core/utils/app_paths.dart';
import '../../../data/db/app_database.dart';
import '../../../data/db/database_provider.dart';
import 'doctor_profile_repository.dart';

/// What [LocalDataWiper.wipe] managed to remove. [errors] lists the steps
/// that failed (human-readable, for a "partially deleted" message); an empty
/// list means everything went.
class LocalWipeReport {
  const LocalWipeReport({required this.errors});
  final List<String> errors;
  bool get ok => errors.isEmpty;
}

/// Settings > Privacy > "Delete all local data on this device".
///
/// Removes the signed-in doctor's data from the phone, and nobody else's
/// (roadmap item 6):
///
/// * the doctor's folder `users/<uid>/`: database (+ WAL/SHM/journal),
///   scanned reports, recordings, profile cache and signature. The profile
///   is cleared through its controller first so its state drops to
///   [DoctorProfile.empty] immediately,
/// * data from builds that kept one shared database, report folder and
///   recordings folder for the whole phone and that no doctor has claimed,
/// * every SharedPreferences key except UI preferences (language, theme).
///
/// The database handle is closed before its files go and the provider is
/// invalidated afterwards so the next reader opens a fresh, empty database.
/// Everything is best-effort: a missing file is not an error, and a step
/// that fails is recorded in the report instead of aborting the rest.
/// Server-side data (account, backups) is untouched.
class LocalDataWiper {
  LocalDataWiper._();

  /// Preferences that are device settings rather than user data.
  static const Set<String> _keptPrefKeys = {
    kAppLocaleKey,
    // ThemeModeNotifier's private key (lib/core/theme/theme_provider.dart).
    'dark_mode_enabled',
  };

  static const _legacyDbFileName = 'medscribe.sqlite';

  /// Wipe from a widget (Settings > Privacy).
  ///
  /// The providers are resolved by the caller rather than through a generic
  /// `read` callback: Riverpod's `WidgetRef` and `Ref` do not share a common
  /// interface, and the four things this needs are known up front.
  static Future<LocalWipeReport> wipe(WidgetRef ref) => _run(
    uid: ref.read(currentUserIdProvider),
    database: ref.read(appDatabaseProvider),
    profile: ref.read(doctorProfileProvider.notifier),
    invalidateDatabase: () => ref.invalidate(appDatabaseProvider),
  );

  static Future<LocalWipeReport> _run({
    required String? uid,
    required AppDatabase database,
    required DoctorProfileController profile,
    required void Function() invalidateDatabase,
  }) async {
    final errors = <String>[];

    Future<void> step(String name, Future<void> Function() body) async {
      try {
        await body();
      } catch (e) {
        debugPrint('[wipe] $name failed: $e');
        errors.add(name);
      }
    }

    final documents = AppPaths.documentsDir;

    // 1. Close the database so SQLite releases its files (and the
    //    background isolate stops) before they are deleted.
    await step('database', database.close);

    // 2. Unclaimed data from builds with one shared database for the phone.
    await step('shared data', () async {
      for (final base in [AppPaths.databaseFileName, _legacyDbFileName]) {
        for (final suffix in AppPaths.databaseSidecars) {
          await _deleteFile(File(p.join(documents, '$base$suffix')));
        }
      }
      await _deleteDir(Directory(p.join(documents, 'attachments')));
      await _deleteDir(Directory(p.join(documents, 'recordings')));
    });

    // 3. The doctor's own folder: database, reports, recordings, profile and
    //    signature. Clear the profile through the controller first so
    //    widgets watching it update, then remove the whole folder.
    await step('profile', profile.clearLocal);
    if (uid != null) {
      await step(
        'user folder',
        () => _deleteDir(Directory(p.join(documents, 'users', uid))),
      );
    }

    // 4. Preferences that hold user data. Language and theme are kept.
    await step('preferences', () async {
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys().toList()) {
        if (_keptPrefKeys.contains(key)) continue;
        await prefs.remove(key);
      }
    });

    // 5. Fresh database handle for whoever reads next.
    try {
      invalidateDatabase();
    } catch (e) {
      debugPrint('[wipe] could not invalidate database provider: $e');
    }

    return LocalWipeReport(errors: List.unmodifiable(errors));
  }

  static Future<void> _deleteFile(File file) async {
    if (!await file.exists()) return;
    await file.delete();
  }

  static Future<void> _deleteDir(Directory dir) async {
    if (!await dir.exists()) return;
    await dir.delete(recursive: true);
  }
}
