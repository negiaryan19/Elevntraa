import 'package:freezed_annotation/freezed_annotation.dart';

import 'medical_insight.dart';
import 'report_attachment.dart';

part 'visit.freezed.dart';
part 'visit.g.dart';

/// Where a consultation that could not be processed straight away stands.
enum PendingState {
  /// Recorded, waiting for a connection to be processed.
  queued,

  /// Processed in the background; the doctor has not opened it yet.
  ready,

  /// Processing cannot succeed (nothing was heard, the recording is gone…).
  failed,
}

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

    /// Null for a visit that was processed straight away.
    PendingState? pendingState,

    /// A FailureCode name, set with [PendingState.failed].
    String? pendingError,
  }) = _VisitRecord;

  factory VisitRecord.fromJson(Map<String, dynamic> json) =>
      _$VisitRecordFromJson(json);
}
