import 'package:freezed_annotation/freezed_annotation.dart';

import 'medication.dart';

part 'medical_insight.freezed.dart';
part 'medical_insight.g.dart';

/// Structured prescription extracted from the doctor's dictation. The
/// extractor MUST NOT invent fields — see the Gemini system instructions in
/// the backend pipeline (supabase/functions/_shared/pipeline.ts). Empty lists /
/// null fields are valid and expected.
@freezed
abstract class MedicalInsight with _$MedicalInsight {
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
    String? icdCode,
    String? icdDescription,

    /// "high" or "medium". Null when absent or after doctor manually edits.
    String? icdConfidence,
  }) = _MedicalInsight;

  factory MedicalInsight.fromJson(Map<String, dynamic> json) =>
      _$MedicalInsightFromJson(json);

  static const empty = MedicalInsight();
}
