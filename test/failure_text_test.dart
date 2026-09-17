import 'dart:io';

import 'package:archive/archive.dart' show ArchiveException;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxvarta/core/errors/failure.dart';
import 'package:rxvarta/core/errors/failure_text.dart';
import 'package:rxvarta/features/settings/data/backup_service.dart';
import 'package:rxvarta/l10n/app_localizations.dart';

/// Backup, export, report and share failures used to show the doctor raw
/// exception text ("Backup failed: SocketException: Failed host lookup ...",
/// "Could not add report: PathNotFoundException ...") in English whatever
/// the app language (roadmap item 11).
void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final hi = lookupAppLocalizations(const Locale('hi'));

  test('connection problems read as no internet', () {
    expect(failureText(en, const NetworkFailure('no route')), en.errorOffline);
    expect(
      failureText(en, const SocketException('Failed host lookup')),
      en.errorOffline,
    );
  });

  test('each failure kind has its own message', () {
    expect(
      failureText(en, const AuthFailure('jwt expired')),
      en.errorSessionExpired,
    );
    expect(
      failureText(en, const FileSystemException('No space left on device')),
      en.errorStorage,
    );
    expect(
      failureText(
        en,
        const StorageFailure(
          'manifest missing',
          code: FailureCode.invalidBackup,
        ),
      ),
      en.errorInvalidBackup,
    );
    expect(
      failureText(
        en,
        const StorageFailure('v9', code: FailureCode.backupFromNewerApp),
      ),
      en.errorBackupTooNew,
    );
  });

  test('an unexpected exception never shows its text', () {
    final text = failureText(en, StateError('Bad state: isolate died 0x1f'));
    expect(text, en.errorUnexpected);
    expect(text, isNot(contains('isolate')));
  });

  test('the message follows the app language', () {
    expect(failureText(hi, const NetworkFailure('x')), hi.errorOffline);
    expect(hi.errorOffline, isNot(en.errorOffline));
  });

  test('a damaged backup archive is reported as an invalid backup', () {
    final failure = mapBackupError(ArchiveException('bad zip'), 'Restore');
    expect(failure.code, FailureCode.invalidBackup);
    expect(failureText(en, failure), en.errorInvalidBackup);
  });
}
