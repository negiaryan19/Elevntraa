import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rxvarta/app/router.dart';
import 'package:rxvarta/domain/models/doctor_profile.dart';
import 'package:rxvarta/features/auth/auth_redirect.dart';

/// Drives a real GoRouter (the app's own route table and redirect) through
/// the flows that used to go wrong, using push() exactly like the screens.
const _complete = DoctorProfile(
  name: 'Dr. Test',
  qualifications: 'MBBS',
  regNo: 'REG-1',
  clinicName: 'Clinic',
  clinicAddress: 'Somewhere',
  phone: '9999999999',
  signatureFileName: 'signature.png',
);

/// Stand-in for the provider reads the real router performs.
class _State extends ChangeNotifier {
  bool signedIn = false;
  bool recoveryPending = false;
  AsyncValue<DoctorProfile> profile = const AsyncData(DoctorProfile.empty);

  void update({bool? signed, bool? recovery, AsyncValue<DoctorProfile>? prof}) {
    signedIn = signed ?? signedIn;
    recoveryPending = recovery ?? recoveryPending;
    profile = prof ?? profile;
    notifyListeners();
  }
}

GoRouter _router(_State st, {required String initial}) => GoRouter(
  initialLocation: initial,
  refreshListenable: st,
  redirect: (context, state) => computeRedirect(
    hasBackend: true,
    signedIn: st.signedIn,
    profile: st.profile,
    location: state.uri.toString(),
    recoveryPending: st.recoveryPending,
  ),
  routes: [
    for (final route in AppRoute.values)
      GoRoute(
        path: route.path,
        name: route.name,
        builder: (context, state) =>
            Scaffold(body: Text('SCREEN:${route.name}')),
      ),
  ],
);

String _screen(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? '')
    .firstWhere((s) => s.startsWith('SCREEN:'), orElse: () => '<none>');

void main() {
  testWidgets('a verified reset code opens "Set new password", not home', (
    tester,
  ) async {
    final st = _State();
    final router = _router(st, initial: '/login');
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    router.push('/forgot');
    await tester.pumpAndSettle();
    router.push('/verify?email=a%40b.c&purpose=recovery');
    await tester.pumpAndSettle();
    expect(_screen(tester), 'SCREEN:verify');

    // Supabase signs the doctor in and emits passwordRecovery.
    st.update(signed: true, recovery: true, prof: const AsyncData(_complete));
    await tester.pumpAndSettle();
    expect(_screen(tester), 'SCREEN:resetPassword');

    // New password saved: the flag clears and the doctor can go home.
    st.update(recovery: false);
    router.go('/');
    await tester.pumpAndSettle();
    expect(_screen(tester), 'SCREEN:home');
  });

  testWidgets(
    'a profile reload does not throw a doctor out of a consultation',
    (tester) async {
      final st = _State()
        ..signedIn = true
        ..profile = const AsyncData(_complete);
      final router = _router(st, initial: '/');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      router.push('/intake');
      await tester.pumpAndSettle();
      router.push('/intake/form?patientId=p1');
      await tester.pumpAndSettle();
      expect(_screen(tester), 'SCREEN:intakeForm');

      // A backup restore reloads the profile while still holding it.
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = FutureProvider<DoctorProfile>((ref) async => _complete);
      await container.read(provider.future);
      container.invalidate(provider);
      final reloading = container.read(provider);
      expect(reloading.isLoading && reloading.hasValue, isTrue);
      st.update(prof: reloading);
      await tester.pumpAndSettle();
      expect(_screen(tester), 'SCREEN:intakeForm');

      st.update(prof: const AsyncData(_complete));
      await tester.pumpAndSettle();
      expect(router.state.uri.toString(), '/intake/form?patientId=p1');
    },
  );
}
