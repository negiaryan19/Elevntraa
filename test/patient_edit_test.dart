import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rxvarta/app/router.dart';
import 'package:rxvarta/data/db/app_database.dart';
import 'package:rxvarta/data/db/database_provider.dart';
import 'package:rxvarta/data/repositories/patient_repository.dart';
import 'package:rxvarta/data/repositories/visit_repository.dart';
import 'package:rxvarta/domain/models/medical_insight.dart';
import 'package:rxvarta/domain/models/patient.dart';
import 'package:rxvarta/domain/models/visit.dart';
import 'package:rxvarta/features/patient/presentation/patient_detail_screen.dart';
import 'package:rxvarta/features/patient/presentation/patients_screen.dart';
import 'package:rxvarta/l10n/app_localizations.dart';

/// A patient's name, age, gender and WhatsApp number could only be changed
/// from the review screen of a consultation, so correcting a mistyped number
/// meant starting a new visit (roadmap item 16). They can now be edited from
/// the patient's own page.
void main() {
  late AppDatabase db;
  final created = DateTime(2026, 9, 1, 10);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await PatientRepository(db).upsert(
      PatientProfile(
        id: 'p1',
        name: 'Ramesh Kumr',
        age: 42,
        sex: Sex.male,
        whatsappNumber: '9000000000',
        createdAt: created,
        updatedAt: created,
      ),
    );
    await VisitRepository(db).upsert(
      VisitRecord(
        id: 'v1',
        patientId: 'p1',
        createdAt: created,
        transcript: 'Doctor: viral fever hai.',
        signed: true,
        signedAt: created,
        insight: const MedicalInsight(diagnosis: 'Viral fever'),
      ),
    );
  });
  tearDown(() async => db.close());

  Future<void> pump(WidgetTester tester, {String at = '/patient/p1'}) async {
    tester.view.physicalSize = const Size(1080, 5000);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: at,
      routes: [
        GoRoute(path: '/patients', builder: (_, _) => const PatientsScreen()),
        GoRoute(
          path: AppRoute.patient.path,
          builder: (_, s) =>
              PatientDetailScreen(patientId: s.pathParameters['patientId']!),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets('an edit is saved and shown on the patient page', (tester) async {
    await pump(tester);
    expect(find.text('Ramesh Kumr'), findsWidgets);

    await tester.tap(find.byKey(const Key('edit_patient_button')));
    await settle(tester);
    await tester.enterText(
      find.byKey(const Key('edit_patient_name')),
      '  Ramesh Kumar ',
    );
    await tester.enterText(find.byKey(const Key('edit_patient_age')), '43');
    await tester.enterText(
      find.byKey(const Key('edit_patient_whatsapp')),
      '9876543210',
    );
    await tester.tap(find.byKey(const Key('edit_patient_save')));
    await settle(tester);

    final saved = (await PatientRepository(db).byId('p1'))!;
    expect(saved.name, 'Ramesh Kumar', reason: 'trimmed');
    expect(saved.age, 43);
    expect(saved.whatsappNumber, '9876543210');
    expect(saved.sex, Sex.male, reason: 'untouched field kept');
    expect(saved.createdAt, created);
    expect(saved.updatedAt.isAfter(created), isTrue);

    expect(find.byKey(const Key('edit_patient_save')), findsNothing);
    expect(find.text('Ramesh Kumar'), findsWidgets);
    expect(find.text('Ramesh Kumr'), findsNothing);
  });

  testWidgets('editing a patient never touches their visits', (tester) async {
    final before = (await VisitRepository(db).byId('v1'))!;
    await pump(tester);
    await tester.tap(find.byKey(const Key('edit_patient_button')));
    await settle(tester);
    await tester.enterText(
      find.byKey(const Key('edit_patient_name')),
      'Someone Else',
    );
    await tester.tap(find.byKey(const Key('edit_patient_save')));
    await settle(tester);

    final visits = await VisitRepository(db).forPatient('p1');
    expect(visits, hasLength(1));
    expect(visits.single, before, reason: 'a signed visit is a record');
  });

  testWidgets('a blank name is refused and nothing is saved', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('edit_patient_button')));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('edit_patient_name')), '   ');
    await tester.tap(find.byKey(const Key('edit_patient_save')));
    await settle(tester);

    expect(find.text('Name is required'), findsOneWidget);
    expect(find.byKey(const Key('edit_patient_save')), findsOneWidget);
    expect((await PatientRepository(db).byId('p1'))!.name, 'Ramesh Kumr');
  });

  testWidgets('cancel changes nothing', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('edit_patient_button')));
    await settle(tester);
    await tester.enterText(
      find.byKey(const Key('edit_patient_name')),
      'Typed But Abandoned',
    );
    await tester.tap(find.text('Cancel'));
    await settle(tester);

    final after = (await PatientRepository(db).byId('p1'))!;
    expect(after.name, 'Ramesh Kumr');
    expect(after.updatedAt, created);
  });

  testWidgets('clearing the number removes it instead of saving ""', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('edit_patient_button')));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('edit_patient_whatsapp')), '');
    await tester.tap(find.byKey(const Key('edit_patient_save')));
    await settle(tester);

    expect((await PatientRepository(db).byId('p1'))!.whatsappNumber, isNull);
  });

  testWidgets('the Patients list shows the new name after coming back', (
    tester,
  ) async {
    await pump(tester, at: '/patients');
    expect(find.text('Ramesh Kumr'), findsOneWidget);

    await tester.tap(find.text('Ramesh Kumr'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('edit_patient_button')));
    await settle(tester);
    await tester.enterText(
      find.byKey(const Key('edit_patient_name')),
      'Ramesh Kumar',
    );
    await tester.tap(find.byKey(const Key('edit_patient_save')));
    await settle(tester);

    await tester.pageBack();
    await settle(tester);
    expect(find.byType(PatientsScreen), findsOneWidget);
    expect(find.text('Ramesh Kumar'), findsOneWidget);
    expect(find.text('Ramesh Kumr'), findsNothing);
  });
}

/// Lets the in-memory database answer and the sheet animate, without
/// pumpAndSettle (a progress spinner on screen would never settle).
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 60));
  }
}
