/// Stable, UI-facing classification of what went wrong. The UI maps a code to
/// a localized message and a recovery action (Retry / Sign in / Open settings /
/// Record again) instead of showing raw exception text (roadmap item 11).
enum FailureCode {
  /// No connectivity or the request never reached the server.
  network,

  /// No valid session; the doctor must sign in again.
  auth,

  /// Local disk / database read or write failed.
  storage,

  /// Microphone or notification permission missing.
  permission,

  /// The recording was empty, silent or unreadable.
  invalidAudio,

  /// A backup file is damaged, not a Rxvarta backup, or another account's.
  invalidBackup,

  /// A backup was made by a newer app version than this one.
  backupFromNewerApp,

  /// Backend returned an error we do not classify further.
  server,

  /// Anything else.
  unknown,
}

/// A flat failure type the UI can render directly. Repositories and services
/// translate IO/DB/Supabase exceptions into one of these so widgets never see
/// a raw exception. [message] is a developer-readable detail that is logged,
/// never shown; [code] picks the translated text (see `failureText`).
sealed class Failure implements Exception {
  const Failure(this.message, {this.cause, this.code = FailureCode.unknown});

  final String message;
  final Object? cause;
  final FailureCode code;

  @override
  String toString() => '$runtimeType(${code.name}): $message';
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.cause})
    : super(code: FailureCode.network);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.cause})
    : super(code: FailureCode.auth);
}

class ApiFailure extends Failure {
  const ApiFailure(
    super.message, {
    super.cause,
    super.code = FailureCode.server,
  });
}

class StorageFailure extends Failure {
  const StorageFailure(
    super.message, {
    super.cause,
    super.code = FailureCode.storage,
  });
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {super.cause})
    : super(code: FailureCode.permission);
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.cause});
}
