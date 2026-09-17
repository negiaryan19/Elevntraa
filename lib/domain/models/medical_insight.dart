import 'package:freezed_annotation/freezed_annotation.dart';

import 'json_coerce.dart';
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

  /// Tolerant of what a language model actually returns. A string where a
  /// list belongs, a numeric string for [followUpDays], or a medicine with no
  /// name used to throw and lose the entire recorded consultation; the map is
  /// now reshaped first so everything dictated survives.
  factory MedicalInsight.fromJson(Map<String, dynamic> json) =>
      _$MedicalInsightFromJson(normalizeInsightJson(json));

  static const empty = MedicalInsight();
}

extension MedicalInsightContent on MedicalInsight {
  /// True when the extraction holds anything the doctor said. A recording
  /// with no consultation in it (muted microphone, background noise) yields
  /// none of these, and must not be treated as a finished prescription.
  bool get hasClinicalContent =>
      consultationSummary.trim().isNotEmpty ||
      symptoms.isNotEmpty ||
      diagnosis.trim().isNotEmpty ||
      medications.isNotEmpty ||
      tests.isNotEmpty ||
      advice.isNotEmpty ||
      instructions.isNotEmpty ||
      followUpDays != null;
}

/// Reshapes an extraction map into the types the generated decoder casts to.
Map<String, dynamic> normalizeInsightJson(Map<String, dynamic> json) {
  final rawMeds = json['medications'];
  final List<Map<String, dynamic>> medications;
  if (rawMeds is List) {
    medications = [
      for (final item in rawMeds)
        // freezed's toJson() leaves nested Medication objects unconverted;
        // they must be kept, not mistaken for junk and dropped.
        if (item is Medication)
          normalizeMedicationJson(item.toJson())
        else if (coerceMap(item) case final map?)
          normalizeMedicationJson(map)
        else if (coerceOptionalString(item) case final name?)
          if (name.trim().isNotEmpty)
            normalizeMedicationJson({'name': name.trim()}),
    ];
  } else if (rawMeds is String) {
    // One string of medicines: keep each line as its own row for the doctor
    // to tidy up, rather than dropping what was prescribed.
    medications = [
      for (final name in coerceStringList(rawMeds))
        normalizeMedicationJson({'name': name}),
    ];
  } else {
    medications = const [];
  }

  return {
    ...json,
    'consultationSummary': coerceString(json['consultationSummary']),
    'symptoms': coerceStringList(json['symptoms']),
    'diagnosis': coerceString(json['diagnosis']),
    'differentials': coerceStringList(json['differentials']),
    'medications': medications,
    'tests': coerceStringList(json['tests']),
    'advice': coerceStringList(json['advice']),
    'instructions': coerceStringList(json['instructions']),
    'followUpDays': coerceOptionalInt(json['followUpDays']),
    'doctorNotes': coerceString(json['doctorNotes']),
    'icdCode': coerceOptionalString(json['icdCode']),
    'icdDescription': coerceOptionalString(json['icdDescription']),
    'icdConfidence': coerceOptionalString(json['icdConfidence']),
  };
}
