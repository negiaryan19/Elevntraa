import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/repositories/patient_repository.dart';
import '../../../data/repositories/visit_repository.dart';
import '../../../domain/models/patient.dart';
import '../../../domain/models/report_attachment.dart';
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

  /// Creates a visit for a patient. When [existingPatientId] is provided the
  /// patient record is updated in place (same id, original createdAt preserved)
  /// so the new visit stacks onto that person's history; otherwise a brand-new
  /// patient is created.
  Future<IntakeResult> submit({
    required String name,
    int? age,
    Sex? sex,
    required String whatsappNumber,
    String? existingPatientId,
    List<ReportAttachment> attachments = const [],
  }) async {
    final now = DateTime.now();
    final visitId = _uuid.v4();

    final patientId = existingPatientId ?? _uuid.v4();
    var createdAt = now;
    if (existingPatientId != null) {
      final existing = await _patients.byId(existingPatientId);
      if (existing != null) createdAt = existing.createdAt;
    }

    await _patients.upsert(
      PatientProfile(
        id: patientId,
        name: name.trim(),
        age: age,
        sex: sex,
        whatsappNumber: whatsappNumber.trim().isEmpty
            ? null
            : whatsappNumber.trim(),
        createdAt: createdAt,
        updatedAt: now,
      ),
    );

    await _visits.upsert(
      VisitRecord(
        id: visitId,
        patientId: patientId,
        createdAt: now,
        attachments: attachments,
        patientConsent: true,
        consentAt: now,
      ),
    );

    return IntakeResult(visitId: visitId, patientId: patientId);
  }

  /// Looks up a saved patient by exact WhatsApp number (duplicate detection).
  Future<PatientProfile?> findByPhone(String whatsappNumber) =>
      _patients.findByWhatsapp(whatsappNumber);
}

final intakeControllerProvider = Provider<IntakeController>((ref) {
  return IntakeController(
    ref.watch(patientRepositoryProvider),
    ref.watch(visitRepositoryProvider),
  );
});
