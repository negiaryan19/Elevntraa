/// Prescribing doctor / clinic identity printed on the prescription letterhead
/// and signature block, and shown on the Settings screen.
///
/// There is deliberately NO default/sample profile any more: a prescription
/// must never carry a name or registration number the doctor did not enter
/// (roadmap item 5). An incomplete profile blocks signing (see [isComplete]).
///
/// Kept as a plain immutable class (no freezed/build_runner) so it stays simple
/// and dependency-free. The signature image itself lives on disk next to the
/// doctor's other data (`AppPaths.userDir(uid)/<signatureFileName>`) and in
/// the private `doctor-signatures` bucket; the model only records that it
/// exists and when it last changed so devices can decide which copy is newer.
class DoctorProfile {
  const DoctorProfile({
    this.name = '',
    this.qualifications = '',
    this.regNo = '',
    this.clinicName = '',
    this.clinicAddress = '',
    this.clinicPhone = '',
    this.phone = '',
    this.signatureFileName,
    this.signatureUpdatedAt,
    this.updatedAt,
    this.onboardingCompletedAt,
  });

  static const empty = DoctorProfile();

  /// File name (relative to the doctor's data directory) of the signature
  /// PNG, or null when no signature has been captured yet.
  static const defaultSignatureFileName = 'signature.png';

  final String name;
  final String qualifications;
  final String regNo;
  final String clinicName;
  final String clinicAddress;
  final String clinicPhone;

  /// Doctor's own mobile number (distinct from the clinic landline).
  final String phone;

  final String? signatureFileName;
  final DateTime? signatureUpdatedAt;

  /// Last modification of any text field; drives local-vs-remote merging.
  final DateTime? updatedAt;

  /// Set once the doctor finishes onboarding; the router sends doctors without
  /// it (or with an incomplete profile) back to onboarding.
  final DateTime? onboardingCompletedAt;

  bool get hasSignature =>
      signatureFileName != null && signatureFileName!.trim().isNotEmpty;

  /// Fields the doctor still has to fill before prescriptions can be signed.
  /// Everything a prescription must legally carry in India — the
  /// practitioner's name, qualification, registration number, practice name
  /// and address (NMC Ethics Regulations; Drugs & Cosmetics Rules, Rule 65) —
  /// plus a contact number and a real signature. Only the clinic landline is
  /// optional.
  List<DoctorProfileField> get missingFields => [
    if (name.trim().isEmpty) DoctorProfileField.name,
    if (qualifications.trim().isEmpty) DoctorProfileField.qualifications,
    if (regNo.trim().isEmpty) DoctorProfileField.regNo,
    if (clinicName.trim().isEmpty) DoctorProfileField.clinicName,
    if (clinicAddress.trim().isEmpty) DoctorProfileField.clinicAddress,
    if (phone.trim().isEmpty) DoctorProfileField.phone,
    if (!hasSignature) DoctorProfileField.signature,
  ];

  bool get isComplete => missingFields.isEmpty;

  /// True when nothing has been entered at all (fresh account).
  bool get isBlank =>
      name.trim().isEmpty &&
      qualifications.trim().isEmpty &&
      regNo.trim().isEmpty &&
      clinicName.trim().isEmpty &&
      clinicAddress.trim().isEmpty &&
      clinicPhone.trim().isEmpty &&
      phone.trim().isEmpty &&
      !hasSignature;

  DoctorProfile copyWith({
    String? name,
    String? qualifications,
    String? regNo,
    String? clinicName,
    String? clinicAddress,
    String? clinicPhone,
    String? phone,
    Object? signatureFileName = _unset,
    Object? signatureUpdatedAt = _unset,
    Object? updatedAt = _unset,
    Object? onboardingCompletedAt = _unset,
  }) {
    return DoctorProfile(
      name: name ?? this.name,
      qualifications: qualifications ?? this.qualifications,
      regNo: regNo ?? this.regNo,
      clinicName: clinicName ?? this.clinicName,
      clinicAddress: clinicAddress ?? this.clinicAddress,
      clinicPhone: clinicPhone ?? this.clinicPhone,
      phone: phone ?? this.phone,
      signatureFileName: signatureFileName == _unset
          ? this.signatureFileName
          : signatureFileName as String?,
      signatureUpdatedAt: signatureUpdatedAt == _unset
          ? this.signatureUpdatedAt
          : signatureUpdatedAt as DateTime?,
      updatedAt: updatedAt == _unset ? this.updatedAt : updatedAt as DateTime?,
      onboardingCompletedAt: onboardingCompletedAt == _unset
          ? this.onboardingCompletedAt
          : onboardingCompletedAt as DateTime?,
    );
  }

  static const Object _unset = Object();

  // ── Local cache JSON (documents/users/<uid>/doctor_profile.json) ──────

  Map<String, dynamic> toJson() => {
    'name': name,
    'qualifications': qualifications,
    'regNo': regNo,
    'clinicName': clinicName,
    'clinicAddress': clinicAddress,
    'clinicPhone': clinicPhone,
    'phone': phone,
    'signatureFileName': signatureFileName,
    'signatureUpdatedAt': signatureUpdatedAt?.toUtc().toIso8601String(),
    'updatedAt': updatedAt?.toUtc().toIso8601String(),
    'onboardingCompletedAt': onboardingCompletedAt?.toUtc().toIso8601String(),
  };

  /// Blank fields stay blank.
  ///
  /// Earlier builds shipped a hard-coded sample doctor ("Dr. Rajesh Sharma"
  /// / "MH-12345"). A cache still holding it is discarded so it can never
  /// reach a real prescription — but only when the whole thing is that
  /// sample, identified by its name AND registration number together.
  /// Matching field by field would erase real data: "MBBS, MD (Medicine)"
  /// was one of the sample values and is one of the commonest
  /// qualifications in India.
  factory DoctorProfile.fromJson(Map<String, dynamic> json) {
    final legacy = _isLegacySampleProfile(json);

    String s(String key) {
      if (legacy) return '';
      final v = json[key];
      return v is String ? v.trim() : '';
    }

    return DoctorProfile(
      name: s('name'),
      qualifications: s('qualifications'),
      regNo: s('regNo'),
      clinicName: s('clinicName'),
      clinicAddress: s('clinicAddress'),
      clinicPhone: s('clinicPhone'),
      phone: s('phone'),
      signatureFileName: _optString(json['signatureFileName']),
      signatureUpdatedAt: _parseDate(json['signatureUpdatedAt']),
      updatedAt: _parseDate(json['updatedAt']),
      onboardingCompletedAt: _parseDate(json['onboardingCompletedAt']),
    );
  }

  // ── Supabase `public.doctors` row ─────────────────────────────────────

  /// Column map for `public.doctors` (id is added by the repository).
  Map<String, dynamic> toRemoteJson() => {
    'full_name': name,
    'qualifications': qualifications,
    'registration_number': regNo,
    'clinic_name': clinicName,
    'clinic_address': clinicAddress,
    'clinic_phone': clinicPhone,
    'phone': phone,
    'signature_updated_at': signatureUpdatedAt?.toUtc().toIso8601String(),
    'updated_at': (updatedAt ?? DateTime.now()).toUtc().toIso8601String(),
    'onboarding_completed_at': onboardingCompletedAt?.toUtc().toIso8601String(),
  };

  /// [signatureFileName] is a LOCAL concept; the repository passes the local
  /// file name it downloaded the remote signature to (or null).
  factory DoctorProfile.fromRemoteJson(
    Map<String, dynamic> row, {
    String? signatureFileName,
  }) {
    String s(String key) {
      final v = row[key];
      return v is String ? v.trim() : '';
    }

    return DoctorProfile(
      name: s('full_name'),
      qualifications: s('qualifications'),
      regNo: s('registration_number'),
      clinicName: s('clinic_name'),
      clinicAddress: s('clinic_address'),
      clinicPhone: s('clinic_phone'),
      phone: s('phone'),
      signatureFileName: signatureFileName,
      signatureUpdatedAt: _parseDate(row['signature_updated_at']),
      updatedAt: _parseDate(row['updated_at']),
      onboardingCompletedAt: _parseDate(row['onboarding_completed_at']),
    );
  }

  static String? _optString(Object? v) {
    if (v is! String) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  static DateTime? _parseDate(Object? v) {
    if (v is! String || v.isEmpty) return null;
    return DateTime.tryParse(v)?.toLocal();
  }

  /// The identity of the sample doctor that earlier builds hard-coded. Both
  /// must match for a cached profile to be treated as the sample: either one
  /// alone could plausibly belong to a real doctor.
  static const _legacySampleName = 'Dr. Rajesh Sharma';
  static const _legacySampleRegNo = 'MH-12345';

  static bool _isLegacySampleProfile(Map<String, dynamic> json) {
    final name = json['name'];
    final regNo = json['regNo'];
    return name is String &&
        regNo is String &&
        name.trim() == _legacySampleName &&
        regNo.trim() == _legacySampleRegNo;
  }

  @override
  bool operator ==(Object other) =>
      other is DoctorProfile &&
      other.name == name &&
      other.qualifications == qualifications &&
      other.regNo == regNo &&
      other.clinicName == clinicName &&
      other.clinicAddress == clinicAddress &&
      other.clinicPhone == clinicPhone &&
      other.phone == phone &&
      other.signatureFileName == signatureFileName &&
      other.signatureUpdatedAt == signatureUpdatedAt &&
      other.updatedAt == updatedAt &&
      other.onboardingCompletedAt == onboardingCompletedAt;

  @override
  int get hashCode => Object.hash(
    name,
    qualifications,
    regNo,
    clinicName,
    clinicAddress,
    clinicPhone,
    phone,
    signatureFileName,
    signatureUpdatedAt,
    updatedAt,
    onboardingCompletedAt,
  );
}

/// Profile fields, used to report what is still missing before signing.
enum DoctorProfileField {
  name,
  qualifications,
  regNo,
  clinicName,
  clinicAddress,
  phone,
  signature,
}
