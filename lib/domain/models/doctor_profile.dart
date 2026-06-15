/// Prescribing doctor / clinic identity printed on the prescription letterhead
/// and signature block, and shown on the Settings screen. Persisted via
/// [DoctorProfileRepository] so the doctor can edit it once and have it flow to
/// every generated PDF.
///
/// Kept as a plain immutable class (no freezed/build_runner) so it stays simple
/// and dependency-free.
class DoctorProfile {
  const DoctorProfile({
    required this.name,
    required this.qualifications,
    required this.regNo,
    required this.clinicName,
    required this.clinicAddress,
    required this.clinicPhone,
  });

  final String name;
  final String qualifications;
  final String regNo;
  final String clinicName;
  final String clinicAddress;
  final String clinicPhone;

  static const defaultProfile = DoctorProfile(
    name: 'Dr. Rajesh Sharma',
    qualifications: 'MBBS, MD (Medicine)',
    regNo: 'MH-12345',
    clinicName: 'MediScribe Clinic',
    clinicAddress: 'Andheri West, Mumbai, Maharashtra 400053',
    clinicPhone: '+91 98765 43210',
  );

  DoctorProfile copyWith({
    String? name,
    String? qualifications,
    String? regNo,
    String? clinicName,
    String? clinicAddress,
    String? clinicPhone,
  }) {
    return DoctorProfile(
      name: name ?? this.name,
      qualifications: qualifications ?? this.qualifications,
      regNo: regNo ?? this.regNo,
      clinicName: clinicName ?? this.clinicName,
      clinicAddress: clinicAddress ?? this.clinicAddress,
      clinicPhone: clinicPhone ?? this.clinicPhone,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'qualifications': qualifications,
    'regNo': regNo,
    'clinicName': clinicName,
    'clinicAddress': clinicAddress,
    'clinicPhone': clinicPhone,
  };

  factory DoctorProfile.fromJson(Map<String, dynamic> json) {
    String s(String key, String fallback) {
      final v = json[key];
      return (v is String && v.trim().isNotEmpty) ? v : fallback;
    }

    const d = defaultProfile;
    return DoctorProfile(
      name: s('name', d.name),
      qualifications: s('qualifications', d.qualifications),
      regNo: s('regNo', d.regNo),
      clinicName: s('clinicName', d.clinicName),
      clinicAddress: s('clinicAddress', d.clinicAddress),
      clinicPhone: s('clinicPhone', d.clinicPhone),
    );
  }
}
