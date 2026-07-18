import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'locale_provider.dart';

const String kPrescriptionLocaleKey = 'prescription_locale';

/// The doctor's *default* language for prescription PDFs.
///
/// Deliberately separate from [appLocaleProvider]: a doctor may run the app
/// in Telugu but still issue English prescriptions (pharmacists read English).
/// Defaults to English, and each consultation can override it at intake or on
/// the review screen.
class PrescriptionLocaleNotifier extends Notifier<String> {
  @override
  String build() {
    _load();
    return 'en';
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(kPrescriptionLocaleKey);
    if (code == null) return;
    if (kSupportedLanguages.any((l) => l.code == code)) state = code;
  }

  Future<void> setLocale(String code) async {
    state = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrescriptionLocaleKey, code);
  }
}

final prescriptionLocaleProvider =
    NotifierProvider<PrescriptionLocaleNotifier, String>(
      PrescriptionLocaleNotifier.new,
    );
