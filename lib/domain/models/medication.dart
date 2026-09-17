import 'package:freezed_annotation/freezed_annotation.dart';

import 'json_coerce.dart';

part 'medication.freezed.dart';
part 'medication.g.dart';

@freezed
abstract class Medication with _$Medication {
  const factory Medication({
    required String name,
    @Default('') String dosage,
    @Default('') String frequency,
    @Default('') String duration,

    /// When to take relative to meals — "Before food", "After food",
    /// "With food", or empty when unspecified. Set by the doctor via the
    /// timing chips on the review screen.
    @Default('') String timing,

    /// Set by the LLM extractor when this medication line was uncertain.
    /// Surfaces a [needs review] chip in the UI.
    @Default(false) bool needsReview,

    /// Original name as spoken/transcribed before on-device correction.
    /// Null when no correction was applied. For audit only — never shown
    /// on the prescription PDF.
    String? originalName,
  }) = _Medication;

  /// Tolerant of what a language model actually returns: a missing or
  /// numeric field is coerced rather than thrown on, because a throw here
  /// used to discard the whole consultation. See [coerceString].
  factory Medication.fromJson(Map<String, dynamic> json) =>
      _$MedicationFromJson(normalizeMedicationJson(json));
}

/// Reshapes one medication map into the types the generated decoder casts to.
Map<String, dynamic> normalizeMedicationJson(Map<String, dynamic> json) => {
  ...json,
  'name': coerceString(json['name']),
  'dosage': coerceString(json['dosage']),
  'frequency': coerceString(json['frequency']),
  'duration': coerceString(json['duration']),
  'timing': coerceString(json['timing']),
  'needsReview': coerceBool(json['needsReview']),
  'originalName': coerceOptionalString(json['originalName']),
};
