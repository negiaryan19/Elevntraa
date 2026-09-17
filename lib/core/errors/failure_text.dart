import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;

import '../../l10n/app_localizations.dart';
import 'failure.dart';

/// What went wrong, in one short sentence in the doctor's language (roadmap
/// item 11). Exception text is for developers: it is logged here and never
/// shown.
String failureText(AppLocalizations t, Object error) {
  debugPrint('[error] $error');
  final code = switch (error) {
    Failure(:final code) => code,
    SocketException() ||
    TimeoutException() ||
    HttpException() => FailureCode.network,
    FileSystemException() => FailureCode.storage,
    _ => FailureCode.unknown,
  };
  return switch (code) {
    FailureCode.network => t.errorOffline,
    FailureCode.auth => t.errorSessionExpired,
    FailureCode.storage => t.errorStorage,
    FailureCode.permission => t.errorPermission,
    FailureCode.invalidAudio => t.nothingHeardInRecording,
    FailureCode.invalidBackup => t.errorInvalidBackup,
    FailureCode.backupFromNewerApp => t.errorBackupTooNew,
    FailureCode.server || FailureCode.unknown => t.errorUnexpected,
  };
}
