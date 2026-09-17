import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/doctor_profile.dart';

const String kLoginPath = '/login';
const String kSignupPath = '/signup';
const String kVerifyPath = '/verify';
const String kForgotPath = '/forgot';
const String kResetPasswordPath = '/reset-password';
const String kSplashPath = '/splash';
const String kOnboardingPath = '/onboarding';
const String kHomePath = '/';

/// Paths of the unauthenticated flow (login, sign-up, e-mail code, forgot
/// password). Everything else requires a session.
const Set<String> kAuthPaths = {
  kLoginPath,
  kSignupPath,
  kVerifyPath,
  kForgotPath,
};

/// Pure routing decision behind the router's `redirect` (roadmap items 1, 8).
/// Returns the path to redirect to, or `null` to stay. Never returns the
/// current path, so a refresh can never loop.
///
/// Rules, in order:
///  1. No backend configured → only `/login` is reachable (it explains why).
///  2. Signed out → only the auth flow is reachable; everything else → login.
///  3. Signed in:
///     * `/reset-password` is always allowed (recovery in progress);
///     * a verified reset code ([recoveryPending]) forces `/reset-password`
///       wherever the doctor is, until the new password is saved;
///     * a recovery-code screen for a doctor who is now signed in means the
///       code was accepted → straight to `/reset-password`;
///     * profile not known yet → branded `/splash` (a reload that still
///       holds a complete profile does NOT evict the doctor);
///     * profile incomplete → `/onboarding` (allowed to stay there);
///     * profile complete → auth pages, splash and onboarding → home.
String? computeRedirect({
  required bool hasBackend,
  required bool signedIn,
  required AsyncValue<DoctorProfile> profile,
  required String location,
  bool recoveryPending = false,
}) {
  final uri = Uri.parse(location);
  final path = uri.path.isEmpty ? kHomePath : uri.path;
  String? to(String target) => target == path ? null : target;

  if (!hasBackend) return to(kLoginPath);

  if (!signedIn) {
    return kAuthPaths.contains(path) ? null : to(kLoginPath);
  }

  if (path == kResetPasswordPath) return null;
  if (recoveryPending) return kResetPasswordPath;
  if (path == kVerifyPath && uri.queryParameters['purpose'] == 'recovery') {
    return kResetPasswordPath;
  }
  if (profile.isLoading) {
    // Wait on splash only when we genuinely do not know the profile yet. A
    // reload that still holds a complete profile (backup restore, refresh)
    // must not throw a doctor out of a consultation in progress.
    final previous = profile.value;
    if (previous == null || !previous.isComplete) return to(kSplashPath);
  }

  final data = profile.value ?? DoctorProfile.empty;
  if (!data.isComplete) return to(kOnboardingPath);

  if (kAuthPaths.contains(path) ||
      path == kSplashPath ||
      path == kOnboardingPath) {
    return to(kHomePath);
  }
  return null;
}
