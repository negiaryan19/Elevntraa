import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kAppLocaleKey = 'app_locale';

/// Languages the app UI is available in. Code is the ARB suffix.
class AppLanguage {
  const AppLanguage(this.code, this.englishName, this.nativeName);
  final String code;
  final String englishName;
  final String nativeName;
}

const List<AppLanguage> kSupportedLanguages = [
  AppLanguage('en', 'English', 'English'),
  AppLanguage('hi', 'Hindi', 'हिन्दी'),
  AppLanguage('te', 'Telugu', 'తెలుగు'),
  AppLanguage('mr', 'Marathi', 'मराठी'),
  AppLanguage('ta', 'Tamil', 'தமிழ்'),
  AppLanguage('kn', 'Kannada', 'ಕನ್ನಡ'),
  AppLanguage('bn', 'Bengali', 'বাংলা'),
  AppLanguage('gu', 'Gujarati', 'ગુજરાતી'),
];

class AppLocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    _load();
    return const Locale('en');
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(kAppLocaleKey);
    if (code == null) return;
    final known = kSupportedLanguages.any((l) => l.code == code);
    if (known) state = Locale(code);
  }

  Future<void> setLocale(String code) async {
    state = Locale(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kAppLocaleKey, code);
  }
}

final appLocaleProvider = NotifierProvider<AppLocaleNotifier, Locale>(
  AppLocaleNotifier.new,
);
