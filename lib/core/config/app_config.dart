/// Build-time configuration injected with `--dart-define` /
/// `--dart-define-from-file=config/app_config.json`.
///
/// Only values that are safe to ship inside the binary live here: the Supabase
/// project URL and its *publishable* (anon) key are designed to be public and
/// are useless without a signed-in doctor's JWT because every table and bucket
/// is protected by row-level security. Provider secrets (Sarvam, Gemini,
/// service-role key) never reach the app — they live in Supabase Edge Function
/// secrets. Nothing is read from a bundled `.env` any more.
class AppConfig {
  AppConfig._();

  static const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );
  static const String _supportEmail = String.fromEnvironment('SUPPORT_EMAIL');
  static const String _supportWhatsapp = String.fromEnvironment(
    'SUPPORT_WHATSAPP',
  );
  static const String _privacyUrl = String.fromEnvironment('PRIVACY_URL');
  static const String _termsUrl = String.fromEnvironment('TERMS_URL');

  static String? _nonEmpty(String v) => v.trim().isEmpty ? null : v.trim();

  static String? get supabaseUrl => _nonEmpty(_supabaseUrl);
  static String? get supabaseAnonKey => _nonEmpty(_supabaseAnonKey);

  /// True when the backend can be reached at all. The app refuses to start a
  /// consultation without it and tells the doctor why (item 11).
  static bool get hasBackend => supabaseUrl != null && supabaseAnonKey != null;

  /// Support contacts shown in Settings > Help & Support (item 27). When both
  /// are unset the tile explains that support is not configured instead of
  /// pretending to work.
  static String? get supportEmail => _nonEmpty(_supportEmail);
  static String? get supportWhatsapp => _nonEmpty(_supportWhatsapp);

  /// Optional hosted copies of the legal documents; the bundled versions are
  /// always available offline.
  static String? get privacyUrl => _nonEmpty(_privacyUrl);
  static String? get termsUrl => _nonEmpty(_termsUrl);
}
