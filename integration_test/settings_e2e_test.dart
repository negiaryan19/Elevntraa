import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rxvarta/main.dart' as app;
import 'package:signature/signature.dart';

/// End-to-end drive of the account + settings surface against the REAL
/// Supabase project (roadmap items 1, 2, 3, 4, 5, 22, 24, 26, 27, 28, 29):
/// login → (onboarding with a drawn signature) → home → Settings → every tile
/// → logout → login screen again.
///
/// Run on macOS desktop with the dev doctor account:
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/settings_e2e_test.dart -d macos \
///     --dart-define-from-file=config/e2e.json
/// config/e2e.json = config/app_config.json + E2E_EMAIL / E2E_PASSWORD.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const email = String.fromEnvironment('E2E_EMAIL');
  const password = String.fromEnvironment('E2E_PASSWORD');

  testWidgets('login, onboarding, settings tiles, logout', (tester) async {
    expect(
      email.isNotEmpty && password.isNotEmpty,
      true,
      reason: 'pass --dart-define-from-file=config/e2e.json',
    );

    await app.main();
    await tester.pump(const Duration(seconds: 2));

    // ── Login (or already signed in from a previous run) ────────────────
    final loggedOut = await _waitFor(
      tester,
      find.text('Welcome back'),
      timeout: const Duration(seconds: 15),
    );
    if (loggedOut) {
      await _shot(binding, tester, '01_login');
      final fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(2));
      await tester.enterText(fields.at(0), email);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(fields.at(1), password);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Sign in').last);
      await tester.pump(const Duration(seconds: 1));
    }

    // ── Splash → onboarding or home ─────────────────────────────────────
    final reachedHome = await _waitForAny(tester, [
      find.text('Start new consultation'),
      find.text('Set up your prescription'),
    ], timeout: const Duration(seconds: 30));
    expect(
      reachedHome,
      isNotNull,
      reason: 'neither home nor onboarding appeared',
    );

    if (find.text('Set up your prescription').evaluate().isNotEmpty &&
        find.text('Start new consultation').evaluate().isEmpty) {
      await _shot(binding, tester, '02_onboarding_doctor');
      await _fillOnboarding(tester, binding);
      expect(
        await _waitFor(
          tester,
          find.text('Start new consultation'),
          timeout: const Duration(seconds: 30),
        ),
        true,
        reason: 'home should appear after onboarding',
      );
    }
    await _shot(binding, tester, '04_home');

    // ── Settings ────────────────────────────────────────────────────────
    await tester.tap(find.text('Settings').last);
    await tester.pump(const Duration(seconds: 1));
    expect(await _waitFor(tester, find.text('Profile Settings')), true);
    // The header must show a real doctor, never the old sample identity.
    expect(find.textContaining('Rajesh Sharma'), findsNothing);
    expect(find.textContaining('MH-12345'), findsNothing);
    await _shot(binding, tester, '05_settings');

    // Privacy & Security screen.
    await _openTileAndBack(tester, binding, 'Privacy & Security', '06_privacy');
    // Legal documents.
    await _openTileAndBack(tester, binding, 'Terms & Conditions', '07_terms');
    // Help & Support sheet.
    await _scrollTo(tester, find.text('Help & Support'));
    await tester.tap(find.text('Help & Support'));
    await tester.pump(const Duration(seconds: 1));
    await _shot(binding, tester, '08_help');
    await _dismissSheet(tester);

    // Backup sheet (real upload to the private backups bucket).
    final backupTile = find.textContaining('Backup');
    await _scrollTo(tester, backupTile.first);
    await tester.tap(backupTile.first);
    await tester.pump(const Duration(seconds: 1));
    await _shot(binding, tester, '09_backup_sheet');
    final backupNow = find.text('Back up now');
    if (backupNow.evaluate().isNotEmpty) {
      await tester.tap(backupNow);
      // Wait for either the success or the failure state to settle.
      await tester.pump(const Duration(seconds: 15));
      await _shot(binding, tester, '10_backup_result');
    }
    await _dismissSheet(tester);

    // ── Logout ──────────────────────────────────────────────────────────
    await _scrollTo(tester, find.text('Logout'));
    await tester.tap(find.text('Logout'));
    await tester.pump(const Duration(milliseconds: 600));
    // Confirm dialog: the tile says "Logout", the confirming action says
    // "Sign out".
    expect(await _waitFor(tester, find.text('Sign out?')), true);
    await tester.tap(find.text('Sign out').last);
    await tester.pump(const Duration(seconds: 2));
    expect(
      await _waitFor(
        tester,
        find.text('Welcome back'),
        timeout: const Duration(seconds: 15),
      ),
      true,
      reason: 'login screen should appear after logout',
    );
    await _shot(binding, tester, '11_logged_out');
  });
}

Future<void> _fillOnboarding(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
) async {
  // Step 1 — doctor details: name, qualifications, reg no, phone.
  var fields = find.byType(TextFormField);
  await _type(tester, fields.at(0), 'Dr. E2E Tester');
  await _type(tester, fields.at(1), 'MBBS, MD');
  await _type(tester, fields.at(2), 'MH-E2E-0001');
  await _type(tester, fields.at(3), '9876543210');
  await tester.tap(find.text('Continue'));
  await tester.pump(const Duration(seconds: 1));

  // Step 2 — clinic details: name, address, phone (optional).
  fields = find.byType(TextFormField);
  await _type(tester, fields.at(0), 'E2E Clinic');
  await _type(tester, fields.at(1), '12 Test Road, Mumbai 400001');
  await tester.tap(find.text('Continue'));
  await tester.pump(const Duration(seconds: 1));
  await _shot(binding, tester, '03_onboarding_signature');

  // Step 3 — signature: draw on the pad.
  // The button reads "Add signature" the first time and "Update signature"
  // once one exists (e.g. a previous run on this machine).
  final addSig = find.text('Add signature');
  await tester.tap(
    addSig.evaluate().isNotEmpty ? addSig : find.text('Update signature'),
  );
  await tester.pump(const Duration(seconds: 1));
  final pad = find.byType(Signature);
  expect(pad, findsOneWidget);
  await _scribble(tester, pad);
  await tester.tap(find.text('Use signature'));
  await tester.pump(const Duration(seconds: 2));

  await _scrollTo(tester, find.text('Finish'));
  await tester.tap(find.text('Finish'));
  await tester.pump(const Duration(seconds: 2));
}

/// Draws a signature-like squiggle on the pad. package:signature records
/// points from pan updates, so the gesture has to move in many small steps
/// with a frame pumped between them; a single `dragFrom` produces too few
/// points and leaves the pad empty.
Future<void> _scribble(WidgetTester tester, Finder pad) async {
  final box = tester.getRect(pad);
  final baseline = box.center.dy + box.height * 0.15;
  final left = box.left + box.width * 0.2;
  final width = box.width * 0.6;

  final gesture = await tester.startGesture(Offset(left, baseline));
  await tester.pump(const Duration(milliseconds: 16));
  const steps = 40;
  for (var i = 1; i <= steps; i++) {
    final t = i / steps;
    final x = left + width * t;
    // Two humps so the stroke looks like handwriting and covers real area.
    final y = baseline - box.height * 0.25 * (1 - (2 * t - 1).abs());
    await gesture.moveTo(Offset(x, y));
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _openTileAndBack(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  String label,
  String shot,
) async {
  await _scrollTo(tester, find.text(label));
  await tester.tap(find.text(label));
  await tester.pump(const Duration(seconds: 1));
  await _shot(binding, tester, shot);
  final back = find.byType(BackButton);
  if (back.evaluate().isNotEmpty) {
    await tester.tap(back.first);
  } else {
    await tester.pageBack();
  }
  await tester.pump(const Duration(seconds: 1));
  // The settings list keeps its scroll position, so assert on the tile we
  // came from rather than the first tile (which may be scrolled off and
  // disposed).
  expect(
    await _waitFor(tester, find.text(label)),
    true,
    reason: 'should return to settings after $label',
  );
}

Future<void> _dismissSheet(WidgetTester tester) async {
  // Drag the sheet down / tap the barrier: tapping the top-left corner hits
  // the modal barrier for bottom sheets.
  await tester.tapAt(const Offset(20, 40));
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isNotEmpty) {
    await tester.ensureVisible(finder);
    await tester.pump(const Duration(milliseconds: 300));
    return;
  }
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _type(WidgetTester tester, Finder field, String text) async {
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pump(const Duration(milliseconds: 150));
}

Future<void> _shot(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  await tester.pump(const Duration(milliseconds: 300));
  try {
    await binding.takeScreenshot(name);
  } catch (e) {
    debugPrint('E2E screenshot $name skipped: $e');
  }
}

Future<bool> _waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return true;
  }
  return false;
}

Future<Finder?> _waitForAny(
  WidgetTester tester,
  List<Finder> finders, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    for (final f in finders) {
      if (f.evaluate().isNotEmpty) return f;
    }
  }
  return null;
}
