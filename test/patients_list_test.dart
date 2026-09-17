import 'package:drift/drift.dart' as d;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxvarta/data/db/app_database.dart';
import 'package:rxvarta/data/db/database_provider.dart';
import 'package:rxvarta/data/repositories/visit_repository.dart';
import 'package:rxvarta/features/patient/presentation/patients_screen.dart';
import 'package:rxvarta/l10n/app_localizations.dart';

/// The Patients tab used to show only the patients inside the clinic's 50
/// most recent visits. Past 50 consultations, older patients vanished from
/// the list and from its search, and a regular's consultation count only
/// counted the visits inside that window.
///
/// Seed, newest to oldest:
///   * 47 one-visit patients in the last hour
///   * Sunita Devi, 12 visits (3 recent, 9 three days ago)
///   * 20 patients seen 8 days ago, including Ramesh Kumar
Future<void> _seed(AppDatabase db) async {
  final now = DateTime.now();
  var seq = 0;

  Future<void> visit(String patientId, DateTime at) => db.upsertVisit(
    VisitsCompanion.insert(
      id: 'v${seq++}',
      patientId: patientId,
      createdAt: at,
    ),
  );

  Future<void> patient(String id, String name, DateTime at) => db.upsertPatient(
    PatientsCompanion.insert(
      id: id,
      name: name,
      createdAt: at,
      updatedAt: at,
      whatsappNumber: d.Value('9$id'),
    ),
  );

  for (var i = 0; i < 47; i++) {
    final at = now.subtract(Duration(minutes: i + 1));
    await patient('new$i', 'New Patient $i', at);
    await visit('new$i', at);
  }

  await patient(
    'sunita',
    'Sunita Devi',
    now.subtract(const Duration(days: 30)),
  );
  for (var i = 0; i < 3; i++) {
    await visit('sunita', now.subtract(Duration(minutes: 50 + i)));
  }
  for (var i = 0; i < 9; i++) {
    await visit('sunita', now.subtract(Duration(days: 3, minutes: i)));
  }

  for (var i = 0; i < 19; i++) {
    final at = now.subtract(Duration(days: 8, minutes: i));
    await patient('old$i', 'Old Patient $i', at);
    await visit('old$i', at);
  }
  final ramesh = now.subtract(const Duration(days: 8, minutes: 30));
  await patient('ramesh', 'Ramesh Kumar', ramesh);
  await visit('ramesh', ramesh);
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await _seed(db);
  });

  tearDown(() async => db.close());

  group('latestPerPatient', () {
    test('includes every patient, however old their last visit', () async {
      final rows = await VisitRepository(db).latestPerPatient();
      expect(rows, hasLength(68));
      expect(rows.map((r) => r.latestVisit.patientId), contains('ramesh'));
    });

    test('counts every visit a patient has had', () async {
      final rows = await VisitRepository(db).latestPerPatient();
      final sunita = rows.singleWhere(
        (r) => r.latestVisit.patientId == 'sunita',
      );
      expect(sunita.visitCount, 12);
    });

    test('reports each patient once, with their newest visit first', () async {
      final rows = await VisitRepository(db).latestPerPatient();
      final ids = rows.map((r) => r.latestVisit.patientId).toList();
      expect(ids.toSet(), hasLength(ids.length));
      expect(ids.first, 'new0');
      for (var i = 1; i < rows.length; i++) {
        expect(
          rows[i - 1].latestVisit.createdAt.isBefore(
            rows[i].latestVisit.createdAt,
          ),
          isFalse,
        );
      }
    });

    test(
      'a tie on the newest timestamp does not duplicate the patient',
      () async {
        final at = DateTime(2026, 1, 1, 9);
        await db.upsertPatient(
          PatientsCompanion.insert(
            id: 'tie',
            name: 'Tie Patient',
            createdAt: at,
            updatedAt: at,
          ),
        );
        for (final id in ['tie-a', 'tie-b']) {
          await db.upsertVisit(
            VisitsCompanion.insert(id: id, patientId: 'tie', createdAt: at),
          );
        }
        final rows = await VisitRepository(db).latestPerPatient();
        final tie = rows.where((r) => r.latestVisit.patientId == 'tie');
        expect(tie, hasLength(1));
        expect(tie.single.visitCount, 2);
      },
    );
  });

  testWidgets('searching the Patients tab finds a patient seen last week', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PatientsScreen(),
        ),
      ),
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    await tester.enterText(find.byType(TextField), 'Ramesh');
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Ramesh Kumar'), findsOneWidget);
  });
}
