import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxvarta/core/auth/secure_session_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The Supabase session (access + refresh token) used to sit in plain
/// SharedPreferences. It now lives in the Keystore / Keychain, doctors who
/// update stay signed in, a reinstall on iOS does not resurrect the previous
/// doctor's session, and an unreadable keychain entry signs out instead of
/// crashing the app on startup.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const key = 'sb-excmhjpttqjfyodynfza-auth-token';
  const marker = SecureSessionStorage.installMarkerKey;
  const session = '{"access_token":"new","refresh_token":"r1"}';
  const oldSession = '{"access_token":"old","refresh_token":"r0"}';

  /// What the in-memory keychain holds; the fake keeps this exact map.
  late Map<String, String> vault;

  Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  Future<SecureSessionStorage> started(
    SharedPreferences prefs, {
    FlutterSecureStorage vault = SecureSessionStorage.defaultVault,
  }) async {
    final storage = SecureSessionStorage(
      prefs: prefs,
      persistSessionKey: key,
      vault: vault,
    );
    await storage.initialize();
    return storage;
  }

  setUp(() {
    vault = {};
    FlutterSecureStorage.setMockInitialValues(vault);
  });

  test('uses the same key as supabase_flutter\'s default store', () {
    expect(
      SecureSessionStorage.sessionKeyFor(
        'https://excmhjpttqjfyodynfza.supabase.co',
      ),
      key,
    );
  });

  test('persists, reads and removes the session in secure storage', () async {
    final prefs = await prefsWith({marker: true});
    final storage = await started(prefs);

    expect(await storage.hasAccessToken(), isFalse);
    expect(await storage.accessToken(), isNull);

    await storage.persistSession(session);
    expect(await storage.hasAccessToken(), isTrue);
    expect(await storage.accessToken(), session);
    expect(vault[key], session);
    expect(prefs.getString(key), isNull, reason: 'never in plain prefs');

    await storage.removePersistedSession();
    expect(await storage.hasAccessToken(), isFalse);
    expect(vault, isEmpty);
  });

  test('an updated app moves the old plaintext session and stays signed '
      'in', () async {
    final prefs = await prefsWith({key: oldSession});
    final storage = await started(prefs);

    expect(await storage.accessToken(), oldSession);
    expect(prefs.getString(key), isNull, reason: 'plaintext copy removed');
    expect(prefs.getBool(marker), isTrue);
  });

  test('the old session wins over a Keychain leftover from a previous '
      'install', () async {
    // iOS: this app was uninstalled while signed in (Keychain kept the
    // session), an older build was installed and signed in, and now it is
    // updated. The first-run wipe must not take the doctor's live session.
    vault[key] = session;
    final prefs = await prefsWith({key: oldSession});
    final storage = await started(prefs);

    expect(await storage.accessToken(), oldSession);
    expect(prefs.getString(key), isNull);
  });

  test('a fresh install drops a session the Keychain kept from before '
      'the uninstall', () async {
    vault[key] = session;
    final prefs = await prefsWith({});
    final storage = await started(prefs);

    expect(await storage.hasAccessToken(), isFalse);
    expect(vault, isEmpty);
    expect(prefs.getBool(marker), isTrue);
  });

  test('a normal relaunch keeps the session', () async {
    vault[key] = session;
    final prefs = await prefsWith({marker: true});
    final storage = await started(prefs);

    expect(await storage.accessToken(), session);
  });

  test('a stale plaintext copy never replaces the secure session', () async {
    vault[key] = session;
    final prefs = await prefsWith({marker: true, key: oldSession});
    final storage = await started(prefs);

    expect(await storage.accessToken(), session);
    expect(prefs.getString(key), isNull);
  });

  test(
    'signing in after "Delete all local data" survives a relaunch',
    () async {
      final prefs = await prefsWith({marker: true});
      final storage = await started(prefs);
      // The wiper clears every preference except language and theme.
      await prefs.remove(marker);

      await storage.persistSession(session);
      expect(prefs.getBool(marker), isTrue);

      final relaunched = await started(prefs);
      expect(await relaunched.accessToken(), session);
    },
  );

  test('an unreadable session signs out and is deleted', () async {
    vault[key] = session;
    final prefs = await prefsWith({marker: true});
    final storage = await started(prefs, vault: _FailingVault(failRead: true));

    expect(await storage.hasAccessToken(), isTrue);
    expect(await storage.accessToken(), isNull);
    expect(vault, isEmpty);
  });

  test('a keychain that cannot even be queried reads as signed out', () async {
    vault[key] = session;
    final prefs = await prefsWith({marker: true});
    final storage = await started(prefs, vault: _FailingVault(failQuery: true));

    expect(await storage.hasAccessToken(), isFalse);
    expect(vault, isEmpty);
  });

  test(
    'a reinstall whose wipe fails does not sign the previous doctor back in',
    () async {
      // The iOS Keychain survives an uninstall, so a session is still there on
      // the new installation's first launch. If the wipe that should remove it
      // fails, the session must be treated as absent rather than handed to
      // Supabase — otherwise the new doctor lands in the old doctor's account.
      vault[key] = oldSession;
      final prefs = await prefsWith({});
      final storage = await started(
        prefs,
        vault: _FailingVault(failDelete: true),
      );

      expect(await storage.hasAccessToken(), isFalse);
      expect(await storage.accessToken(), isNull);
      expect(prefs.getBool(marker), isNull, reason: 'retried next launch');

      // Signing in overwrites whatever the failed wipe left, so reads are
      // safe again within the same launch.
      await storage.persistSession(session);
      expect(await storage.accessToken(), session);
      expect(prefs.getBool(marker), isTrue);
    },
  );

  test('the wipe is retried on the next launch and then succeeds', () async {
    vault[key] = oldSession;
    final prefs = await prefsWith({});
    await started(prefs, vault: _FailingVault(failDelete: true));
    expect(vault[key], oldSession, reason: 'the failed wipe left it');

    final relaunched = await started(prefs);
    expect(await relaunched.accessToken(), isNull);
    expect(vault, isEmpty);
    expect(prefs.getBool(marker), isTrue);
  });

  test(
    'sign-out also drops a plaintext session a failed migration left',
    () async {
      // First launch after the update: the Keystore write fails, so the old
      // build's plaintext session stays in SharedPreferences for a retry.
      final flaky = _FailingVault(failWrite: true);
      final prefs = await prefsWith({key: oldSession});
      final storage = await started(prefs, vault: flaky);
      expect(prefs.getString(key), oldSession);

      // The doctor signs out to hand the phone over.
      await storage.removePersistedSession();
      expect(prefs.getString(key), isNull);

      // Nothing may come back on the next launch.
      final relaunched = await started(prefs);
      expect(await relaunched.accessToken(), isNull);
    },
  );

  test(
    'signing in supersedes a plaintext session a failed migration left',
    () async {
      final flaky = _FailingVault(failWrite: true);
      final prefs = await prefsWith({key: oldSession});
      final storage = await started(prefs, vault: flaky);

      // The Keystore recovers and the doctor signs in again.
      flaky.failWrite = false;
      await storage.persistSession(session);
      expect(prefs.getString(key), isNull, reason: 'superseded');

      // Sign out, relaunch: the old account must not be migrated back in.
      await storage.removePersistedSession();
      final relaunched = await started(prefs);
      expect(await relaunched.accessToken(), isNull);
    },
  );

  test(
    'a failed migration does not crash and is retried next launch',
    () async {
      final prefs = await prefsWith({key: oldSession});
      final storage = await started(
        prefs,
        vault: _FailingVault(failWrite: true),
      );

      expect(await storage.hasAccessToken(), isFalse);
      expect(prefs.getString(key), oldSession, reason: 'kept for the retry');
      expect(prefs.getBool(marker), isNull);

      final retried = await started(prefs);
      expect(await retried.accessToken(), oldSession);
      expect(prefs.getString(key), isNull);
    },
  );

  group('forThisDevice', () {
    const url = 'https://excmhjpttqjfyodynfza.supabase.co';
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    Future<LocalStorage> on(TargetPlatform platform) async {
      debugDefaultTargetPlatformOverride = platform;
      return SecureSessionStorage.forThisDevice(
        prefs: await prefsWith({}),
        supabaseUrl: url,
      );
    }

    test('phones keep the session in the Keystore / Keychain', () async {
      expect(await on(TargetPlatform.android), isA<SecureSessionStorage>());
      expect(await on(TargetPlatform.iOS), isA<SecureSessionStorage>());
    });

    test('ad-hoc signed macOS dev builds keep the plain store', () async {
      final storage = await on(TargetPlatform.macOS);
      expect(storage, isA<SharedPreferencesLocalStorage>());
      expect((storage as SharedPreferencesLocalStorage).persistSessionKey, key);
    });
  });
}

/// The in-memory keychain with chosen operations failing the way a lost
/// Android Keystore key does after a backup restore.
class _FailingVault extends FlutterSecureStorage {
  _FailingVault({
    this.failRead = false,
    this.failQuery = false,
    this.failWrite = false,
    this.failDelete = false,
  });

  final bool failRead;
  final bool failQuery;

  /// Mutable so a test can model a transient Keystore error that clears up
  /// later in the same launch.
  bool failWrite;
  final bool failDelete;

  static final _keystoreError = PlatformException(
    code: 'Exception encountered',
    message: 'javax.crypto.BadPaddingException: error:1e000065',
  );

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) => failRead ? Future.error(_keystoreError) : super.read(key: key);

  @override
  Future<bool> containsKey({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) => failQuery ? Future.error(_keystoreError) : super.containsKey(key: key);

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) => failWrite
      ? Future.error(_keystoreError)
      : super.write(key: key, value: value);

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) => failDelete ? Future.error(_keystoreError) : super.delete(key: key);
}
