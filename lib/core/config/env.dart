import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Reads the `.env` bundle loaded at startup. API keys may also come from
/// secure storage (set by the doctor in onboarding); when both exist,
/// secure storage wins. This class only owns the `.env` source.
class Env {
  Env._();

  static String? _value(String key) {
    final v = dotenv.maybeGet(key);
    if (v == null || v.trim().isEmpty) return null;
    return v.trim();
  }

  static String? get sarvamApiKey => _value('SARVAM_API_KEY');
  static String? get geminiApiKey => _value('GEMINI_API_KEY');

  static const String geminiEndpointBase =
      'https://generativelanguage.googleapis.com/v1beta';
  static const String geminiModel = 'gemini-2.5-flash';

  static String? get supabaseUrl => _value('SUPABASE_URL');
  static String? get supabaseAnonKey => _value('SUPABASE_ANON_KEY');
  static String? get autoLoginEmail => _value('AUTO_LOGIN_EMAIL');
  static String? get autoLoginPassword => _value('AUTO_LOGIN_PASSWORD');
}
