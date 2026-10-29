import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import '../../core/utils/app_paths.dart';

part 'app_database.g.dart';

/// Patients table. WhatsApp number is the primary contact channel for
/// sharing the prescription PDF.
class Patients extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get age => integer().nullable()();
  TextColumn get sex => text().nullable()(); // 'male' | 'female' | 'other'
  TextColumn get whatsappNumber => text().nullable()();
  TextColumn get phone => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Visit row. The structured prescription is stored as a JSON blob in
/// [insightJson]; that gives us schema flexibility while drift still gives
/// us indexed search on patient + date.
class Visits extends Table {
  TextColumn get id => text()();
  TextColumn get patientId =>
      text().references(Patients, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get createdAt => dateTime()();

  /// Audio file path on device (may be null if user opted to auto-delete).
  TextColumn get audioPath => text().nullable()();

  /// Raw transcript from the STT engine.
  TextColumn get transcript => text().nullable()();

  /// Language hint used for transcription, e.g. 'or-IN' or 'unknown'.
  TextColumn get languageCode =>
      text().withDefault(const Constant('unknown'))();

  /// Structured MedicalInsight encoded as JSON.
  TextColumn get insightJson => text().nullable()();

  /// Attached previous-report images (list of {path, caption}) encoded as JSON.
  TextColumn get attachmentsJson => text().nullable()();

  /// PDF path on device once generated and signed.
  TextColumn get pdfPath => text().nullable()();

  /// Hard signature gate — Share is disabled until this is true.
  BoolColumn get signed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get signedAt => dateTime().nullable()();

  /// DPDP consent — must be true before recording.
  BoolColumn get patientConsent =>
      boolean().withDefault(const Constant(false))();

  /// Where a consultation recorded without internet stands: `queued` (waiting
  /// to be processed), `ready` (processed, not opened yet) or `failed`
  /// (processing cannot succeed; see [pendingError]). Null for every visit
  /// that was processed straight away. Kept on the visit, in the doctor's own
  /// database, so it survives a restart and never crosses doctors.
  TextColumn get pendingState => text().nullable()();

  /// Why a queued consultation ended up `failed` (a FailureCode name).
  TextColumn get pendingError => text().nullable()();
  DateTimeColumn get consentAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Patients, Visits])
class AppDatabase extends _$AppDatabase {
  /// The signed-in doctor's own database, `users/<uid>/rxvarta.sqlite`.
  AppDatabase.forDoctor(String uid) : super(_openConnection(uid));

  /// Nobody is signed in: an empty database in memory, so no doctor's
  /// records are readable and nothing is written to disk.
  AppDatabase.signedOut() : super(NativeDatabase.memory());

  /// Construct against a custom executor — used in tests.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // v2: store attached previous-report images on the visit.
      if (from < 2) {
        await m.addColumn(visits, visits.attachmentsJson);
      }
      // v3: consultations recorded offline wait in a queue on the visit row.
      if (from < 3) {
        await m.addColumn(visits, visits.pendingState);
        await m.addColumn(visits, visits.pendingError);
      }
    },
  );

  // ── Patients ────────────────────────────────────────────────────────
  Future<List<Patient>> recentPatients({int limit = 20}) {
    return (select(patients)
          ..orderBy([(p) => OrderingTerm.desc(p.updatedAt)])
          ..limit(limit))
        .get();
  }

  /// Live version of [recentPatients]: re-runs whenever a patient or visit
  /// row changes, so a screen showing it never goes stale.
  Stream<List<Patient>> watchRecentPatients({int limit = 20}) {
    return (select(patients)
          ..orderBy([(p) => OrderingTerm.desc(p.updatedAt)])
          ..limit(limit))
        .watch();
  }

  Future<List<Patient>> searchPatients(String query) {
    final q = '%${query.trim()}%';
    return (select(patients)
          ..where(
            (p) => p.name.like(q) | p.phone.like(q) | p.whatsappNumber.like(q),
          )
          ..orderBy([(p) => OrderingTerm.desc(p.updatedAt)])
          ..limit(50))
        .get();
  }

  Future<Patient?> patientById(String id) {
    return (select(patients)..where((p) => p.id.equals(id))).getSingleOrNull();
  }

  /// Patients whose WhatsApp number matches exactly — used to detect a
  /// returning patient before creating a duplicate record.
  Future<List<Patient>> patientsByWhatsapp(String number) {
    return (select(
      patients,
    )..where((p) => p.whatsappNumber.equals(number))).get();
  }

  Future<void> upsertPatient(PatientsCompanion row) {
    return into(patients).insertOnConflictUpdate(row);
  }

  // ── Visits ──────────────────────────────────────────────────────────
  Future<List<Visit>> visitsForPatient(String patientId) {
    return (select(visits)
          ..where((v) => v.patientId.equals(patientId))
          ..orderBy([(v) => OrderingTerm.desc(v.createdAt)]))
        .get();
  }

  Future<Visit?> visitById(String id) {
    return (select(visits)..where((v) => v.id.equals(id))).getSingleOrNull();
  }

  /// Visits with a pending state, oldest first: the order they are
  /// processed in.
  Future<List<Visit>> pendingVisits() {
    return (select(visits)
          ..where((v) => v.pendingState.isNotNull())
          ..orderBy([(v) => OrderingTerm.asc(v.createdAt)]))
        .get();
  }

  /// Live version of [pendingVisits].
  Stream<List<Visit>> watchPendingVisits() {
    return (select(visits)
          ..where((v) => v.pendingState.isNotNull())
          ..orderBy([(v) => OrderingTerm.asc(v.createdAt)]))
        .watch();
  }

  Future<void> upsertVisit(VisitsCompanion row) {
    return into(visits).insertOnConflictUpdate(row);
  }

  Future<List<Visit>> recentVisits({int limit = 30}) {
    return (select(visits)
          ..orderBy([(v) => OrderingTerm.desc(v.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Every patient that has at least one visit, with their newest visit and
  /// their total number of visits, newest first. One query for the whole
  /// clinic, so nobody drops off the list however many consultations there
  /// have been.
  Future<List<({Visit latest, int count})>> latestVisitPerPatient() async {
    final rows = await customSelect(
      'SELECT v.*, s.visit_count AS visit_count '
      'FROM visits v '
      'JOIN (SELECT patient_id, MAX(created_at) AS last_at, '
      '             COUNT(*) AS visit_count '
      '      FROM visits GROUP BY patient_id) s '
      '  ON s.patient_id = v.patient_id AND s.last_at = v.created_at '
      'ORDER BY v.created_at DESC',
      readsFrom: {visits},
    ).get();

    final seen = <String>{};
    final result = <({Visit latest, int count})>[];
    for (final row in rows) {
      final visit = visits.map(row.data);
      // Two visits can share the newest timestamp; list the patient once.
      if (!seen.add(visit.patientId)) continue;
      result.add((latest: visit, count: row.read<int>('visit_count')));
    }
    return result;
  }

  Future<List<Patient>> patientsByIds(Iterable<String> ids) {
    final list = ids.toSet().toList();
    if (list.isEmpty) return Future.value(const []);
    return (select(patients)..where((p) => p.id.isIn(list))).get();
  }
}

LazyDatabase _openConnection(String uid) {
  return LazyDatabase(() async {
    // A phone upgraded from a build with one shared database keeps its
    // records: they move into the first signed-in doctor's folder.
    await AppPaths.claimSharedData(uid);
    return NativeDatabase.createInBackground(File(AppPaths.databasePath(uid)));
  });
}
