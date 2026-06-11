import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/repositories/patient_repository.dart';
import '../../../data/repositories/visit_repository.dart';
import '../../../domain/models/patient.dart';
import '../../../domain/models/visit.dart';

/// Result of a successful intake submission — the IDs the next screen
/// (recording) needs to attach the audio + transcript to.
class IntakeResult {
  IntakeResult({required this.visitId, required this.patientId});
  final String visitId;
  final String patientId;
}

class IntakeController {
  IntakeController(this._patients, this._visits);

  final PatientRepository _patients;
  final VisitRepository _visits;
  final _uuid = const Uuid();

  Future<IntakeResult> submit({
    required String name,
    int? age,
    Sex? sex,
    required String whatsappNumber,
  }) async {
    final now = DateTime.now();
    final patientId = _uuid.v4();
    final visitId = _uuid.v4();

    await _patients.upsert(PatientProfile(
      id: patientId,
      name: name.trim(),
      age: age,
      sex: sex,
      whatsappNumber: whatsappNumber.trim().isEmpty ? null : whatsappNumber.trim(),
      createdAt: now,
      updatedAt: now,
    ));

    await _visits.upsert(VisitRecord(
      id: visitId,
      patientId: patientId,
      createdAt: now,
      patientConsent: true,
      consentAt: now,
    ));

    return IntakeResult(visitId: visitId, patientId: patientId);
  }
}

final intakeControllerProvider = Provider<IntakeController>((ref) {
  return IntakeController(
    ref.watch(patientRepositoryProvider),
    ref.watch(visitRepositoryProvider),
  );
});
