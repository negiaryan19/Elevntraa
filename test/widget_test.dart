import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rxvarta/app/app.dart';
import 'package:rxvarta/core/prefs/shared_preferences_provider.dart';

void main() {
  testWidgets('App boots to the login screen without a backend', (
    tester,
  ) async {
    // Tests run without --dart-define, so AppConfig.hasBackend is false and
    // nothing may touch Supabase. The router must still land somewhere
    // sensible: the login screen with its "not configured" explanation.
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const RxvartaApp(),
      ),
    );

    // Can't use pumpAndSettle — entrance animations use staggered timers.
    // Pump a fixed window so they fire and the providers settle.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Rxvarta'), findsWidgets);
    expect(find.text('App not configured'), findsOneWidget);
    // No sign-in form and no home content without a backend.
    expect(find.text('Sign in'), findsNothing);
    expect(find.text('Start new consultation'), findsNothing);
  });
}
