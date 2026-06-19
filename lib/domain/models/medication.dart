import 'package:freezed_annotation/freezed_annotation.dart';

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
  }) = _Medication;

  factory Medication.fromJson(Map<String, dynamic> json) =>
      _$MedicationFromJson(json);
}
