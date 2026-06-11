import 'package:freezed_annotation/freezed_annotation.dart';

import 'medication.dart';

part 'medical_insight.freezed.dart';
part 'medical_insight.g.dart';

/// Structured prescription extracted from the doctor's dictation. The
/// extractor MUST NOT invent fields — see system_instruction in
/// insight_service.dart. Empty lists / null fields are valid and expected.
@freezed
class MedicalInsight with _$MedicalInsight {
  const factory MedicalInsight({
    @Default('') String consultationSummary,
    @Default([]) List<String> symptoms,
    @Default('') String diagnosis,
    @Default([]) List<String> differentials,
    @Default([]) List<Medication> medications,
    @Default([]) List<String> tests,
    /// General health guidance (rest, diet, hydration, lifestyle) — not tied
    /// to a specific medicine. Doctor's words only.
    @Default([]) List<String> advice,
    /// Specific actionable directions the patient must follow (how/when to take
    /// medicines, precautions, warning signs, when to return). Doctor's words only.
    @Default([]) List<String> instructions,
    int? followUpDays,
    @Default('') String doctorNotes,
  }) = _MedicalInsight;

  factory MedicalInsight.fromJson(Map<String, dynamic> json) =>
      _$MedicalInsightFromJson(json);

  static const empty = MedicalInsight();
}
