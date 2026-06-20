import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../domain/models/doctor_profile.dart';

class DoctorProfileRepository {
  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'doctor_profile.json'));
  }

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

class DoctorProfileController extends Notifier<DoctorProfile> {
  @override
  DoctorProfile build() {
    _init();
    return DoctorProfile.defaultProfile;
  }

  DoctorProfileRepository get _repo =>
      ref.read(doctorProfileRepositoryProvider);

  Future<void> _init() async {
    state = await _repo.load();
  }

  Future<void> update(DoctorProfile profile) async {
    state = profile;
    await _repo.save(profile);
  }
}

final doctorProfileControllerProvider =
    NotifierProvider<DoctorProfileController, DoctorProfile>(
      DoctorProfileController.new,
    );
