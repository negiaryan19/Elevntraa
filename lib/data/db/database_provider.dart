import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/utils/app_paths.dart';
import 'app_database.dart';

/// The signed-in doctor's database (roadmap item 6). Signing out, or another
/// doctor signing in, closes it and opens that doctor's own file, so one
/// doctor's patients and prescriptions are never shown to another.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  final db = uid == null ? AppDatabase.signedOut() : AppDatabase.forDoctor(uid);
  ref.onDispose(db.close);
  return db;
});

/// The signed-in doctor's scanned-report folder; null when signed out.
final attachmentsDirProvider = Provider<String?>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  return uid == null ? null : AppPaths.attachmentsDir(uid);
});
