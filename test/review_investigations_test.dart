import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rxvarta/data/db/app_database.dart';
import 'package:rxvarta/data/db/database_provider.dart';
import 'package:rxvarta/data/repositories/patient_repository.dart';
import 'package:rxvarta/data/repositories/visit_repository.dart';
import 'package:rxvarta/domain/models/medical_insight.dart';
import 'package:rxvarta/domain/models/patient.dart';
import 'package:rxvarta/domain/models/visit.dart';
import 'package:rxvarta/features/prescription/presentation/review_sign_screen.dart';
import 'package:rxvarta/l10n/app_localizations.dart';

/// The pipeline extracted laboratory tests and the doctor's notes, and the
/// app showed neither: they existed only inside the stored JSON (roadmap
/// item 19).
void main() {
  late AppDatabase db;
  final now = DateTime(2026, 9, 17, 10);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await PatientRepository(db).upsert(
      PatientProfile(
        id: 'p1',
        name: 'Ramesh Kumar',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await VisitRepository(db).upsert(
      VisitRecord(
        id: 'v1',
        patientId: 'p1',
        createdAt: now,
        insight: const MedicalInsight(
          diagnosis: 'Suspected anaemia',
          tests: ['Complete blood count', 'Serum ferritin'],
          doctorNotes: 'Recheck haemoglobin before starting iron.',
        ),
      ),
    );
  });
  tearDown(() async => db.close());

  testWidgets('review shows the extracted tests and the doctor notes', (
    tester,
  ) async {
    // Tall enough to show the whole review at once, so the test does not
    // depend on scrolling a screen that has several scrollables.
    tester.view.physicalSize = const Size(1080, 6000);
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
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    for (var i = 0; i < 12; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Bullet lists render each item with a leading bullet.
    expect(find.text('\u2022  Complete blood count'), findsOneWidget);
    expect(find.text('\u2022  Serum ferritin'), findsOneWidget);
    expect(find.text('Investigations'), findsOneWidget);
    expect(
      find.text('Recheck haemoglobin before starting iron.'),
      findsOneWidget,
    );
    // The notes are the doctor's own: the card says they are not printed.
    expect(
      find.text('Kept for your records; not printed on the prescription'),
      findsOneWidget,
    );
  });
}
