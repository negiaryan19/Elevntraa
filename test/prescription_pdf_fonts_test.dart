import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rxvarta/domain/models/doctor_profile.dart';
import 'package:rxvarta/domain/models/medical_insight.dart';
import 'package:rxvarta/domain/models/patient.dart';
import 'package:rxvarta/domain/models/visit.dart';
import 'package:rxvarta/features/prescription/data/prescription_pdf_service.dart';

/// Prescriptions used to download their fonts at print time. Offline, the
/// theme fell back to Helvetica and every non-Latin character vanished; even
/// online only Devanagari had a fallback, so Tamil, Telugu, Kannada, Bengali
/// and Gujarati printed as empty boxes. The fonts are now bundled.
///
/// Tests have no network, so these builds prove the bundled path works.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 9, 17, 11);
  const doctor = DoctorProfile(
    name: 'Dr. Asha Verma',
    qualifications: 'MBBS, MD',
    regNo: 'KA-98765',
    clinicName: 'Verma Clinic',
    clinicAddress: '12 MG Road, Bengaluru',
    phone: '9876543210',
    signatureFileName: 'signature.png',
  );

  Future<String> buildWith({
    required String patientName,
    required String diagnosis,
  }) async {
    final bytes = await PrescriptionPdfService().build(
      visit: VisitRecord(
        id: 'v1',
        patientId: 'p1',
        createdAt: now,
        insight: MedicalInsight(diagnosis: diagnosis),
      ),
      patient: PatientProfile(
        id: 'p1',
        name: patientName,
        createdAt: now,
        updatedAt: now,
      ),
      doctor: doctor,
    );
    return _pdfText(bytes);
  }

  test('the Latin text uses bundled Noto Sans, not Helvetica', () async {
    final pdf = await buildWith(
      patientName: 'Ramesh Kumar',
      diagnosis: 'Viral fever',
    );
    expect(pdf, contains('NotoSans'));
    expect(pdf, isNot(contains('/Helvetica')));
  });

  // Which font must carry each script's glyphs. Base Noto Sans already
  // includes all 128 Devanagari characters (verified from its cmap), so
  // Hindi and Marathi render from it and no Devanagari fallback is needed;
  // every other script needs its own bundled font.
  for (final (script, font, name, diagnosis) in const [
    ('Devanagari', 'NotoSans', 'सुनीता देवी', 'वायरल बुखार'),
    ('Tamil', 'NotoSansTamil', 'முருகன்', 'காய்ச்சல்'),
    ('Telugu', 'NotoSansTelugu', 'రమేష్', 'జ్వరం'),
    ('Kannada', 'NotoSansKannada', 'ರಮೇಶ್', 'ಜ್ವರ'),
    ('Bengali', 'NotoSansBengali', 'সুনীতা', 'জ্বর'),
    ('Gujarati', 'NotoSansGujarati', 'રમેશ', 'તાવ'),
  ]) {
    test('$script text is printed with a font that has its glyphs', () async {
      final pdf = await buildWith(patientName: name, diagnosis: diagnosis);
      expect(
        pdf,
        contains(font),
        reason: '$script text needs $font, or it prints as blank boxes',
      );
      // Helvetica has no glyphs for any Indian script: its presence is the
      // offline failure this guards against.
      expect(pdf, isNot(contains('/Helvetica')));
    });
  }
}

/// The PDF as Latin-1 text, enough to find font names in its dictionaries.
String _pdfText(Uint8List bytes) => latin1.decode(bytes, allowInvalid: true);
