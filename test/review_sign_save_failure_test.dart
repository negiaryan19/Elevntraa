import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rxvarta/data/db/app_database.dart';
import 'package:rxvarta/data/db/database_provider.dart';
import 'package:rxvarta/data/repositories/patient_repository.dart';
import 'package:rxvarta/data/repositories/visit_repository.dart';
import 'package:rxvarta/domain/models/doctor_profile.dart';
import 'package:rxvarta/domain/models/medical_insight.dart';
import 'package:rxvarta/domain/models/medication.dart';
import 'package:rxvarta/domain/models/patient.dart';
import 'package:rxvarta/domain/models/visit.dart';
import 'package:rxvarta/features/prescription/presentation/review_sign_screen.dart';
import 'package:rxvarta/features/settings/data/doctor_profile_repository.dart';
import 'package:rxvarta/l10n/app_localizations.dart';

/// The review screen saved every edit fire-and-forget. When a write failed
/// the header spinner ran forever, nothing told the doctor, and "Sign &
/// Generate PDF" still went on to the PDF of a prescription that was never
/// stored. Its "Share on WhatsApp" button also sent the unsigned draft as
/// plain text, bypassing the sign gate.
class _FlakyVisitRepository extends VisitRepository {
  _FlakyVisitRepository(super.db);

  bool fail = false;

  @override
  Future<void> upsert(VisitRecord v) {
    if (fail) return Future.error(StateError('disk I/O error'));
    return super.upsert(v);
  }
}

class _FlakyPatientRepository extends PatientRepository {
  _FlakyPatientRepository(super.db);

  bool fail = false;

  @override
  Future<void> upsert(PatientProfile p) {
    if (fail) return Future.error(StateError('disk I/O error'));
    return super.upsert(p);
  }
}

class _CompleteProfile extends DoctorProfileController {
  @override
  Future<DoctorProfile> build() async => const DoctorProfile(
    name: 'Dr. Asha Verma',
    qualifications: 'MBBS, MD',
    regNo: 'KA-98765',
    clinicName: 'Verma Clinic',
    clinicAddress: '12 MG Road, Bengaluru',
    phone: '9876543210',
    signatureFileName: 'signature.png',
  );
}

void main() {
  late AppDatabase db;
  late _FlakyVisitRepository visits;
  late _FlakyPatientRepository patients;
  final now = DateTime(2026, 9, 17, 10);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    visits = _FlakyVisitRepository(db);
    patients = _FlakyPatientRepository(db);
    await patients.upsert(
      PatientProfile(
        id: 'p1',
        name: 'Ramesh Kumar',
        age: 42,
        sex: Sex.male,
        whatsappNumber: '9876543210',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await visits.upsert(
      VisitRecord(
        id: 'v1',
        patientId: 'p1',
        createdAt: now,
        insight: const MedicalInsight(
          diagnosis: 'Viral fever',
          medications: [
            Medication(
              name: 'Paracetamol',
              dosage: '500 mg',
              frequency: '1-1-1',
            ),
          ],
        ),
      ),
    );
  });

  tearDown(() async => db.close());

  Future<void> pumpReview(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/review/v1',
      routes: [
        GoRoute(
          path: '/review/:visitId',
          builder: (_, s) =>
              ReviewSignScreen(visitId: s.pathParameters['visitId']!),
        ),
        GoRoute(
          path: '/pdf/:visitId',
          builder: (_, _) => const Scaffold(body: Text('PDF SCREEN')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          visitRepositoryProvider.overrideWithValue(visits),
          patientRepositoryProvider.overrideWithValue(patients),
          doctorProfileProvider.overrideWith(_CompleteProfile.new),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await settle(tester);
  }

  Finder saveSpinner() => find.byWidgetPredicate(
    (w) => w is CircularProgressIndicator && w.strokeWidth == 2,
  );

  Future<void> addMedicine(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Add Medicine'));
    await tester.pump();
    await tester.tap(find.text('Add Medicine'));
    await settle(tester);
  }

  testWidgets('a failed save tells the doctor and stops the spinner', (
    tester,
  ) async {
    await pumpReview(tester);
    visits.fail = true;

    await addMedicine(tester);

    expect(find.text('Could not save your changes'), findsOneWidget);
    expect(saveSpinner(), findsNothing);
  });

  testWidgets('Retry stores the edit once saving works again', (tester) async {
    await pumpReview(tester);
    visits.fail = true;
    await addMedicine(tester);

    visits.fail = false;
    await tester.tap(find.text('Retry'));
    await settle(tester);

    final stored = await VisitRepository(db).byId('v1');
    expect(stored!.insight!.medications, hasLength(2));
  });

  testWidgets('signing stops when the prescription cannot be saved', (
    tester,
  ) async {
    await pumpReview(tester);
    visits.fail = true;

    await tester.tap(find.text('Sign & Generate PDF'));
    await settle(tester);

    expect(find.text('PDF SCREEN'), findsNothing);
    expect(find.text('Could not save your changes'), findsOneWidget);
    final stored = await VisitRepository(db).byId('v1');
    expect(stored!.signed, isFalse);
  });

  testWidgets('signing still opens the PDF when saving works', (tester) async {
    await pumpReview(tester);

    await tester.tap(find.text('Sign & Generate PDF'));
    await settle(tester);

    expect(find.text('PDF SCREEN'), findsOneWidget);
    final stored = await VisitRepository(db).byId('v1');
    expect(stored!.signed, isTrue);
  });

  testWidgets('a failed patient save puts the stored details back', (
    tester,
  ) async {
    await pumpReview(tester);
    patients.fail = true;

    final header = find.ancestor(
      of: find.text('Patient Information'),
      matching: find.byType(Row),
    );
    await tester.tap(
      find.descendant(
        of: header.first,
        matching: find.byIcon(Icons.edit_rounded),
      ),
    );
    await settle(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Ramesh Kumar'),
      'Ramesh K',
    );
    await tester.tap(find.byTooltip('Save').first);
    await settle(tester);

    expect(find.text('Could not save patient'), findsOneWidget);
    expect(find.text('Ramesh Kumar'), findsOneWidget);
    expect(find.text('Ramesh K'), findsNothing);
  });

  testWidgets('an unsigned draft offers no WhatsApp text share', (
    tester,
  ) async {
    await pumpReview(tester);
    expect(find.text('Share on WhatsApp'), findsNothing);
  });
}

/// Real async work (sqlite in a background isolate-free executor) needs
/// wall-clock turns, so pump in short steps instead of pumpAndSettle.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}
