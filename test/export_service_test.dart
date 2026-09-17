import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxvarta/data/db/app_database.dart';
import 'package:rxvarta/data/db/database_provider.dart';
import 'package:rxvarta/data/repositories/patient_repository.dart';
import 'package:rxvarta/domain/models/medical_insight.dart';
import 'package:rxvarta/domain/models/medication.dart';
import 'package:rxvarta/domain/models/patient.dart';
import 'package:rxvarta/domain/models/visit.dart';
import 'package:rxvarta/features/settings/data/export_service.dart';
import 'package:rxvarta/l10n/app_localizations.dart';

/// Strict RFC 4180 reader, to prove the CSV the export writes parses back to
/// exactly the values that went in.
List<List<String>> _parseCsv(String input) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;
  var pending = false;

  void endField() {
    row.add(field.toString());
    field.clear();
  }

  void endRow() {
    endField();
    rows.add(row);
    row = <String>[];
    pending = false;
  }

  for (var i = 0; i < input.length; i++) {
    final c = input[i];
    if (inQuotes) {
      if (c == '"' && i + 1 < input.length && input[i + 1] == '"') {
        field.write('"');
        i++;
      } else if (c == '"') {
        inQuotes = false;
      } else {
        field.write(c);
      }
      continue;
    }
    if (c == '"' && field.isEmpty) {
      inQuotes = true;
      pending = true;
    } else if (c == ',') {
      endField();
      pending = true;
    } else if (c == '\n') {
      endRow();
    } else {
      field.write(c);
      pending = true;
    }
  }
  if (pending || field.isNotEmpty || row.isNotEmpty) endRow();
  return rows;
}

String _withoutBom(String csv) =>
    csv.startsWith('\uFEFF') ? csv.substring(1) : csv;

final _at = DateTime(2026, 9, 17, 10);

PatientProfile _patient(String id, String name) => PatientProfile(
  id: id,
  name: name,
  age: 40,
  sex: Sex.female,
  createdAt: _at,
  updatedAt: _at,
);

void main() {
  group('CSV', () {
    test('values round trip through a strict RFC 4180 reader', () {
      const values = [
        'plain',
        'has,comma',
        'has"quote',
        '"',
        'line\nbreak',
        '  padded  ',
        'सुनीता देवी',
        "Dr. O'Brien, MBBS",
        '',
      ];
      final rows = _parseCsv(
        _withoutBom(
          toCsv([
            ['header'],
            for (final v in values) [v],
          ]),
        ),
      );
      expect(rows, [
        ['header'],
        for (final v in values) [v],
      ]);
    });

    test('dictated text never runs as a spreadsheet formula', () {
      for (final value in [
        '=HYPERLINK("http://x","click")',
        '+91 98765',
        '-5 kg',
        '@SUM(A1)',
        '\t=1+1',
      ]) {
        final cell = _parseCsv(
          _withoutBom(
            toCsv([
              [value],
            ]),
          ),
        ).single.single;
        expect(cell, "'$value", reason: '"$value" would be evaluated by Excel');
      }
    });

    test('starts with a UTF-8 byte order mark so Excel shows Hindi names', () {
      final bytes = utf8.encode(patientsCsv([_patient('p1', 'सुनीता देवी')]));
      expect(bytes.take(3), [0xEF, 0xBB, 0xBF]);
    });

    test('the medicines column keeps the meal timing', () {
      final visit = VisitRecord(
        id: 'v1',
        patientId: 'p1',
        createdAt: _at,
        insight: const MedicalInsight(
          medications: [
            Medication(
              name: 'Metformin',
              dosage: '500 mg',
              frequency: '1-0-1',
              duration: '30 days',
              timing: 'After food',
            ),
          ],
        ),
      );
      final rows = _parseCsv(
        _withoutBom(visitsCsv([visit], {'p1': _patient('p1', 'Asha')})),
      );
      expect(rows[1][4], 'Metformin 500 mg 1-0-1 30 days After food');
    });

    test('a visit whose patient is gone keeps the row shape', () {
      final visit = VisitRecord(id: 'v1', patientId: 'gone', createdAt: _at);
      final rows = _parseCsv(_withoutBom(visitsCsv([visit], const {})));
      expect(rows[1], hasLength(rows[0].length));
      expect(rows[1][1], '');
    });
  });

  testWidgets('the export progress dialog never closes the doctor’s screen', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final patients = _HangingPatientRepository(db);
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        patientRepositoryProvider.overrideWithValue(patients),
      ],
    );
    addTearDown(container.dispose);

    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: Text('home')),
        ),
      ),
    );
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('settings screen')),
      ),
    );
    await tester.pumpAndSettle();

    final export = container
        .read(exportServiceProvider)
        .exportAndShare(tester.element(find.text('settings screen')));
    await tester.pump();
    expect(find.text('Preparing your export…'), findsOneWidget);

    // Android back while the export runs. (The dialog's spinner never
    // settles, so pump a fixed time.)
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Preparing your export…'), findsOneWidget);
    expect(find.text('settings screen'), findsOneWidget);

    // The export ends (nothing to export).
    patients.completer.complete(const []);
    await export;
    await tester.pumpAndSettle();

    expect(find.text('Preparing your export…'), findsNothing);
    expect(find.text('settings screen'), findsOneWidget);
    expect(find.text('There is nothing to export yet.'), findsOneWidget);
  });
}

class _HangingPatientRepository extends PatientRepository {
  _HangingPatientRepository(super.db);

  final completer = Completer<List<PatientProfile>>();

  @override
  Future<List<PatientProfile>> recent({int limit = 20}) => completer.future;
}
