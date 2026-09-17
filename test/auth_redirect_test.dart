import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rxvarta/domain/models/doctor_profile.dart';
import 'package:rxvarta/features/auth/auth_redirect.dart';

void main() {
  const complete = DoctorProfile(
    name: 'Dr. Test',
    qualifications: 'MBBS',
    regNo: 'REG-1',
    clinicName: 'Clinic',
    clinicAddress: 'Somewhere',
    phone: '9999999999',
    signatureFileName: 'signature.png',
  );
  const incomplete = DoctorProfile(name: 'Dr. Test');

  const loading = AsyncLoading<DoctorProfile>();
  const loaded = AsyncData<DoctorProfile>(complete);
  const loadedIncomplete = AsyncData<DoctorProfile>(incomplete);

  String? redirect({
    bool hasBackend = true,
    bool signedIn = true,
    AsyncValue<DoctorProfile> profile = loaded,
    required String location,
    bool recoveryPending = false,
  }) => computeRedirect(
    hasBackend: hasBackend,
    signedIn: signedIn,
    profile: profile,
    location: location,
    recoveryPending: recoveryPending,
  );

  group('no backend configured', () {
    test('everything goes to /login', () {
      for (final loc in [
        '/',
        '/splash',
        '/signup',
        '/verify?email=a%40b.c&purpose=signup',
        '/forgot',
        '/reset-password',
        '/onboarding',
        '/settings',
        '/recording/abc',
      ]) {
        expect(
          redirect(hasBackend: false, signedIn: false, location: loc),
          '/login',
          reason: loc,
        );
      }
    });

    test('/login stays (no loop)', () {
      expect(
        redirect(hasBackend: false, signedIn: false, location: '/login'),
        isNull,
      );
    });

    test('a stale session is ignored without a backend', () {
      expect(redirect(hasBackend: false, location: '/'), '/login');
    });
  });

  group('signed out', () {
    test('auth flow pages are allowed', () {
      for (final loc in [
        '/login',
        '/signup',
        '/verify?email=a%40b.c&purpose=signup',
        '/verify?email=a%40b.c&purpose=recovery',
        '/forgot',
      ]) {
        expect(redirect(signedIn: false, location: loc), isNull, reason: loc);
      }
    });

    test('everything else goes to /login', () {
      for (final loc in [
        '/',
        '/splash',
        '/onboarding',
        '/reset-password',
        '/patients',
        '/settings',
        '/intake',
        '/recording/v1',
        '/review/v1',
        '/pdf/v1',
        '/patient/p1',
      ]) {
        expect(redirect(signedIn: false, location: loc), '/login', reason: loc);
      }
    });

    test('an empty location counts as home', () {
      expect(redirect(signedIn: false, location: ''), '/login');
    });
  });

  group('signed in, profile loading', () {
    test('goes to /splash', () {
      for (final loc in [
        '/',
        '/login',
        '/signup',
        '/forgot',
        '/onboarding',
        '/settings',
        '/verify?email=a%40b.c&purpose=signup',
      ]) {
        expect(
          redirect(profile: loading, location: loc),
          '/splash',
          reason: loc,
        );
      }
    });

    test('/splash stays (no loop)', () {
      expect(redirect(profile: loading, location: '/splash'), isNull);
    });

    test('/reset-password is always allowed', () {
      expect(redirect(profile: loading, location: '/reset-password'), isNull);
    });

    test('an accepted recovery code goes to /reset-password', () {
      expect(
        redirect(
          profile: loading,
          location: '/verify?email=a%40b.c&purpose=recovery',
        ),
        '/reset-password',
      );
    });

    test(
      'a reload that still holds a complete profile keeps the doctor in place',
      () async {
        // A backup restore invalidates the profile provider. Riverpod keeps
        // the previous complete profile while reloading; evicting the doctor
        // to /splash threw them out of a consultation in progress.
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final provider = FutureProvider<DoctorProfile>((ref) async => complete);
        await container.read(provider.future);
        container.invalidate(provider);
        final reloading = container.read(provider);
        expect(reloading.isLoading, isTrue);
        expect(reloading.hasValue, isTrue);
        expect(
          redirect(profile: reloading, location: '/intake/form?patientId=p1'),
          isNull,
        );
        expect(redirect(profile: reloading, location: '/'), isNull);
        // Pages that only exist before the app is ready still move on.
        expect(redirect(profile: reloading, location: '/splash'), '/');
      },
    );

    test('after sign-out the next doctor still waits on /splash', () async {
      // Sign-out resolves the profile to empty before anyone can sign in
      // again, so a newly signed-in doctor loads with an EMPTY previous
      // value and never inherits someone else's complete profile.
      Future<AsyncValue<DoctorProfile>> reloadingFrom(DoctorProfile p) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final provider = FutureProvider<DoctorProfile>((ref) async => p);
        await container.read(provider.future);
        container.invalidate(provider);
        return container.read(provider);
      }

      final fromEmpty = await reloadingFrom(DoctorProfile.empty);
      expect(fromEmpty.isLoading, isTrue);
      expect(redirect(profile: fromEmpty, location: '/'), '/splash');

      final fromIncomplete = await reloadingFrom(incomplete);
      expect(redirect(profile: fromIncomplete, location: '/'), '/splash');
    });
  });

  group('signed in, profile incomplete', () {
    test('goes to /onboarding', () {
      for (final loc in [
        '/',
        '/splash',
        '/login',
        '/signup',
        '/forgot',
        '/settings',
        '/patients',
        '/recording/v1',
      ]) {
        expect(
          redirect(profile: loadedIncomplete, location: loc),
          '/onboarding',
          reason: loc,
        );
      }
    });

    test('/onboarding stays (no loop)', () {
      expect(
        redirect(profile: loadedIncomplete, location: '/onboarding'),
        isNull,
      );
    });

    test('/reset-password is still allowed', () {
      expect(
        redirect(profile: loadedIncomplete, location: '/reset-password'),
        isNull,
      );
    });

    test('a profile that failed to load is treated as incomplete', () {
      final failed = AsyncError<DoctorProfile>(
        Exception('disk'),
        StackTrace.empty,
      );
      expect(redirect(profile: failed, location: '/'), '/onboarding');
      expect(redirect(profile: failed, location: '/onboarding'), isNull);
    });

    test('an empty (signed-out style) profile is incomplete', () {
      expect(
        redirect(profile: const AsyncData(DoctorProfile.empty), location: '/'),
        '/onboarding',
      );
    });
  });

  group('signed in, profile complete', () {
    test('auth pages, splash and onboarding go home', () {
      for (final loc in [
        '/login',
        '/signup',
        '/verify?email=a%40b.c&purpose=signup',
        '/forgot',
        '/splash',
        '/onboarding',
      ]) {
        expect(redirect(location: loc), '/', reason: loc);
      }
    });

    test('app routes stay', () {
      for (final loc in [
        '/',
        '/patients',
        '/settings',
        '/intake',
        '/intake/form?patientId=p1',
        '/intake/existing',
        '/recording/v1?append=true',
        '/review/v1',
        '/pdf/v1',
        '/patient/p1',
        '/reset-password',
      ]) {
        expect(redirect(location: loc), isNull, reason: loc);
      }
    });

    test('recovery verify still goes to /reset-password', () {
      expect(
        redirect(location: '/verify?email=a%40b.c&purpose=recovery'),
        '/reset-password',
      );
    });
  });

  group('password recovery in progress', () {
    test('a verified reset code forces /reset-password from anywhere', () {
      for (final loc in [
        '/',
        '/login',
        '/forgot',
        '/verify?email=a%40b.c&purpose=recovery',
        '/splash',
        '/onboarding',
        '/settings',
      ]) {
        expect(
          redirect(location: loc, recoveryPending: true),
          '/reset-password',
          reason: loc,
        );
      }
    });

    test('it applies even while the profile is still loading', () {
      expect(
        redirect(location: '/', profile: loading, recoveryPending: true),
        '/reset-password',
      );
    });

    test('the reset screen itself is left alone', () {
      expect(
        redirect(location: '/reset-password', recoveryPending: true),
        isNull,
      );
    });

    test('once cleared, the doctor can leave the reset screen', () {
      expect(redirect(location: '/'), isNull);
    });
  });
}
