import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxvarta/core/auth/auth_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Verifying a password-reset code signs the doctor in. The router must keep
/// them on "Set new password" until they save one; this flag is how it
/// knows. These tests pin that it follows the real Supabase auth events.
void main() {
  late StreamController<AuthState> auth;
  late ProviderContainer container;

  setUp(() {
    auth = StreamController<AuthState>();
    container = ProviderContainer(
      overrides: [authStateProvider.overrideWith((ref) => auth.stream)],
    );
    // Instantiate the flag so it is listening, as the router does.
    container.listen(passwordRecoveryPendingProvider, (_, _) {});
  });

  tearDown(() async {
    container.dispose();
    await auth.close();
  });

  Future<void> emit(AuthChangeEvent event) async {
    auth.add(AuthState(event, null));
    // Let the stream deliver and the listener run.
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  bool pending() => container.read(passwordRecoveryPendingProvider);

  test('starts false', () {
    expect(pending(), isFalse);
  });

  test('a verified reset code sets it', () async {
    await emit(AuthChangeEvent.passwordRecovery);
    expect(pending(), isTrue);
  });

  test('saving the new password clears it', () async {
    await emit(AuthChangeEvent.passwordRecovery);
    await emit(AuthChangeEvent.userUpdated);
    expect(pending(), isFalse);
  });

  test('signing out clears it', () async {
    await emit(AuthChangeEvent.passwordRecovery);
    await emit(AuthChangeEvent.signedOut);
    expect(pending(), isFalse);
  });

  test('an ordinary sign-in does not set it', () async {
    await emit(AuthChangeEvent.signedIn);
    await emit(AuthChangeEvent.tokenRefreshed);
    expect(pending(), isFalse);
  });

  test('clear() resets it immediately', () async {
    await emit(AuthChangeEvent.passwordRecovery);
    container.read(passwordRecoveryPendingProvider.notifier).clear();
    expect(pending(), isFalse);
  });
}
