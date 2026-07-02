import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Reads the `.env` bundle loaded at startup. Only Supabase connection details
/// and the auto-login test credentials live here — all STT/LLM work happens in
/// the backend pipeline, so no Sarvam or Gemini keys ever touch the app.
class Env {
  Env._();

  static String? _value(String key) {
    final v = dotenv.maybeGet(key);
    if (v == null || v.trim().isEmpty) return null;
    return v.trim();
  }

  static String? get supabaseUrl => _value('SUPABASE_URL');
  static String? get supabaseAnonKey => _value('SUPABASE_ANON_KEY');
  static String? get autoLoginEmail => _value('AUTO_LOGIN_EMAIL');
  static String? get autoLoginPassword => _value('AUTO_LOGIN_PASSWORD');
}
