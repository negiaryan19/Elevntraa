import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/patient.dart';
import '../db/app_database.dart';
import '../db/database_provider.dart';

/// Maps drift rows ↔ freezed [PatientProfile]. The repository is the only
/// thing that talks to drift directly; everything else uses freezed models.
class PatientRepository {
  PatientRepository(this._db);

  final AppDatabase _db;

  Future<List<PatientProfile>> recent({int limit = 20}) async {
    final rows = await _db.recentPatients(limit: limit);
    return rows.map(_toProfile).toList();
  }

  Future<List<PatientProfile>> search(String query) async {
    if (query.trim().isEmpty) return recent();
    final rows = await _db.searchPatients(query);
    return rows.map(_toProfile).toList();
  }

  Future<PatientProfile?> byId(String id) async {
    final row = await _db.patientById(id);
    return row == null ? null : _toProfile(row);
  }

  Future<void> upsert(PatientProfile profile) {
    return _db.upsertPatient(PatientsCompanion(
      id: Value(profile.id),
      name: Value(profile.name),
      age: Value(profile.age),
      sex: Value(profile.sex?.name),
      whatsappNumber: Value(profile.whatsappNumber),
      phone: Value(profile.phone),
      createdAt: Value(profile.createdAt),
      updatedAt: Value(profile.updatedAt),
    ));
  }

  PatientProfile _toProfile(Patient row) {
    return PatientProfile(
      id: row.id,
      name: row.name,
      age: row.age,
      sex: _sexFromString(row.sex),
      whatsappNumber: row.whatsappNumber,
      phone: row.phone,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  Sex? _sexFromString(String? s) {
    if (s == null) return null;
    return Sex.values.where((v) => v.name == s).firstOrNull;
  }
}

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return PatientRepository(ref.watch(appDatabaseProvider));
});
