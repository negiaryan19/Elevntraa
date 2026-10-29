import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:rxvarta/data/db/app_database.dart';
import 'package:rxvarta/data/repositories/visit_repository.dart';
import 'package:rxvarta/domain/models/visit.dart';

/// Schema v3 adds `pending_state` / `pending_error` to visits (the offline
/// queue). Every doctor already using the app has a v2 database file, so the
/// upgrade must add the columns and leave their records exactly as they were.
void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('rx_migrate_'));
  tearDown(() => tmp.deleteSync(recursive: true));

  test('a v2 database upgrades to v3 and keeps its visits', () async {
    final file = File(p.join(tmp.path, 'rxvarta.sqlite'));

    // Create the file with today's schema, then close it.
    var db = AppDatabase.forTesting(NativeDatabase(file));
    await db.customSelect('select 1').get();
    await db.close();

    // Reopen it cut back to the v2 shape, with a doctor's existing records in
    // it. `setup` runs on the raw connection before drift reads user_version,
    // so drift then sees a genuine v2 file and runs onUpgrade(2 -> 3).
    db = AppDatabase.forTesting(
      NativeDatabase(
        file,
        setup: (raw) {
          raw.execute('ALTER TABLE visits DROP COLUMN pending_state');
          raw.execute('ALTER TABLE visits DROP COLUMN pending_error');
          raw.execute(
            "INSERT INTO patients (id, name, created_at, updated_at) "
            "VALUES ('p1', 'Sunita Devi', 1756700000, 1756700000)",
          );
          raw.execute(
            "INSERT INTO visits (id, patient_id, created_at, transcript, "
            "language_code, signed, patient_consent) "
            "VALUES ('v1', 'p1', 1756700000, 'Doctor: viral fever.', 'hi-IN', "
            "1, 1)",
          );
          raw.execute('PRAGMA user_version = 2');
        },
      ),
    );
    addTearDown(db.close);

    final columns = await db
        .customSelect("select name from pragma_table_info('visits')")
        .get();
    final names = columns.map((r) => r.read<String>('name')).toSet();
    expect(names, containsAll(['pending_state', 'pending_error']));

    final visit = (await VisitRepository(db).byId('v1'))!;
    expect(visit.transcript, 'Doctor: viral fever.');
    expect(visit.languageCode, 'hi-IN');
    expect(visit.signed, isTrue);
    expect(visit.pendingState, isNull, reason: 'old visits are not pending');
    expect(await VisitRepository(db).pending(), isEmpty);
  });

  test('pending state round-trips, oldest first', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = VisitRepository(db);
    final t0 = DateTime(2026, 9, 22, 9);
    await db.customStatement(
      "INSERT INTO patients (id, name, created_at, updated_at) "
      "VALUES ('p1', 'A', 0, 0)",
    );
    await repo.upsert(VisitRecord(id: 'done', patientId: 'p1', createdAt: t0));
    await repo.upsert(
      VisitRecord(
        id: 'late',
        patientId: 'p1',
        createdAt: t0.add(const Duration(hours: 2)),
        pendingState: PendingState.queued,
      ),
    );
    await repo.upsert(
      VisitRecord(
        id: 'early',
        patientId: 'p1',
        createdAt: t0.add(const Duration(hours: 1)),
        pendingState: PendingState.failed,
        pendingError: 'invalidAudio',
      ),
    );

    final pending = await repo.pending();
    expect(pending.map((v) => v.id), ['early', 'late']);
    expect(pending.first.pendingState, PendingState.failed);
    expect(pending.first.pendingError, 'invalidAudio');
  });

  test('an unknown pending value reads as not pending', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.customStatement(
      "INSERT INTO patients (id, name, created_at, updated_at) "
      "VALUES ('p1', 'A', 0, 0)",
    );
    await db.customStatement(
      "INSERT INTO visits (id, patient_id, created_at, pending_state) "
      "VALUES ('v1', 'p1', 0, 'some_future_state')",
    );
    expect((await VisitRepository(db).byId('v1'))!.pendingState, isNull);
  });
}
