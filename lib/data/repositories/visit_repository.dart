import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/medical_insight.dart';
import '../../domain/models/report_attachment.dart';
import '../../domain/models/visit.dart';
import '../db/app_database.dart';
import '../db/database_provider.dart';

class VisitRepository {
  VisitRepository(this._db);

  final AppDatabase _db;

  Future<VisitRecord?> byId(String id) async {
    final row = await _db.visitById(id);
    return row == null ? null : _toRecord(row);
  }

  Future<List<VisitRecord>> forPatient(String patientId) async {
    final rows = await _db.visitsForPatient(patientId);
    return rows.map(_toRecord).toList();
  }

  Future<List<VisitRecord>> recent({int limit = 30}) async {
    final rows = await _db.recentVisits(limit: limit);
    return rows.map(_toRecord).toList();
  }

  Future<void> upsert(VisitRecord v) {
    return _db.upsertVisit(VisitsCompanion(
      id: Value(v.id),
      patientId: Value(v.patientId),
      createdAt: Value(v.createdAt),
      audioPath: Value(v.audioPath),
      transcript: Value(v.transcript),
      languageCode: Value(v.languageCode),
      insightJson:
          Value(v.insight == null ? null : jsonEncode(v.insight!.toJson())),
      attachmentsJson: Value(v.attachments.isEmpty
          ? null
          : jsonEncode(v.attachments.map((a) => a.toJson()).toList())),
      pdfPath: Value(v.pdfPath),
      signed: Value(v.signed),
      signedAt: Value(v.signedAt),
      patientConsent: Value(v.patientConsent),
      consentAt: Value(v.consentAt),
    ));
  }

  VisitRecord _toRecord(Visit row) {
    MedicalInsight? insight;
    final raw = row.insightJson;
    if (raw != null && raw.isNotEmpty) {
      try {
        insight = MedicalInsight.fromJson(
            jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        insight = null;
      }
    }

    var attachments = const <ReportAttachment>[];
    final rawAtt = row.attachmentsJson;
    if (rawAtt != null && rawAtt.isNotEmpty) {
      try {
        attachments = (jsonDecode(rawAtt) as List)
            .map((e) => ReportAttachment.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        attachments = const [];
      }
    }

    return VisitRecord(
      id: row.id,
      patientId: row.patientId,
      createdAt: row.createdAt,
      audioPath: row.audioPath,
      transcript: row.transcript,
      languageCode: row.languageCode,
      insight: insight,
      attachments: attachments,
      pdfPath: row.pdfPath,
      signed: row.signed,
      signedAt: row.signedAt,
      patientConsent: row.patientConsent,
      consentAt: row.consentAt,
    );
  }
}

final visitRepositoryProvider = Provider<VisitRepository>((ref) {
  return VisitRepository(ref.watch(appDatabaseProvider));
});
