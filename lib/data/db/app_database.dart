import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
  TextColumn get languageCode => text().withDefault(const Constant('unknown'))();

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
  BoolColumn get patientConsent => boolean().withDefault(const Constant(false))();
  DateTimeColumn get consentAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Patients, Visits])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Construct against a custom executor — used in tests.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // v2: store attached previous-report images on the visit.
          if (from < 2) {
            await m.addColumn(visits, visits.attachmentsJson);
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

  Future<List<Patient>> searchPatients(String query) {
    final q = '%${query.trim()}%';
    return (select(patients)
          ..where((p) => p.name.like(q) | p.phone.like(q) | p.whatsappNumber.like(q))
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
    return (select(patients)..where((p) => p.whatsappNumber.equals(number)))
        .get();
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

  Future<void> upsertVisit(VisitsCompanion row) {
    return into(visits).insertOnConflictUpdate(row);
  }

  Future<List<Visit>> recentVisits({int limit = 30}) {
    return (select(visits)
          ..orderBy([(v) => OrderingTerm.desc(v.createdAt)])
          ..limit(limit))
        .get();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'medscribe.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
