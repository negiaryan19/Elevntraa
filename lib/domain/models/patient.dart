import 'package:freezed_annotation/freezed_annotation.dart';

part 'patient.freezed.dart';
part 'patient.g.dart';

enum Sex { male, female, other }

@freezed
abstract class PatientProfile with _$PatientProfile {
  const factory PatientProfile({
    required String id,
    required String name,
    int? age,
    Sex? sex,
    String? whatsappNumber,
    String? phone,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _PatientProfile;

  factory PatientProfile.fromJson(Map<String, dynamic> json) =>
      _$PatientProfileFromJson(json);
}
