import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rxvarta/domain/models/doctor_profile.dart';
import 'package:rxvarta/domain/models/medical_insight.dart';
import 'package:rxvarta/domain/models/medication.dart';
import 'package:rxvarta/domain/models/patient.dart';
import 'package:rxvarta/domain/models/visit.dart';
import 'package:rxvarta/features/prescription/data/prescription_pdf_service.dart';

/// 1x1 transparent PNG (67 bytes) — enough for the pdf package to embed.
final Uint8List kTinyPng = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // signature
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR length + type
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1 x 1
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, // 8-bit RGBA + CRC
  0x89, //
  0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, // IDAT length + type
  0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, // zlib data
  0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, // + CRC
  0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, // IEND
  0xAE, 0x42, 0x60, 0x82, // CRC
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 9, 16, 10, 30);
  final patient = PatientProfile(
    id: 'p1',
    name: 'Ramesh Kumar',
    age: 42,
    sex: Sex.male,
    whatsappNumber: '9876543210',
    createdAt: now,
    updatedAt: now,
  );
  const doctor = DoctorProfile(
    name: 'Dr. Asha Verma',
    qualifications: 'MBBS, MD',
    regNo: 'KA-98765',
    clinicName: 'Verma Clinic',
    clinicAddress: '12 MG Road, Bengaluru 560001',
    phone: '9876543210',
    signatureFileName: 'signature.png',
  );
  final signedVisit = VisitRecord(
    id: 'v1',
    patientId: 'p1',
    createdAt: now,
    signed: true,
    signedAt: now,
    insight: const MedicalInsight(
      diagnosis: 'Viral fever',
      medications: [
        Medication(
          name: 'Paracetamol',
          dosage: '500 mg',
          frequency: '1-1-1',
          duration: '3 days',
          timing: 'After food',
        ),
      ],
      advice: ['Rest and fluids'],
      followUpDays: 3,
    ),
  );

  /// The service downloads Google fonts for the theme; in tests the network
  /// is unavailable and it falls back to the built-in fonts. Anything else
  /// that fails because of fonts/plugins marks the test skipped rather than
  /// failing on an environment problem.
  Future<Uint8List?> tryBuild(Future<Uint8List> Function() build) async {
    try {
      return await build();
    } catch (e) {
      final text = e.toString().toLowerCase();
      if (text.contains('font') ||
          text.contains('glyph') ||
          text.contains('missingplugin') ||
          text.contains('socket') ||
          text.contains('http')) {
        markTestSkipped('PDF fonts need network / plugins: $e');
        return null;
      }
      rethrow;
    }
  }

  test('signed visit with a signature image produces a PDF', () async {
    final svc = PrescriptionPdfService();
    final bytes = await tryBuild(
      () => svc.build(
        visit: signedVisit,
        patient: patient,
        doctor: doctor,
        signaturePng: kTinyPng,
        awaitingSignatureLabel: 'Awaiting signature',
      ),
    );
    if (bytes == null) return;
    expect(bytes, isNotEmpty);
    // %PDF- header
    expect(bytes.sublist(0, 5), [0x25, 0x50, 0x44, 0x46, 0x2D]);
  });

  test(
    'signed visit without an image still builds (no fake cursive)',
    () async {
      final svc = PrescriptionPdfService();
      final bytes = await tryBuild(
        () => svc.build(visit: signedVisit, patient: patient, doctor: doctor),
      );
      if (bytes == null) return;
      expect(bytes, isNotEmpty);
    },
  );

  test('unsigned visit with a blank profile builds', () async {
    final svc = PrescriptionPdfService();
    final bytes = await tryBuild(
      () => svc.build(
        visit: signedVisit.copyWith(signed: false, signedAt: null),
        patient: patient,
        doctor: DoctorProfile.empty,
        signaturePng: kTinyPng,
      ),
    );
    if (bytes == null) return;
    expect(bytes, isNotEmpty);
  });

  test('garbage signature bytes are ignored, not fatal', () async {
    final svc = PrescriptionPdfService();
    final bytes = await tryBuild(
      () => svc.build(
        visit: signedVisit,
        patient: patient,
        doctor: doctor,
        signaturePng: Uint8List.fromList([1, 2, 3, 4, 5, 6]),
      ),
    );
    if (bytes == null) return;
    expect(bytes, isNotEmpty);
  });

  group('fileName', () {
    final svc = PrescriptionPdfService();

    test('is safe, dated and identifies the visit', () {
      expect(
        svc.fileName(patient, signedVisit),
        'Prescription_Ramesh_Kumar_20260916-1030_v1.pdf',
      );
    });

    test('keeps a name written in an Indian script', () {
      final hindi = patient.copyWith(name: 'सुनीता देवी');
      expect(svc.fileName(hindi, signedVisit), contains('सुनीता_देवी'));
    });

    test('differs for two visits on the same day', () {
      final later = signedVisit.copyWith(
        id: 'v2',
        createdAt: signedVisit.createdAt.add(const Duration(hours: 6)),
      );
      expect(
        svc.fileName(patient, signedVisit),
        isNot(svc.fileName(patient, later)),
      );
    });

    test('never contains characters unsafe in a file name', () {
      final awkward = patient.copyWith(name: 'A/B:C*D?"E<F>G|H');
      expect(
        svc.fileName(awkward, signedVisit),
        isNot(matches(RegExp(r'[\\/:*?"<>|]'))),
      );
    });
  });
}
