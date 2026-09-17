import 'package:flutter_test/flutter_test.dart';
import 'package:rxvarta/domain/models/doctor_profile.dart';

void main() {
  const complete = DoctorProfile(
    name: 'Dr. Asha Verma',
    qualifications: 'MBBS, MD',
    regNo: 'KA-98765',
    clinicName: 'Verma Clinic',
    clinicAddress: '12 MG Road, Bengaluru 560001',
    phone: '9876543210',
    signatureFileName: 'signature.png',
  );

  group('DoctorProfile.fromJson legacy scrubbing', () {
    test('every legacy sample value becomes blank', () {
      final profile = DoctorProfile.fromJson({
        'name': 'Dr. Rajesh Sharma',
        'qualifications': 'MBBS, MD (Medicine)',
        'regNo': 'MH-12345',
        'clinicName': 'Rxvarta Clinic',
        'clinicAddress': 'Andheri West, Mumbai, Maharashtra 400053',
        'clinicPhone': '+91 98765 43210',
        'phone': '+91 98765 43210',
      });
      expect(profile.name, '');
      expect(profile.qualifications, '');
      expect(profile.regNo, '');
      expect(profile.clinicName, '');
      expect(profile.clinicAddress, '');
      expect(profile.clinicPhone, '');
      expect(profile.phone, '');
      expect(profile.isBlank, isTrue);
      expect(profile.isComplete, isFalse);
    });

    test('legacy values are scrubbed even with surrounding whitespace', () {
      final profile = DoctorProfile.fromJson({
        'name': '  Dr. Rajesh Sharma  ',
        'regNo': ' MH-12345 ',
      });
      expect(profile.name, '');
      expect(profile.regNo, '');
    });

    test('a real doctor keeps a qualification the sample also used', () {
      // "MBBS, MD (Medicine)" was one of the sample values and is one of the
      // commonest qualifications in India. Erasing it made the profile
      // incomplete on every launch and trapped the doctor in onboarding.
      final profile = DoctorProfile.fromJson({
        'name': 'Dr. Asha Verma',
        'qualifications': 'MBBS, MD (Medicine)',
        'regNo': 'KA-4471',
        'clinicName': 'Verma Clinic',
        'clinicAddress': 'MG Road, Bengaluru',
        'phone': '9876543210',
        'signatureFileName': 'signature.png',
      });
      expect(profile.qualifications, 'MBBS, MD (Medicine)');
      expect(profile.name, 'Dr. Asha Verma');
      expect(profile.isComplete, isTrue);
    });

    test('a real clinic named like the sample is kept', () {
      final profile = DoctorProfile.fromJson({
        'name': 'Dr. Meera Iyer',
        'qualifications': 'MBBS',
        'regNo': 'TN-9081',
        'clinicName': 'Rxvarta Clinic',
        'clinicAddress': 'Anna Nagar, Chennai',
        'phone': '9812345670',
      });
      expect(profile.clinicName, 'Rxvarta Clinic');
      expect(profile.regNo, 'TN-9081');
    });

    test('the sample name alone is not enough to scrub', () {
      // Only name AND registration number together identify the old sample.
      final profile = DoctorProfile.fromJson({
        'name': 'Dr. Rajesh Sharma',
        'qualifications': 'MS (Ortho)',
        'regNo': 'MH-90210',
      });
      expect(profile.name, 'Dr. Rajesh Sharma');
      expect(profile.qualifications, 'MS (Ortho)');
      expect(profile.regNo, 'MH-90210');
    });

    test('real values survive and are trimmed', () {
      final profile = DoctorProfile.fromJson({
        'name': '  Dr. Asha Verma ',
        'qualifications': 'MBBS',
        'regNo': 'KA-1',
        'clinicName': 'Verma Clinic',
        'clinicAddress': 'MG Road',
        'clinicPhone': '',
        'phone': '9876543210',
        'signatureFileName': 'signature.png',
        'signatureUpdatedAt': '2026-09-01T10:00:00.000Z',
        'updatedAt': '2026-09-02T10:00:00.000Z',
        'onboardingCompletedAt': null,
      });
      expect(profile.name, 'Dr. Asha Verma');
      expect(profile.hasSignature, isTrue);
      expect(profile.signatureUpdatedAt, isNotNull);
      expect(profile.updatedAt, isNotNull);
      expect(profile.onboardingCompletedAt, isNull);
      expect(profile.isComplete, isTrue);
    });

    test('missing / non-string / blank signature name means no signature', () {
      expect(DoctorProfile.fromJson({}).hasSignature, isFalse);
      expect(
        DoctorProfile.fromJson({'signatureFileName': '   '}).hasSignature,
        isFalse,
      );
      expect(
        DoctorProfile.fromJson({'signatureFileName': 42}).hasSignature,
        isFalse,
      );
      expect(DoctorProfile.fromJson({'name': 12}).name, '');
    });
  });

  group('isComplete / missingFields', () {
    test('empty profile is missing everything', () {
      expect(DoctorProfile.empty.isComplete, isFalse);
      expect(
        DoctorProfile.empty.missingFields,
        containsAll(DoctorProfileField.values),
      );
      expect(
        DoctorProfile.empty.missingFields.length,
        DoctorProfileField.values.length,
      );
    });

    test('complete profile has no missing fields', () {
      expect(complete.isComplete, isTrue);
      expect(complete.missingFields, isEmpty);
    });

    test('clinic phone is optional', () {
      expect(complete.clinicPhone, '');
      expect(complete.isComplete, isTrue);
      expect(
        complete.copyWith(clinicPhone: '08012345678').missingFields,
        isEmpty,
      );
    });

    test('clinic address is required', () {
      final p = complete.copyWith(clinicAddress: '   ');
      expect(p.isComplete, isFalse);
      expect(p.missingFields, [DoctorProfileField.clinicAddress]);
    });

    test('doctor phone is required', () {
      final p = complete.copyWith(phone: '');
      expect(p.missingFields, [DoctorProfileField.phone]);
    });

    test('signature is required', () {
      final p = complete.copyWith(signatureFileName: null);
      expect(p.hasSignature, isFalse);
      expect(p.missingFields, [DoctorProfileField.signature]);
    });

    test('whitespace-only values count as missing', () {
      final p = complete.copyWith(name: '  ', regNo: '\t');
      expect(p.missingFields, [
        DoctorProfileField.name,
        DoctorProfileField.regNo,
      ]);
    });
  });

  group('copyWith', () {
    test('can clear signatureFileName to null', () {
      final cleared = complete.copyWith(
        signatureFileName: null,
        signatureUpdatedAt: null,
      );
      expect(cleared.signatureFileName, isNull);
      expect(cleared.signatureUpdatedAt, isNull);
      expect(cleared.hasSignature, isFalse);
    });

    test('omitted signature fields are preserved', () {
      final now = DateTime.now();
      final withTs = complete.copyWith(signatureUpdatedAt: now);
      final renamed = withTs.copyWith(name: 'Dr. B');
      expect(renamed.signatureFileName, 'signature.png');
      expect(renamed.signatureUpdatedAt, now);
      expect(renamed.name, 'Dr. B');
    });

    test('can clear timestamps to null', () {
      final now = DateTime.now();
      final p = complete.copyWith(updatedAt: now, onboardingCompletedAt: now);
      final cleared = p.copyWith(updatedAt: null, onboardingCompletedAt: null);
      expect(cleared.updatedAt, isNull);
      expect(cleared.onboardingCompletedAt, isNull);
    });
  });

  group('remote JSON round trip', () {
    test('toRemoteJson emits UTC ISO timestamps and column names', () {
      final sigAt = DateTime(2026, 9, 1, 15, 30);
      final updAt = DateTime(2026, 9, 2, 9, 0);
      final doneAt = DateTime(2026, 9, 2, 9, 5);
      final p = complete.copyWith(
        clinicPhone: '08012345678',
        signatureUpdatedAt: sigAt,
        updatedAt: updAt,
        onboardingCompletedAt: doneAt,
      );
      final row = p.toRemoteJson();
      expect(row['full_name'], 'Dr. Asha Verma');
      expect(row['qualifications'], 'MBBS, MD');
      expect(row['registration_number'], 'KA-98765');
      expect(row['clinic_name'], 'Verma Clinic');
      expect(row['clinic_address'], '12 MG Road, Bengaluru 560001');
      expect(row['clinic_phone'], '08012345678');
      expect(row['phone'], '9876543210');
      expect(row['signature_updated_at'], sigAt.toUtc().toIso8601String());
      expect(row['updated_at'], updAt.toUtc().toIso8601String());
      expect(row['onboarding_completed_at'], doneAt.toUtc().toIso8601String());
      // The signature file name is a local concept and is never sent.
      expect(row.containsKey('signatureFileName'), isFalse);
      expect(row.containsKey('signature_file_name'), isFalse);
      for (final v in row.values.whereType<String>()) {
        if (v.contains('T')) expect(v, endsWith('Z'));
      }
    });

    test('updated_at defaults to now when unset', () {
      final before = DateTime.now().toUtc().subtract(
        const Duration(seconds: 1),
      );
      final row = complete.toRemoteJson();
      final parsed = DateTime.parse(row['updated_at'] as String);
      expect(parsed.isUtc, isTrue);
      expect(parsed.isAfter(before), isTrue);
    });

    test('fromRemoteJson(toRemoteJson) preserves every field', () {
      final sigAt = DateTime.utc(2026, 9, 1, 10, 0, 0);
      final updAt = DateTime.utc(2026, 9, 2, 10, 0, 0);
      final doneAt = DateTime.utc(2026, 9, 2, 10, 5, 0);
      final original = complete.copyWith(
        clinicPhone: '08012345678',
        signatureUpdatedAt: sigAt,
        updatedAt: updAt,
        onboardingCompletedAt: doneAt,
      );
      final restored = DoctorProfile.fromRemoteJson(
        original.toRemoteJson(),
        signatureFileName: 'signature.png',
      );
      expect(restored.name, original.name);
      expect(restored.qualifications, original.qualifications);
      expect(restored.regNo, original.regNo);
      expect(restored.clinicName, original.clinicName);
      expect(restored.clinicAddress, original.clinicAddress);
      expect(restored.clinicPhone, original.clinicPhone);
      expect(restored.phone, original.phone);
      expect(restored.signatureFileName, 'signature.png');
      expect(restored.signatureUpdatedAt!.toUtc(), sigAt);
      expect(restored.updatedAt!.toUtc(), updAt);
      expect(restored.onboardingCompletedAt!.toUtc(), doneAt);
      expect(restored.isComplete, isTrue);
      // Parsed dates come back local; compare as instants.
      expect(restored.updatedAt!.isAtSameMomentAs(updAt), isTrue);
    });

    test('fromRemoteJson without a local signature file has no signature', () {
      final restored = DoctorProfile.fromRemoteJson(complete.toRemoteJson());
      expect(restored.signatureFileName, isNull);
      expect(restored.hasSignature, isFalse);
      expect(restored.missingFields, [DoctorProfileField.signature]);
    });

    test('local JSON round trip', () {
      final now = DateTime.now();
      final original = complete.copyWith(
        signatureUpdatedAt: now,
        updatedAt: now,
        onboardingCompletedAt: now,
      );
      final restored = DoctorProfile.fromJson(original.toJson());
      expect(restored.name, original.name);
      expect(restored.signatureFileName, 'signature.png');
      expect(restored.signatureUpdatedAt!.isAtSameMomentAs(now), isTrue);
      expect(restored.updatedAt!.isAtSameMomentAs(now), isTrue);
      expect(restored.onboardingCompletedAt!.isAtSameMomentAs(now), isTrue);
      expect(original.toJson()['updatedAt'], endsWith('Z'));
    });
  });

  test('equality and hashCode cover every field', () {
    expect(complete, complete.copyWith());
    expect(complete.hashCode, complete.copyWith().hashCode);
    expect(complete, isNot(complete.copyWith(phone: '1')));
    expect(complete, isNot(complete.copyWith(signatureFileName: null)));
  });
}
