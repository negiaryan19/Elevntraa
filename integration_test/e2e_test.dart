import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:medscribe/main.dart' as app;

/// End-to-end drive of the full consultation flow against REAL services:
/// home → new patient intake → live mic recording → Sarvam STT →
/// Gemini extraction → review screen → PDF screen.
///
/// Run on a booted simulator with mic permission pre-granted and speech
/// audio playing near the host mic:
///   `xcrun simctl privacy <udid> grant microphone com.medscribe.varad`
///   `flutter test integration_test/e2e_test.dart -d <udid>`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('full consultation flow', (tester) async {
    app.main();
    await tester.pump(const Duration(seconds: 2));

    // ── Home ────────────────────────────────────────────────────────────
    expect(
      await _waitFor(tester, find.text('Start New Consultation')),
      true,
      reason: 'home screen should load',
    );
    debugPrint('E2E ✅ home loaded');

    await tester.tap(find.text('Start New Consultation'));

    // ── Intake choice ───────────────────────────────────────────────────
    expect(
      await _waitFor(tester, find.text('New Patient')),
      true,
      reason: 'intake choice should appear',
    );
    debugPrint('E2E ✅ intake choice');
    await tester.tap(find.text('New Patient'));

    // ── Intake form ─────────────────────────────────────────────────────
    expect(
      await _waitFor(tester, find.text('Patient Name')),
      true,
      reason: 'intake form should appear',
    );
    debugPrint('E2E ✅ intake form');

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'E2E Test Patient');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(fields.at(1), '34');
    await tester.pump(const Duration(milliseconds: 200));

    // Gender dropdown
    await tester.tap(find.text('Select'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Male').last);
    await tester.pump(const Duration(milliseconds: 400));

    // Unique phone per run so the duplicate-number dialog never appears.
    final phone =
        '9${(DateTime.now().millisecondsSinceEpoch % 1000000000).toString().padLeft(9, '0')}';
    await tester.enterText(fields.at(2), phone);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 300));

    // Consent checkbox (scroll into view first)
    final consent = find.textContaining('consented');
    await tester.scrollUntilVisible(
      consent,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(consent);
    await tester.pump(const Duration(milliseconds: 300));

    final continueBtn = find.text('Continue to Recording');
    await tester.scrollUntilVisible(
      continueBtn,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(continueBtn);
    debugPrint('E2E ✅ form submitted');

    // ── Recording screen ────────────────────────────────────────────────
    expect(
      await _waitFor(tester, find.text('Start Consultation')),
      true,
      reason: 'recording screen should appear',
    );
    debugPrint('E2E ✅ recording screen');

    await tester.tap(find.text('Start Consultation'));
    await tester.pump(const Duration(seconds: 1));

    // Record ~14 s of real time (host plays consultation speech).
    for (var i = 0; i < 28; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(
      find.text('Done'),
      findsOneWidget,
      reason: 'Done button should be visible while recording',
    );
    debugPrint('E2E ✅ recorded ~14s, stopping');
    await tester.tap(find.text('Done'));

    // ── Pipeline: STT + extraction (real network) ───────────────────────
    final reviewReached = await _waitFor(
      tester,
      find.textContaining('Generate'),
      timeout: const Duration(minutes: 3),
    );
    if (!reviewReached) {
      // Surface whatever error the app is showing before failing.
      final texts = find
          .byType(Text)
          .evaluate()
          .take(40)
          .map((e) {
            final w = e.widget;
            return w is Text ? (w.data ?? '') : '';
          })
          .where((s) => s.isNotEmpty);
      debugPrint('E2E ❌ review not reached. Visible texts: $texts');
    }
    expect(
      reviewReached,
      true,
      reason: 'review screen should appear after processing',
    );
    debugPrint('E2E ✅ review screen — pipeline complete');

    expect(
      find.text('Diagnosis'),
      findsOneWidget,
      reason: 'review screen should show Diagnosis section',
    );

    // ── Sign & generate PDF ─────────────────────────────────────────────
    final pdfBtn = find.textContaining('Generate');
    await tester.scrollUntilVisible(
      pdfBtn,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(pdfBtn);

    final pdfReached = await _waitFor(
      tester,
      find.textContaining('Prescription'),
      timeout: const Duration(minutes: 1),
    );
    expect(pdfReached, true, reason: 'PDF screen should appear');
    debugPrint('E2E ✅ PDF screen reached — flow complete');

    // Hold the final frame so the host can screenshot it.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  });
}

/// Polls real time for [f] to appear — pumpAndSettle can't be used because
/// the recording screen runs repeating pulse animations that never settle.
Future<bool> _waitFor(
  WidgetTester tester,
  Finder f, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 400));
    if (f.evaluate().isNotEmpty) return true;
  }
  return false;
}
