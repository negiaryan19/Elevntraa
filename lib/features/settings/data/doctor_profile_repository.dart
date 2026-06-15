import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../domain/models/doctor_profile.dart';

/// Persists the [DoctorProfile] to a small JSON file in the app documents
/// directory. A plain file keeps it dependency-light and avoids a drift schema
/// migration for what is a single editable record.
class DoctorProfileRepository {
  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'doctor_profile.json'));
  }

  /// Returns the stored profile, or [DoctorProfile.defaultProfile] if nothing
  /// has been saved yet (or the file is unreadable).
  Future<DoctorProfile> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return DoctorProfile.defaultProfile;
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return DoctorProfile.defaultProfile;
      return DoctorProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return DoctorProfile.defaultProfile;
    }
  }

  Future<void> save(DoctorProfile profile) async {
    final file = await _file();
    await file.writeAsString(jsonEncode(profile.toJson()));
  }
}

final doctorProfileRepositoryProvider = Provider<DoctorProfileRepository>(
  (ref) => DoctorProfileRepository(),
);

/// Holds the current profile in memory and persists edits. Screens read this
/// (PDF letterhead, signature, Settings) so an edit propagates everywhere.
/// Starts with the default and swaps in the stored value once loaded.
class DoctorProfileController extends StateNotifier<DoctorProfile> {
  DoctorProfileController(this._repo) : super(DoctorProfile.defaultProfile) {
    _init();
  }

  final DoctorProfileRepository _repo;

  Future<void> _init() async {
    state = await _repo.load();
  }

  Future<void> update(DoctorProfile profile) async {
    state = profile;
    await _repo.save(profile);
  }
}

final doctorProfileControllerProvider =
    StateNotifierProvider<DoctorProfileController, DoctorProfile>((ref) {
      return DoctorProfileController(
        ref.watch(doctorProfileRepositoryProvider),
      );
    });
