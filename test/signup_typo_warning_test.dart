import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rxvarta/core/auth/auth_providers.dart';
import 'package:rxvarta/features/auth/presentation/auth_widgets.dart';
import 'package:rxvarta/features/auth/presentation/signup_screen.dart';
import 'package:rxvarta/l10n/app_localizations.dart';

/// `doctor@gmial.com` is a well-formed address, so it passed validation and
/// the verification code went to a domain that cannot receive it: the doctor
/// waited for a code that never came. Sign-up now warns once, offers the
/// likely address, and still lets a real address through on a second tap.
void main() {
  // Owned by the test, not the fake: Riverpod builds the override lazily,
  // so when the screen (correctly) never calls signUp the fake is never
  // created, and the assertion still needs something to read.
  late List<String> signUps;
  setUp(() => signUps = <String>[]);

  Future<void> pumpSignUp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/signup',
      routes: [
        GoRoute(path: '/signup', builder: (_, _) => const SignUpScreen()),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => _RecordingAuth(ref, signUps),
          ),
        ],
        child: MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fillForm(WidgetTester tester, String email) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), email);
    await tester.enterText(fields.at(1), 'Clinic@2026');
    await tester.enterText(fields.at(2), 'Clinic@2026');
    await tester.pump();
  }

  Future<void> tapCreate(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(AuthPrimaryButton, 'Create account'));
    // Not pumpAndSettle: after a sign-up the button keeps its spinner while
    // the app's router redirects, and this test has no redirect, so the
    // animation would never settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('a likely typo is not sent on the first tap', (tester) async {
    await pumpSignUp(tester);
    await fillForm(tester, 'doctor@gmial.com');
    await tapCreate(tester);

    expect(signUps, isEmpty);
    expect(
      find.textContaining('Did you mean doctor@gmail.com?'),
      findsOneWidget,
    );
    expect(find.widgetWithText(AuthLink, 'doctor@gmail.com'), findsOneWidget);
  });

  testWidgets('tapping the suggestion fixes the address', (tester) async {
    await pumpSignUp(tester);
    await fillForm(tester, 'doctor@gmial.com');
    await tapCreate(tester);

    await tester.tap(find.widgetWithText(AuthLink, 'doctor@gmail.com'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Did you mean'), findsNothing);

    await tapCreate(tester);
    expect(signUps, ['doctor@gmail.com']);
  });

  testWidgets('a second tap keeps the address as typed', (tester) async {
    await pumpSignUp(tester);
    await fillForm(tester, 'doctor@gmial.com');
    await tapCreate(tester);
    await tapCreate(tester);

    expect(signUps, ['doctor@gmial.com']);
  });

  testWidgets('editing the address retires the warning', (tester) async {
    await pumpSignUp(tester);
    await fillForm(tester, 'doctor@gmial.com');
    await tapCreate(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'doctor@yaho.com');
    await tester.pump();
    expect(find.textContaining('Did you mean doctor@gmail.com?'), findsNothing);

    // A different typo is its own first tap: warned, not sent.
    await tapCreate(tester);
    expect(signUps, isEmpty);
    expect(
      find.textContaining('Did you mean doctor@yahoo.com?'),
      findsOneWidget,
    );
  });

  testWidgets('an ordinary address is sent on the first tap', (tester) async {
    await pumpSignUp(tester);
    await fillForm(tester, 'doctor@apollo.co.in');
    await tapCreate(tester);

    expect(signUps, ['doctor@apollo.co.in']);
    expect(find.textContaining('Did you mean'), findsNothing);
  });
}

/// Records sign-ups instead of calling Supabase. Answers "signed in" so the
/// screen does not navigate: the router is not what is under test.
class _RecordingAuth extends AuthController {
  _RecordingAuth(super.ref, this.signUps);

  final List<String> signUps;

  @override
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
  }) async {
    signUps.add(email);
    return SignUpOutcome.signedIn;
  }
}
