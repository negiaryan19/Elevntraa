import 'package:freezed_annotation/freezed_annotation.dart';

import 'medical_insight.dart';
import 'report_attachment.dart';

part 'visit.freezed.dart';
part 'visit.g.dart';

@freezed
abstract class VisitRecord with _$VisitRecord {
  const factory VisitRecord({
    required String id,
    required String patientId,
    required DateTime createdAt,
    String? audioPath,
    String? transcript,
    @Default('unknown') String languageCode,
    MedicalInsight? insight,
    @Default([]) List<ReportAttachment> attachments,
    String? pdfPath,
    @Default(false) bool signed,
    DateTime? signedAt,
    @Default(false) bool patientConsent,
    DateTime? consentAt,
  }) = _VisitRecord;

  factory VisitRecord.fromJson(Map<String, dynamic> json) =>
      _$VisitRecordFromJson(json);
}
