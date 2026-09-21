import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../errors/failure.dart';

/// Real per-doctor authentication on top of Supabase Auth (roadmap items 1,
/// 8, 29). Email + password accounts; e-mail ownership is proven with the
/// 8-digit code the project's auth templates send (`{{ .Token }}`), so the app
/// never needs deep links. Nothing here ever signs in with a shared account.
///
/// Streams the auth state so the router can redirect (no session → login,
/// session → app) and so user-scoped providers rebuild when the doctor
/// changes. Seeded with the persisted session so the first frame already
/// knows whether the doctor is signed in.
final authStateProvider = StreamProvider<AuthState>((ref) async* {
  if (!AppConfig.hasBackend) {
    // No backend configured: behave as signed out so the login screen can
    // explain the problem instead of the app crashing on Supabase.instance.
    yield const AuthState(AuthChangeEvent.initialSession, null);
    return;
  }
  final auth = Supabase.instance.client.auth;
  yield AuthState(AuthChangeEvent.initialSession, auth.currentSession);
  yield* auth.onAuthStateChange;
});

/// The signed-in doctor, or null.
final currentUserProvider = Provider<User?>((ref) {
  final state = ref.watch(authStateProvider).value;
  if (state != null) return state.session?.user;
  if (!AppConfig.hasBackend) return null;
  return Supabase.instance.client.auth.currentUser;
});

/// Supabase user id of the signed-in doctor, or null. Every piece of
/// per-doctor state (profile, data folders, sync) keys off this.
final currentUserIdProvider = Provider<String?>(
  (ref) => ref.watch(currentUserProvider)?.id,
);

final isSignedInProvider = Provider<bool>(
  (ref) => ref.watch(currentUserIdProvider) != null,
);

/// True from the moment a password-reset code is verified until the doctor
/// sets a new password or signs out.
///
/// Verifying a recovery code signs the doctor in. Without this flag the
/// router saw an ordinary signed-in doctor and sent them home before the
/// "Set new password" screen could open, so the password was never changed.
final passwordRecoveryPendingProvider =
    NotifierProvider<PasswordRecoveryPending, bool>(
      PasswordRecoveryPending.new,
    );

class PasswordRecoveryPending extends Notifier<bool> {
  @override
  bool build() {
    ref.listen<AsyncValue<AuthState>>(authStateProvider, (_, next) {
      switch (next.value?.event) {
        case AuthChangeEvent.passwordRecovery:
          state = true;
        case AuthChangeEvent.userUpdated || AuthChangeEvent.signedOut:
          state = false;
        default:
          break;
      }
    });
    return false;
  }

  /// Called once the new password is saved, before leaving the screen, so
  /// the router does not bounce the doctor straight back to it.
  void clear() => state = false;
}

/// What went wrong, for localized messages in the auth screens.
enum AuthErrorKind {
  invalidCredentials,
  emailNotConfirmed,
  userAlreadyExists,
  weakPassword,
  otpExpired,
  otpInvalid,
  rateLimited,

  /// The server could not hand the code e-mail (sign-up, reset) to its mail
  /// relay. Nothing the doctor typed is wrong; a later retry can work.
  emailSendFailed,
  network,
  signupDisabled,
  validation,
  notConfigured,
  unknown,
}

/// Classifies any error thrown by [AuthController] (or Supabase directly).
AuthErrorKind authErrorKind(Object error) {
  final e = error is AuthFailure ? (error.cause ?? error) : error;
  if (e is AuthFailure && e.message == _kNotConfigured) {
    return AuthErrorKind.notConfigured;
  }
  if (e is SocketException || e is TimeoutException) {
    return AuthErrorKind.network;
  }
  if (e is AuthException) {
    switch (e.code) {
      case 'invalid_credentials':
      case 'user_not_found':
        return AuthErrorKind.invalidCredentials;
      case 'email_not_confirmed':
        return AuthErrorKind.emailNotConfirmed;
      case 'user_already_exists':
      case 'email_exists':
        return AuthErrorKind.userAlreadyExists;
      case 'weak_password':
      case 'same_password':
        return AuthErrorKind.weakPassword;
      case 'otp_expired':
        return AuthErrorKind.otpExpired;
      case 'otp_disabled':
      case 'invalid_otp':
        return AuthErrorKind.otpInvalid;
      case 'over_email_send_rate_limit':
      case 'over_request_rate_limit':
      case 'over_sms_send_rate_limit':
        return AuthErrorKind.rateLimited;
      case 'signup_disabled':
        return AuthErrorKind.signupDisabled;
      case 'validation_failed':
        return AuthErrorKind.validation;
    }
    final msg = e.message.toLowerCase();
    // GoTrue answers HTTP 500 "Error sending confirmation / recovery / magic
    // link / email change email" when its SMTP relay refuses the message
    // (e.g. Brevo "Unauthorized IP address"). gotrue-dart puts the raw JSON
    // body in the message and sets no code, so the text is all there is.
    if (msg.contains('error sending')) return AuthErrorKind.emailSendFailed;
    if (msg.contains('token has expired') || msg.contains('expired')) {
      return AuthErrorKind.otpExpired;
    }
    if (msg.contains('invalid') && msg.contains('token')) {
      return AuthErrorKind.otpInvalid;
    }
    if (msg.contains('socket') || msg.contains('network')) {
      return AuthErrorKind.network;
    }
    if (msg.contains('already registered') || msg.contains('already exists')) {
      return AuthErrorKind.userAlreadyExists;
    }
    if (e.statusCode == '429') return AuthErrorKind.rateLimited;
  }
  final text = e.toString().toLowerCase();
  if (text.contains('socketexception') ||
      text.contains('clientexception') ||
      text.contains('failed host lookup') ||
      text.contains('connection')) {
    return AuthErrorKind.network;
  }
  return AuthErrorKind.unknown;
}

/// Result of [AuthController.signUp].
enum SignUpOutcome {
  /// The project requires e-mail confirmation: an 8-digit code was sent and
  /// the UI must collect it (see [AuthController.verifySignUp]).
  verificationRequired,

  /// Confirmation is disabled server-side; the doctor is already signed in.
  signedIn,
}

const _kNotConfigured = 'Backend is not configured.';

/// Thin, exception-normalising facade over `Supabase.instance.client.auth`.
/// Every method throws [AuthFailure] (with the original error as `cause`) on
/// failure; use [authErrorKind] to localise.
class AuthController {
  AuthController(this._ref);

  final Ref _ref;

  GoTrueClient get _auth => Supabase.instance.client.auth;

  Session? get currentSession =>
      AppConfig.hasBackend ? _auth.currentSession : null;

  void _requireBackend() {
    if (!AppConfig.hasBackend) throw const AuthFailure(_kNotConfigured);
  }

  Future<T> _guard<T>(Future<T> Function() op) async {
    _requireBackend();
    try {
      return await op();
    } on AuthFailure {
      rethrow;
    } on AuthException catch (e) {
      throw AuthFailure(e.message, cause: e);
    } catch (e) {
      throw AuthFailure(e.toString(), cause: e);
    }
  }

  Future<void> signIn({required String email, required String password}) =>
      _guard(() async {
        await _auth.signInWithPassword(email: email.trim(), password: password);
      });

  /// Creates the account. With e-mail confirmation enabled (production
  /// setting) Supabase returns no session and mails the code. When the address
  /// is already registered Supabase returns an obfuscated user with no
  /// identities (anti-enumeration); we surface that as
  /// [AuthErrorKind.userAlreadyExists] so the doctor is sent to Login.
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
  }) => _guard(() async {
    final res = await _auth.signUp(email: email.trim(), password: password);
    if (res.session != null) return SignUpOutcome.signedIn;
    final identities = res.user?.identities;
    if (identities != null && identities.isEmpty) {
      throw AuthFailure(
        'User already registered',
        cause: const AuthException(
          'User already registered',
          code: 'user_already_exists',
        ),
      );
    }
    return SignUpOutcome.verificationRequired;
  });

  /// Verifies the 8-digit sign-up code; on success the doctor is signed in.
  Future<void> verifySignUp({required String email, required String token}) =>
      _guard(() async {
        await _auth.verifyOTP(
          type: OtpType.signup,
          email: email.trim(),
          token: token.trim(),
        );
      });

  Future<void> resendSignUpCode(String email) => _guard(() async {
    await _auth.resend(type: OtpType.signup, email: email.trim());
  });

  /// Starts a password reset: Supabase mails an 8-digit recovery code.
  Future<void> requestPasswordReset(String email) => _guard(() async {
    await _auth.resetPasswordForEmail(email.trim());
  });

  /// Verifies the recovery code. On success a session exists and
  /// [updatePassword] can be called.
  Future<void> verifyRecovery({required String email, required String token}) =>
      _guard(() async {
        await _auth.verifyOTP(
          type: OtpType.recovery,
          email: email.trim(),
          token: token.trim(),
        );
      });

  Future<void> updatePassword(String newPassword) => _guard(() async {
    await _auth.updateUser(UserAttributes(password: newPassword));
  });

  /// Returns a usable session, refreshing an expired one. Throws
  /// [AuthFailure] when there is none — callers (upload, sync) surface it as
  /// "please sign in again"; nothing falls back to a shared login.
  Future<Session> ensureSession() => _guard(() async {
    final current = _auth.currentSession;
    if (current == null) {
      throw const AuthFailure('Not signed in.');
    }
    if (!current.isExpired) return current;
    final refreshed = await _auth.refreshSession();
    final session = refreshed.session;
    if (session == null) throw const AuthFailure('Session expired.');
    return session;
  });

  /// Ends the session on this device (roadmap item 29). The auth stream
  /// emits `signedOut`, user-scoped providers dispose, and the router
  /// redirects to Login. Local per-doctor files are kept (they are scoped by
  /// uid and may hold consultations waiting to upload); Settings > Privacy
  /// offers "Delete local data" for shared devices.
  Future<void> signOut() async {
    _requireBackend();
    try {
      await _auth.signOut(scope: SignOutScope.local);
    } on AuthException catch (e) {
      // A revoked/expired token already means "signed out" server-side; the
      // local session is cleared regardless, so just log it.
      debugPrint('[auth] signOut server call failed (${e.code}): ${e.message}');
    } catch (e) {
      debugPrint('[auth] signOut failed: $e');
    }
    _ref.invalidate(authStateProvider);
  }
}

final authControllerProvider = Provider<AuthController>(AuthController.new);
