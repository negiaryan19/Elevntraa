import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../prefs/shared_preferences_provider.dart';

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

bool isSupportedLanguage(String code) =>
    kSupportedLanguages.any((l) => l.code == code);

/// The UI locale. Resolved synchronously on first build (roadmap item 22):
/// the saved choice wins; otherwise the device language when the app ships
/// it, else English. No async load, so there is no flash of the wrong
/// language on a cold start.
class AppLocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final saved = prefs.getString(kAppLocaleKey);
    if (saved != null && isSupportedLanguage(saved)) return Locale(saved);

    final device =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return Locale(isSupportedLanguage(device) ? device : 'en');
  }

  Future<void> setLocale(String code) async {
    if (!isSupportedLanguage(code)) return;
    state = Locale(code);
    await ref.read(sharedPreferencesProvider).setString(kAppLocaleKey, code);
  }
}

final appLocaleProvider = NotifierProvider<AppLocaleNotifier, Locale>(
  AppLocaleNotifier.new,
);
