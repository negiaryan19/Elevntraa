import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/auth/secure_session_storage.dart';
import 'core/config/app_config.dart';
import 'core/prefs/shared_preferences_provider.dart';
import 'core/utils/app_paths.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cache the documents directory so attachment paths resolve synchronously.
  await AppPaths.init();

  // Preload preferences once so locale/theme resolve on the first frame.
  final prefs = await SharedPreferences.getInstance();

  await _initBackend(prefs);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const RxvartaApp(),
    ),
  );
}

/// Connects to Supabase when the build carries a project URL + publishable
/// key (`--dart-define-from-file=config/app_config.json`). Nothing is read
/// from a bundled `.env` and nobody is signed in automatically: the router
/// sends a doctor without a session to Login (roadmap items 1, 8).
///
/// The session (the tokens that keep a doctor signed in) is kept encrypted in
/// the Android Keystore / iOS Keychain, not in plain SharedPreferences; see
/// [SecureSessionStorage].
Future<void> _initBackend(SharedPreferences prefs) async {
  if (!AppConfig.hasBackend) {
    debugPrint(
      '[config] SUPABASE_URL / SUPABASE_ANON_KEY are not set — sign-in is '
      'disabled. Copy config/app_config.example.json to '
      'config/app_config.json and run with '
      '--dart-define-from-file=config/app_config.json.',
    );
    return;
  }

  await Supabase.initialize(
    url: AppConfig.supabaseUrl!,
    publishableKey: AppConfig.supabaseAnonKey!,
    authOptions: FlutterAuthClientOptions(
      localStorage: SecureSessionStorage.forThisDevice(
        prefs: prefs,
        supabaseUrl: AppConfig.supabaseUrl!,
      ),
    ),
  );

  // supabase_flutter restores the persisted session asynchronously after
  // `initialize` returns. Wait for the first auth event (the stream replays
  // it, so an `initialSession` that already fired is still delivered) so the
  // first frame knows whether the doctor is signed in — otherwise every cold
  // start would flash the login screen before jumping to Home.
  try {
    await Supabase.instance.client.auth.onAuthStateChange.first.timeout(
      const Duration(seconds: 5),
    );
  } on TimeoutException {
    debugPrint('[auth] session restore did not settle in 5 s; continuing.');
  } catch (e) {
    // e.g. a stored refresh token the server rejected: gotrue has already
    // cleared it and the router shows Login.
    debugPrint('[auth] session restore failed: $e');
  }
}
