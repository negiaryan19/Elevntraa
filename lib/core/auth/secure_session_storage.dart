import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Keeps the doctor's Supabase session encrypted at rest.
///
/// The app never stores the password: Supabase Auth keeps only a bcrypt hash
/// on the server. What the phone does keep is the session (access token plus
/// refresh token), and a refresh token is as good as a login. supabase_flutter
/// writes it to plain SharedPreferences by default, which any backup, rooted
/// phone or file dump can read. This store puts it in the Android Keystore
/// (AES-GCM key wrapped by a Keystore RSA key) or the iOS Keychain instead.
///
/// [initialize] also runs three one-off steps, in this order:
///
/// 1. On the first launch of an installation (no [installMarkerKey] in
///    SharedPreferences, which uninstalling wipes) it deletes any session
///    already in secure storage. The iOS Keychain survives an uninstall, so
///    without this a reinstalled app would sign the previous doctor back in.
/// 2. It moves a session left in SharedPreferences by an older build into
///    secure storage, so the update does not sign anyone out. This runs
///    after step 1, so an upgrading doctor's session is never the one wiped.
/// 3. It sets [installMarkerKey].
///
/// A session that cannot be read (for example an Android Keystore key lost
/// in a backup restore, "BadPaddingException") counts as signed out and is
/// deleted, so a broken keychain never stops the app from starting.
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage({
    required this._prefs,
    required this.persistSessionKey,
    this._vault = defaultVault,
  });

  /// The Keystore / Keychain the session lives in.
  ///
  /// iOS: readable once the phone has been unlocked after boot, so a token
  /// refresh that runs while the screen is locked (a long recording) still
  /// works. `this_device` keeps the item out of backups: a new phone signs in
  /// again rather than inheriting the session. Android: the plugin defaults
  /// (Keystore-wrapped AES-GCM; data it cannot decrypt is deleted).
  static const defaultVault = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Set once this installation has prepared secure storage (see class docs).
  @visibleForTesting
  static const installMarkerKey = 'secure_session_ready';

  /// Key of the session, in secure storage and in the SharedPreferences an
  /// older build used.
  final String persistSessionKey;

  final SharedPreferences _prefs;
  final FlutterSecureStorage _vault;

  /// The key supabase_flutter's default [SharedPreferencesLocalStorage] uses
  /// for [supabaseUrl] (see `Supabase.initialize`). The migration needs the
  /// exact same key to find the session an older build saved.
  static String sessionKeyFor(String supabaseUrl) =>
      'sb-${Uri.parse(supabaseUrl).host.split('.').first}-auth-token';

  /// Session storage for the platform the app runs on.
  ///
  /// Phones get [SecureSessionStorage]. macOS, where the app only runs for
  /// development and integration tests, keeps supabase_flutter's plain
  /// SharedPreferences store: those builds are ad-hoc signed (no Apple team),
  /// and an ad-hoc signed app cannot use the Keychain here. The
  /// data-protection keychain fails with -34018 (missing entitlement), adding
  /// the `keychain-access-groups` entitlement makes macOS kill the app at
  /// launch, and the older file keychain asks for the Mac password after
  /// every rebuild because each build has a new code signature.
  static LocalStorage forThisDevice({
    required SharedPreferences prefs,
    required String supabaseUrl,
  }) {
    final key = sessionKeyFor(supabaseUrl);
    final isPhone =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    return isPhone
        ? SecureSessionStorage(prefs: prefs, persistSessionKey: key)
        : SharedPreferencesLocalStorage(persistSessionKey: key);
  }

  /// Set when the first-launch wipe failed, so whatever is in the vault may
  /// still belong to the previous installation. Blocks reads for the rest of
  /// this launch; see [initialize].
  bool _staleSessionUnwiped = false;

  @override
  Future<void> initialize() async {
    if (_prefs.getBool(installMarkerKey) != true) {
      try {
        await _vault.delete(key: persistSessionKey);
      } catch (e) {
        // The iOS Keychain survives an uninstall, so the session still in
        // there may be the PREVIOUS doctor's. If it cannot be deleted, the
        // one thing we must not do is hand it to Supabase and sign this
        // installation in as them. Treat the vault as empty for this launch
        // and leave the marker unset so the next launch tries the wipe again.
        _staleSessionUnwiped = true;
        debugPrint('[auth] first-launch session wipe failed, ignoring it: $e');
        return;
      }
    }
    try {
      final legacy = _prefs.getString(persistSessionKey);
      if (legacy != null) {
        if (!await _vault.containsKey(key: persistSessionKey)) {
          await _vault.write(key: persistSessionKey, value: legacy);
        }
        await _prefs.remove(persistSessionKey);
      }
      await _markInstall();
    } catch (e) {
      // Leave the marker unset so the next launch tries again. A plaintext
      // session that could not be moved stays where it was until then.
      debugPrint('[auth] could not prepare secure session storage: $e');
    }
  }

  @override
  Future<bool> hasAccessToken() async {
    if (_staleSessionUnwiped) return false;
    try {
      return await _vault.containsKey(key: persistSessionKey);
    } catch (e) {
      await _discard(e);
      return false;
    }
  }

  @override
  Future<String?> accessToken() async {
    if (_staleSessionUnwiped) return null;
    try {
      return await _vault.read(key: persistSessionKey);
    } catch (e) {
      await _discard(e);
      return null;
    }
  }

  @override
  Future<void> removePersistedSession() async {
    // A plaintext session an older build left behind survives here only when
    // its migration failed. Sign-out must take it too, or the next launch
    // would migrate it into the vault and sign that account back in — on a
    // phone the doctor just signed out of to hand over. Prefs go first so a
    // failing Keystore delete still leaves no plaintext token behind.
    await _prefs.remove(persistSessionKey);
    await _vault.delete(key: persistSessionKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    await _vault.write(key: persistSessionKey, value: persistSessionString);
    // Whatever the failed wipe left behind has just been overwritten by this
    // installation's own session, so reads are safe again.
    _staleSessionUnwiped = false;
    // This installation's own session supersedes any plaintext one an older
    // build left; it must never be migrated over the top of it later.
    await _prefs.remove(persistSessionKey);
    // Settings > "Delete all local data" clears SharedPreferences, marker
    // included. Setting it again here keeps the next launch from wiping the
    // session of a doctor who signed back in afterwards.
    await _markInstall();
  }

  Future<void> _markInstall() async {
    if (_prefs.getBool(installMarkerKey) == true) return;
    await _prefs.setBool(installMarkerKey, true);
  }

  /// Treats an unreadable session as signed out and deletes it so the next
  /// launch does not trip over it again.
  Future<void> _discard(Object error) async {
    debugPrint('[auth] stored session unreadable, signing out: $error');
    try {
      await _vault.delete(key: persistSessionKey);
    } catch (e) {
      debugPrint('[auth] could not delete the unreadable session: $e');
    }
  }
}
