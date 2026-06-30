import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/env.dart';
import 'core/utils/app_paths.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cache the documents directory so attachment paths resolve synchronously.
  await AppPaths.init();

  // Load .env. A missing file is non-fatal — onboarding can also write
  // keys to secure storage, so first launch without a bundled .env is OK.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Intentional: missing .env on first run is expected.
  }

  final supabaseUrl = Env.supabaseUrl;
  final supabaseAnonKey = Env.supabaseAnonKey;
  if (supabaseUrl != null && supabaseAnonKey != null) {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
    await _autoLogin();
  } else {
    debugPrint('[Supabase] URL or anon key missing — backend calls will fail.');
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: RxvartaApp()));
}

/// Signs in with the dev/test account from .env if no session is active.
/// Failures are logged but never crash the app.
// TODO: Phase 8 — replace with real OTP login
Future<void> _autoLogin() async {
  try {
    final client = Supabase.instance.client;
    if (client.auth.currentSession != null) return;

    final email = Env.autoLoginEmail;
    final password = Env.autoLoginPassword;
    if (email == null || password == null) {
      debugPrint(
        '[Supabase] AUTO_LOGIN_EMAIL/PASSWORD not set — skipping auto-login.',
      );
      return;
    }

    await client.auth.signInWithPassword(email: email, password: password);
    debugPrint('[Supabase] Auto-login succeeded.');
  } catch (e) {
    debugPrint(
      '[Supabase] Auto-login failed: $e — pipeline calls will return "Not authenticated".',
    );
  }
}
