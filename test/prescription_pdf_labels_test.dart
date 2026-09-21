import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxvarta/core/locale/locale_provider.dart';
import 'package:rxvarta/core/prefs/shared_preferences_provider.dart';
import 'package:rxvarta/domain/models/doctor_profile.dart';
import 'package:rxvarta/domain/models/medical_insight.dart';
import 'package:rxvarta/domain/models/medication.dart';
import 'package:rxvarta/domain/models/patient.dart';
import 'package:rxvarta/domain/models/visit.dart';
import 'package:rxvarta/features/prescription/data/pdf_shaper.dart';
import 'package:rxvarta/features/prescription/data/prescription_pdf_service.dart';
import 'package:rxvarta/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/pdf_text.dart';

/// The app runs in eight languages, but every prescription printed its
/// labels (Patient, Diagnosis, Dosage, Advice, Follow-up…) in English
/// (roadmap item 21).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 9, 18, 10);
  const doctor = DoctorProfile(
    name: 'Dr. Asha Verma',
    qualifications: 'MBBS, MD',
    regNo: 'KA-98765',
    clinicName: 'Verma Clinic',
    clinicAddress: '12 MG Road, Bengaluru',
    phone: '9876543210',
  );
  // Only Latin text in the data itself, so any Indian-script glyph in the
  // PDF can only come from a label.
  final visit = VisitRecord(
    id: 'v1',
    patientId: 'p1',
    createdAt: now,
    insight: const MedicalInsight(
      diagnosis: 'Viral fever',
      medications: [Medication(name: 'Paracetamol', dosage: '650 mg')],
      tests: ['CBC'],
      advice: ['Rest'],
      followUpDays: 3,
    ),
  );
  final patient = PatientProfile(
    id: 'p1',
    name: 'Ramesh Kumar',
    age: 42,
    sex: Sex.male,
    createdAt: now,
    updatedAt: now,
  );

  Future<String> pdfIn(String locale) async {
    final bytes = await PrescriptionPdfService(
      labels: lookupAppLocalizations(Locale(locale)),
    ).build(visit: visit, patient: patient, doctor: doctor);
    return pdfText(bytes);
  }

  // Every label this visit prints. It is unsigned, has medicines, tests,
  // advice and a follow-up, and the patient row always shows Phone.
  List<String> printedLabels(AppLocalizations t) => [
    t.pdfPatient,
    t.pdfDate,
    t.pdfAge,
    t.pdfGender,
    t.pdfPhone,
    t.pdfRegNo,
    t.pdfDiagnosis,
    t.pdfColMedicine,
    t.pdfColDosage,
    t.pdfColFrequency,
    t.pdfColDuration,
    t.pdfColTiming,
    t.pdfInvestigations,
    t.pdfAdvice,
    t.pdfFollowUp,
    t.pdfNextVisit,
    t.pdfAwaitingSignature,
    t.pdfComputerGenerated,
    t.pdfFooterTagline,
    t.pdfAgeYears(42),
    t.pdfFollowUpAfter(3),
  ];

  // The data itself is Latin only, so every Indian-script line on the page
  // is a translated label, and each one is shaped by Flutter (see PdfShaper)
  // instead of printed letter by letter. Checking the shaper saw each label
  // catches one that silently went back to English; merely finding "some
  // image" would not, since any one translated line would satisfy it.
  for (final locale in const ['hi', 'mr', 'ta', 'te', 'kn', 'bn', 'gu']) {
    test('a $locale prescription prints its labels in that language', () async {
      PdfShaper.clearCache();
      await pdfIn(locale);
      final shaped = PdfShaper.cachedKeys.join('\n');
      final t = lookupAppLocalizations(Locale(locale));
      for (final label in printedLabels(t)) {
        if (!PdfShaper.needsShaping(label)) continue;
        expect(
          shaped,
          contains(label),
          reason: 'the $locale prescription did not print "$label"',
        );
      }
    });
  }

  // Doctor's notes are the doctor's own record. Devanagari is used so that,
  // if they were ever printed, they could only appear as a shaped image on
  // an otherwise all-Latin English page.
  test("the doctor's notes are never printed on the prescription", () async {
    final bytes = await PrescriptionPdfService().build(
      visit: VisitRecord(
        id: 'v2',
        patientId: 'p1',
        createdAt: now,
        insight: const MedicalInsight(
          diagnosis: 'Viral fever',
          doctorNotes: 'रोगी को दोबारा जाँचें',
        ),
      ),
      patient: patient,
      doctor: doctor,
    );
    expect(pdfText(bytes), isNot(contains('/Subtype/Image')));
  });

  test('investigations the doctor advised are printed', () async {
    final bytes = await PrescriptionPdfService().build(
      visit: VisitRecord(
        id: 'v3',
        patientId: 'p1',
        createdAt: now,
        insight: const MedicalInsight(
          diagnosis: 'Viral fever',
          tests: ['रक्त जाँच'],
        ),
      ),
      patient: patient,
      doctor: doctor,
    );
    // The one non-Latin line on the page is the investigation.
    expect(shapedImageCount(pdfText(bytes)), 1);
  });

  test('an English prescription is plain text throughout', () async {
    expect(await pdfIn('en'), isNot(contains('/Subtype/Image')));
  });

  test('every prescription label is translated in every language', () {
    final en = lookupAppLocalizations(const Locale('en'));
    String labels(AppLocalizations t) => [
      t.pdfPatient,
      t.pdfDate,
      t.pdfAge,
      t.pdfGender,
      t.pdfPhone,
      t.pdfRegNo,
      t.pdfDiagnosis,
      t.pdfNoMedicines,
      t.pdfColMedicine,
      t.pdfColDosage,
      t.pdfColFrequency,
      t.pdfColDuration,
      t.pdfColTiming,
      t.pdfInvestigations,
      t.pdfInstructions,
      t.pdfAdvice,
      t.pdfFollowUp,
      t.pdfNextVisit,
      t.pdfPreviousReports,
      t.pdfComputerGenerated,
      t.pdfFooterTagline,
      t.pdfAwaitingSignature,
      t.pdfAgeYears(42),
      t.pdfFollowUpAfter(3),
      t.pdfReportCaption(1),
      t.pdfDocumentTitle('X'),
      t.pdfReportsAttachedFor('X'),
    ].join('\n');
    final english = labels(en).split('\n');
    for (final code in ['hi', 'mr', 'te', 'ta', 'kn', 'bn', 'gu']) {
      final translated = labels(
        lookupAppLocalizations(Locale(code)),
      ).split('\n');
      for (var i = 0; i < english.length; i++) {
        expect(
          translated[i],
          isNot(english[i]),
          reason: '$code still prints "${english[i]}" in English',
        );
      }
    }
  });

  test('follow-up days read naturally for one day and several', () {
    final en = lookupAppLocalizations(const Locale('en'));
    expect(en.pdfFollowUpAfter(1), 'After 1 day');
    expect(en.pdfFollowUpAfter(3), 'After 3 days');
  });

  test('the prescription follows the language chosen in the app', () async {
    SharedPreferences.setMockInitialValues({kAppLocaleKey: 'ta'});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    final bytes = await container
        .read(prescriptionPdfServiceProvider)
        .build(visit: visit, patient: patient, doctor: doctor);
    expect(pdfText(bytes), contains('/Subtype/Image'));
  });
}
