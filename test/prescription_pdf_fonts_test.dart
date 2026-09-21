import 'package:flutter_test/flutter_test.dart';
import 'package:rxvarta/domain/models/doctor_profile.dart';
import 'package:rxvarta/domain/models/medical_insight.dart';
import 'package:rxvarta/domain/models/patient.dart';
import 'package:rxvarta/domain/models/visit.dart';
import 'package:rxvarta/features/prescription/data/prescription_pdf_service.dart';

import 'support/pdf_text.dart';

/// Prescriptions used to download their fonts at print time: offline, the
/// theme fell back to Helvetica and every non-Latin character vanished. The
/// fonts are now bundled.
///
/// Indian scripts also need shaping (reordered vowel signs, joined
/// consonants), which the pdf package does not do: text in those scripts
/// printed misspelled. It is now shaped by Flutter and embedded as images.
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
    return pdfText(bytes);
  }

  test('Latin text is real text in bundled Noto Sans, not Helvetica', () async {
    final pdf = await buildWith(
      patientName: 'Ramesh Kumar',
      diagnosis: 'Viral fever',
    );
    expect(pdf, contains('NotoSans'));
    expect(pdf, isNot(contains('/Helvetica')));
    // Nothing needed shaping, so nothing was drawn as an image.
    expect(pdf, isNot(contains('/Subtype/Image')));
  });

  for (final (script, name, diagnosis) in const [
    ('Devanagari', 'सुनीता देवी', 'वायरल बुखार'),
    ('Tamil', 'முருகன்', 'காய்ச்சல்'),
    ('Telugu', 'రమేష్', 'జ్వరం'),
    ('Kannada', 'ರಮೇಶ್', 'ಜ್ವರ'),
    ('Bengali', 'সুনীতা', 'জ্বর'),
    ('Gujarati', 'રમેશ', 'તાવ'),
  ]) {
    test('$script text is shaped, not printed letter by letter', () async {
      final pdf = await buildWith(patientName: name, diagnosis: diagnosis);
      expect(
        pdf,
        contains('/Subtype/Image'),
        reason: '$script text must go through the shaper',
      );
      expect(
        pdf,
        contains('beginbfchar'),
        reason: 'the font maps must be readable, or the next check is empty',
      );
      // No Indian-script letter reached the pdf package's text path, which
      // would draw it in typing order.
      expect(
        drawsIndicAsText(pdf),
        isFalse,
        reason: '$script letters were printed as unshaped text',
      );
      expect(
        shapedImageCount(pdf),
        2,
        reason: 'the patient name and the diagnosis are each one shaped line',
      );
      expect(pdf, isNot(contains('/Helvetica')));
    });
  }
}
