import 'package:freezed_annotation/freezed_annotation.dart';

part 'medication.freezed.dart';
part 'medication.g.dart';

@freezed
class Medication with _$Medication {
  const factory Medication({
    required String name,
    @Default('') String dosage,
    @Default('') String frequency,
    @Default('') String duration,
    /// Set by the LLM extractor when this medication line was uncertain.
    /// Surfaces a [needs review] chip in the UI.
    @Default(false) bool needsReview,
  }) = _Medication;

  factory Medication.fromJson(Map<String, dynamic> json) =>
      _$MedicationFromJson(json);
}
