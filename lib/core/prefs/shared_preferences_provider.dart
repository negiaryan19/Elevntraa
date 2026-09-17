import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The single, preloaded [SharedPreferences] instance.
///
/// `main()` awaits `SharedPreferences.getInstance()` once before `runApp` and
/// overrides this provider in the root `ProviderScope`, so every consumer can
/// read preferences *synchronously* in `build()` — no async flash of a default
/// value (roadmap item 22). Tests override it the same way with
/// `SharedPreferences.setMockInitialValues({})`.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in the root ProviderScope '
    'with the preloaded SharedPreferences instance (see main.dart).',
  );
});
