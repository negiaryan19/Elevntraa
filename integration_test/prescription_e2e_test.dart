import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:rxvarta/app/app.dart';
import 'package:rxvarta/core/config/app_config.dart';
import 'package:rxvarta/core/prefs/shared_preferences_provider.dart';
import 'package:rxvarta/core/utils/app_paths.dart';
import 'package:rxvarta/features/consultation/data/recording_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fixtures/consultation_audio.dart';

/// A consultation from recording to signed PDF, on a device, against the
/// REAL backend: upload → Sarvam speech-to-text → Gemini extraction → Review
/// → Sign → PDF. Only the microphone is replaced, by a spoken clip, because
/// an emulator cannot be relied on to hear the host microphone.
///
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/prescription_e2e_test.dart \
///     -d emulator-5554 --dart-define-from-file=config/e2e.json
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const email = String.fromEnvironment('E2E_EMAIL');
  const password = String.fromEnvironment('E2E_PASSWORD');

  testWidgets('a spoken consultation becomes a filled, signed prescription', (
    tester,
  ) async {
    expect(AppConfig.hasBackend, isTrue, reason: 'pass config/e2e.json');

    await AppPaths.init();
    final prefs = await SharedPreferences.getInstance();
    await Supabase.initialize(
      url: AppConfig.supabaseUrl!,
      publishableKey: AppConfig.supabaseAnonKey!,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          recordingServiceProvider.overrideWithValue(_ClipRecorder()),
        ],
        child: const RxvartaApp(),
      ),
    );

    // ── Signed in (or sign in) ─────────────────────────────────────────
    final first = await _waitForAny(tester, [
      find.text('Start new consultation'),
      find.text('Welcome back'),
    ], timeout: const Duration(seconds: 30));
    if (first != null && find.text('Welcome back').evaluate().isNotEmpty) {
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), email);
      await tester.enterText(fields.at(1), password);
      await tester.tap(find.text('Sign in').last);
    }
    expect(
      await _waitFor(
        tester,
        find.text('Start new consultation'),
        timeout: const Duration(seconds: 30),
      ),
      isTrue,
      reason: 'home did not appear',
    );

    // ── New patient ────────────────────────────────────────────────────
    await tester.tap(find.text('Start new consultation'));
    expect(await _waitFor(tester, find.text('New Patient')), isTrue);
    await tester.tap(find.text('New Patient'));
    expect(await _waitFor(tester, find.text('Patient Name')), isTrue);

    // A number no earlier run used, or the app rightly offers to reuse that
    // patient's record instead of creating a new one.
    final phone =
        '9${(DateTime.now().millisecondsSinceEpoch % 1000000000).toString().padLeft(9, '0')}';
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'E2E Ramesh Kumar');
    await tester.enterText(fields.at(1), '42');
    await tester.enterText(fields.at(2), phone);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 500));

    await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await _settle(tester);
    await tester.tap(find.text('Male').last);
    await _settle(tester);

    await tester.ensureVisible(
      find.text('Patient has consented to be recorded (DPDP Act)'),
    );
    await tester.tap(
      find.text('Patient has consented to be recorded (DPDP Act)'),
    );
    await _settle(tester);
    await _shot(binding, tester, 'rx_01_intake');
    await tester.ensureVisible(find.text('Continue to Recording'));
    await tester.tap(find.text('Continue to Recording'));

    // ── Record ─────────────────────────────────────────────────────────
    expect(
      await _waitFor(
        tester,
        find.text('Start Consultation'),
        timeout: const Duration(seconds: 20),
      ),
      isTrue,
      reason: 'recording screen did not appear',
    );
    await tester.tap(find.text('Start Consultation'));
    // "Done" unlocks after five seconds of recording.
    await _waitFor(
      tester,
      find.text('00:07'),
      timeout: const Duration(seconds: 15),
    );
    await _shot(binding, tester, 'rx_02_recording');
    await tester.tap(find.text('Done'));

    // ── Real pipeline → Review ─────────────────────────────────────────
    final outcome = await _waitForAny(tester, [
      find.text('Review Prescription'),
      find.textContaining('No consultation was heard'),
      find.textContaining('error'),
    ], timeout: const Duration(minutes: 3));
    await _shot(binding, tester, 'rx_03_after_processing');
    expect(
      find.text('Review Prescription'),
      findsOneWidget,
      reason: 'processing did not reach Review: ${_visibleText(tester)}',
    );

    expect(find.textContaining('Paracetamol'), findsWidgets);
    expect(
      find.textContaining(RegExp('viral fever', caseSensitive: false)),
      findsWidgets,
    );
    expect(outcome, isNotNull);

    // ── Sign → PDF ─────────────────────────────────────────────────────
    await tester.tap(find.text('Sign & Generate PDF'));
    expect(
      await _waitFor(
        tester,
        find.text('Prescription Ready'),
        timeout: const Duration(seconds: 30),
      ),
      isTrue,
      reason: 'PDF screen did not open: ${_visibleText(tester)}',
    );
    // The preview is rasterised from the generated PDF.
    expect(
      await _waitFor(
        tester,
        find.byType(InteractiveViewer),
        timeout: const Duration(seconds: 60),
      ),
      isTrue,
      reason: 'the PDF was not generated: ${_visibleText(tester)}',
    );
    expect(find.text('Could not generate PDF'), findsNothing);
    await _shot(binding, tester, 'rx_04_pdf');
  });
}

/// Hands the pipeline a spoken consultation instead of microphone audio.
class _ClipRecorder implements RecordingService {
  final _amplitude = StreamController<double>.broadcast();
  String? _path;

  @override
  Stream<double> get amplitude => _amplitude.stream;

  @override
  Future<String> start() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'recordings', 'e2e_consultation.m4a'));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(base64Decode(consultationAudioBase64));
    _path = file.path;
    _amplitude.add(0.5);
    return file.path;
  }

  @override
  Future<String?> stop() async => _path;

  @override
  Future<Duration?> probeDuration(String path) async =>
      const Duration(seconds: 14);

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> cancel() async => _path = null;

  @override
  Future<void> dispose() => _amplitude.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

String _visibleText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data)
    .whereType<String>()
    .where((s) => s.trim().isNotEmpty)
    .take(40)
    .join(' | ');

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
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
