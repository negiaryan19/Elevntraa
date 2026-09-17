import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxvarta/data/db/app_database.dart';
import 'package:rxvarta/data/db/database_provider.dart';
import 'package:rxvarta/data/repositories/patient_repository.dart';
import 'package:rxvarta/domain/models/patient.dart';
import 'package:rxvarta/features/patient/presentation/existing_patient_screen.dart';
import 'package:rxvarta/l10n/app_localizations.dart';

/// "Find patient" queried the database on every keystroke, and a slow early
/// query could land after a later one and show the wrong list (roadmap item
/// 31). Home's recent patients only refreshed on pull-to-refresh, so a
/// finished consultation did not appear (item 32).
class _CountingPatientRepository extends PatientRepository {
  _CountingPatientRepository(super.db);

  final queries = <String>[];
  final _pending = <String, Completer<List<PatientProfile>>>{};

  PatientProfile _patient(String name) => PatientProfile(
    id: name,
    name: name,
    createdAt: DateTime(2026, 9, 17),
    updatedAt: DateTime(2026, 9, 17),
  );

  @override
  Future<List<PatientProfile>> recent({int limit = 20}) async {
    queries.add('');
    return [_patient('Recent patient')];
  }

  @override
  Future<List<PatientProfile>> search(String query) {
    queries.add(query);
    final completer = Completer<List<PatientProfile>>();
    _pending[query] = completer;
    return completer.future;
  }

  void answer(String query) =>
      _pending.remove(query)!.complete([_patient('Result for $query')]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('patient search', () {
    late AppDatabase db;
    late _CountingPatientRepository repo;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = _CountingPatientRepository(db);
    });
    tearDown(() async => db.close());

    Future<void> pumpSearch(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            patientRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ExistingPatientScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('a name typed letter by letter is one query, not one per '
        'keystroke', (tester) async {
      await pumpSearch(tester);
      expect(repo.queries, ['']); // the initial recent list

      for (final text in ['R', 'Ra', 'Ram', 'Rame', 'Ramesh']) {
        await tester.enterText(find.byType(TextField), text);
        await tester.pump(const Duration(milliseconds: 60));
      }
      await tester.pump(const Duration(milliseconds: 400));

      expect(repo.queries, ['', 'Ramesh']);
      repo.answer('Ramesh');
      await tester.pump();
      expect(find.text('Result for Ramesh'), findsOneWidget);
    });

    testWidgets('a slow earlier search cannot replace a later one', (
      tester,
    ) async {
      await pumpSearch(tester);

      await tester.enterText(find.byType(TextField), 'Asha');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.enterText(find.byType(TextField), 'Bharat');
      await tester.pump(const Duration(milliseconds: 400));
      expect(repo.queries, ['', 'Asha', 'Bharat']);

      // The second search answers first, then the first one arrives late.
      repo.answer('Bharat');
      await tester.pump();
      repo.answer('Asha');
      await tester.pump();

      expect(find.text('Result for Bharat'), findsOneWidget);
      expect(find.text('Result for Asha'), findsNothing);
    });
  });

  test('the recent-patient list follows the database', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = PatientRepository(db);
    final seen = <List<String>>[];
    final sub = repo
        .watchRecent(limit: 5)
        .listen((list) => seen.add(list.map((p) => p.name).toList()));

    await pumpEventQueue();
    await repo.upsert(
      PatientProfile(
        id: 'p1',
        name: 'Sunita Devi',
        createdAt: DateTime(2026, 9, 17),
        updatedAt: DateTime(2026, 9, 17),
      ),
    );
    await pumpEventQueue();
    await sub.cancel();

    expect(seen.first, isEmpty);
    expect(seen.last, ['Sunita Devi']);
  });
}
