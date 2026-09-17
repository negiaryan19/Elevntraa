import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/config/app_config.dart';
import '../../../core/errors/failure.dart';
import '../../../core/utils/app_paths.dart';
import '../../../domain/models/doctor_profile.dart';

/// Persists one doctor's profile (roadmap items 2, 3, 4, 5, 6):
///
/// * locally as `users/<uid>/doctor_profile.json` (+ `signature.png`) so the
///   letterhead and signature are available offline, and
/// * remotely in `public.doctors` (+ the private `doctor-signatures` bucket)
///   so a doctor who reinstalls or changes phone gets the profile back and
///   every device prints the same identity.
///
/// Local is the source of truth for the running app; the remote copy is
/// pushed after every save and pulled on start-up. The newer `updated_at`
/// wins when the two differ. A save that cannot reach the server is kept
/// locally with `dirty = true` and pushed on the next start / explicit sync.
class DoctorProfileRepository {
  DoctorProfileRepository({required this.uid, this.client});

  static const _bucket = 'doctor-signatures';
  static const _table = 'doctors';
  static const _profileFileName = 'doctor_profile.json';

  final String uid;

  /// Injectable for tests; defaults to the app-wide client.
  final SupabaseClient? client;

  SupabaseClient get _supabase => client ?? Supabase.instance.client;

  String get _dir => AppPaths.userDir(uid);
  File get _profileFile => File(p.join(_dir, _profileFileName));

  /// Absolute path of the doctor's signature PNG for [profile], or null.
  File? signatureFile(DoctorProfile profile) {
    final name = profile.signatureFileName;
    if (name == null || name.isEmpty) return null;
    return File(p.join(_dir, name));
  }

  String get _remoteSignaturePath => '$uid/signature.png';

  // ── Local cache ───────────────────────────────────────────────────────

  /// Returns the cached profile and whether it still has un-pushed changes.
  Future<({DoctorProfile profile, bool dirty})?> loadLocal() async {
    try {
      if (!await _profileFile.exists()) return null;
      final raw = await _profileFile.readAsString();
      if (raw.trim().isEmpty) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      var profile = DoctorProfile.fromJson(json);
      // A signature the JSON claims to have but whose file is gone (e.g. the
      // user folder was partially deleted) must not count as a signature.
      final sig = signatureFile(profile);
      if (sig != null && !await sig.exists()) {
        profile = profile.copyWith(
          signatureFileName: null,
          signatureUpdatedAt: null,
        );
      }
      return (profile: profile, dirty: json['dirty'] == true);
    } catch (e) {
      // Corrupt cache: better to ask the doctor to re-enter than to guess.
      debugPrint('[profile] local cache unreadable: $e');
      return null;
    }
  }

  Future<void> saveLocal(DoctorProfile profile, {required bool dirty}) async {
    try {
      final json = profile.toJson()..['dirty'] = dirty;
      final tmp = File('${_profileFile.path}.tmp');
      await tmp.writeAsString(jsonEncode(json), flush: true);
      await tmp.rename(_profileFile.path);
    } on FileSystemException catch (e) {
      throw StorageFailure('Could not save profile on this device.', cause: e);
    }
  }

  /// Older builds stored a single device-wide `doctor_profile.json`. Move it
  /// into the first signed-in doctor's folder once so nothing is lost.
  Future<void> migrateLegacy() async {
    try {
      if (await _profileFile.exists()) return;
      final legacy = File(p.join(AppPaths.documentsDir, _profileFileName));
      if (!await legacy.exists()) return;
      await legacy.rename(_profileFile.path);
      // Legacy files never had a signature or timestamps; mark dirty so it
      // gets pushed to the account on first sync.
      final loaded = await loadLocal();
      if (loaded != null) await saveLocal(loaded.profile, dirty: true);
    } catch (e) {
      debugPrint('[profile] legacy migration skipped: $e');
    }
  }

  Future<Uint8List?> signatureBytes(DoctorProfile profile) async {
    final f = signatureFile(profile);
    if (f == null) return null;
    try {
      if (!await f.exists()) return null;
      return await f.readAsBytes();
    } catch (e) {
      debugPrint('[profile] signature unreadable: $e');
      return null;
    }
  }

  /// Deletes the cached profile and signature on this device only.
  Future<void> clearLocal() async {
    for (final f in [
      _profileFile,
      File(p.join(_dir, DoctorProfile.defaultSignatureFileName)),
    ]) {
      try {
        if (await f.exists()) await f.delete();
      } catch (e) {
        debugPrint('[profile] could not delete ${f.path}: $e');
      }
    }
  }

  // ── Remote (Supabase) ─────────────────────────────────────────────────

  bool get _hasBackend => AppConfig.hasBackend;

  /// Fetches the account's profile row. Downloads the signature when the
  /// server copy is newer than the local file (or there is no local file).
  /// Returns null when no row exists yet. Throws [NetworkFailure] /
  /// [ApiFailure] on failure so callers can decide whether to wait.
  Future<DoctorProfile?> fetchRemote({DoctorProfile? local}) async {
    if (!_hasBackend) return null;
    final Map<String, dynamic>? row;
    try {
      row = await _supabase.from(_table).select().eq('id', uid).maybeSingle();
    } on PostgrestException catch (e) {
      throw ApiFailure('Could not load profile: ${e.message}', cause: e);
    } catch (e) {
      throw NetworkFailure('Could not load profile: $e', cause: e);
    }
    if (row == null) return null;

    final remoteSigAt = DoctorProfile.fromRemoteJson(row).signatureUpdatedAt;
    String? localSigName = local?.signatureFileName;
    final localSigAt = local?.signatureUpdatedAt;
    final localSigExists = local != null && signatureFile(local) != null
        ? await signatureFile(local)!.exists()
        : false;

    if (remoteSigAt != null &&
        (!localSigExists ||
            localSigAt == null ||
            remoteSigAt.isAfter(localSigAt))) {
      try {
        final bytes = await _supabase.storage
            .from(_bucket)
            .download(_remoteSignaturePath);
        final f = File(p.join(_dir, DoctorProfile.defaultSignatureFileName));
        await f.writeAsBytes(bytes, flush: true);
        localSigName = DoctorProfile.defaultSignatureFileName;
      } catch (e) {
        // Keep whatever we have locally; the letterhead still works.
        debugPrint('[profile] signature download failed: $e');
        if (!localSigExists) localSigName = null;
      }
    } else if (!localSigExists) {
      localSigName = null;
    }

    return DoctorProfile.fromRemoteJson(row, signatureFileName: localSigName);
  }

  /// Upserts the profile row. The signature image is pushed separately by
  /// [uploadSignature].
  Future<void> pushRemote(DoctorProfile profile) async {
    if (!_hasBackend) throw const AuthFailure('Backend is not configured.');
    try {
      await _supabase.from(_table).upsert({
        ...profile.toRemoteJson(),
        'id': uid,
      });
    } on PostgrestException catch (e) {
      throw ApiFailure('Could not sync profile: ${e.message}', cause: e);
    } catch (e) {
      throw NetworkFailure('Could not sync profile: $e', cause: e);
    }
  }

  Future<void> uploadSignature(Uint8List png) async {
    if (!_hasBackend) throw const AuthFailure('Backend is not configured.');
    try {
      await _supabase.storage
          .from(_bucket)
          .uploadBinary(
            _remoteSignaturePath,
            png,
            fileOptions: const FileOptions(
              contentType: 'image/png',
              upsert: true,
            ),
          );
    } on StorageException catch (e) {
      throw ApiFailure('Could not upload signature: ${e.message}', cause: e);
    } catch (e) {
      throw NetworkFailure('Could not upload signature: $e', cause: e);
    }
  }

  /// Writes the PNG to the doctor's folder and returns the updated profile
  /// (not yet saved or pushed).
  Future<DoctorProfile> writeSignatureLocal(
    DoctorProfile profile,
    Uint8List png,
  ) async {
    try {
      final f = File(p.join(_dir, DoctorProfile.defaultSignatureFileName));
      await f.writeAsBytes(png, flush: true);
    } on FileSystemException catch (e) {
      throw StorageFailure(
        'Could not save signature on this device.',
        cause: e,
      );
    }
    final now = DateTime.now();
    return profile.copyWith(
      signatureFileName: DoctorProfile.defaultSignatureFileName,
      signatureUpdatedAt: now,
      updatedAt: now,
    );
  }
}

/// Result of a profile save: the profile is always stored on the device;
/// [synced] tells whether the server copy was updated too.
class ProfileSaveResult {
  const ProfileSaveResult({required this.profile, required this.synced});
  final DoctorProfile profile;
  final bool synced;
}

/// The signed-in doctor's profile. Rebuilds when the user changes. Emits
/// [DoctorProfile.empty] for a signed-out app so widgets never see a fake
/// identity. `AsyncLoading` while the first local/remote read is in flight —
/// the router waits for it before deciding between onboarding and home.
class DoctorProfileController extends AsyncNotifier<DoctorProfile> {
  static const _remoteTimeout = Duration(seconds: 8);

  DoctorProfileRepository? _repo;

  @override
  Future<DoctorProfile> build() async {
    final uid = ref.watch(currentUserIdProvider);
    if (uid == null) {
      _repo = null;
      return DoctorProfile.empty;
    }
    final repo = DoctorProfileRepository(uid: uid);
    _repo = repo;
    await repo.migrateLegacy();
    final local = await repo.loadLocal();

    if (local == null) {
      // Fresh install / new device: wait (briefly) for the server copy so a
      // doctor with an existing account is not sent through onboarding
      // again. If the network is down we start blank and refresh later.
      try {
        final remote = await repo.fetchRemote().timeout(_remoteTimeout);
        if (remote != null) {
          await repo.saveLocal(remote, dirty: false);
          return remote;
        }
      } catch (e) {
        debugPrint('[profile] initial remote fetch failed: $e');
      }
      return DoctorProfile.empty;
    }

    // Cached copy available: return it immediately, reconcile in background.
    unawaited(_reconcile(repo, local.profile, local.dirty));
    return local.profile;
  }

  Future<void> _reconcile(
    DoctorProfileRepository repo,
    DoctorProfile local,
    bool dirty,
  ) async {
    try {
      if (dirty) {
        await repo.pushRemote(local);
        final sig = await repo.signatureBytes(local);
        if (sig != null) await repo.uploadSignature(sig);
        await repo.saveLocal(local, dirty: false);
        return;
      }
      final remote = await repo.fetchRemote(local: local);
      if (remote == null) {
        if (!local.isBlank) {
          await repo.pushRemote(local);
          final sig = await repo.signatureBytes(local);
          if (sig != null) await repo.uploadSignature(sig);
        }
        return;
      }
      final localAt = local.updatedAt;
      final remoteAt = remote.updatedAt;
      if (localAt == null || (remoteAt != null && remoteAt.isAfter(localAt))) {
        await repo.saveLocal(remote, dirty: false);
        if (_repo == repo && remote != local) state = AsyncData(remote);
      } else if (remoteAt == null || localAt.isAfter(remoteAt)) {
        await repo.pushRemote(local);
      } else if (remote.signatureFileName != local.signatureFileName) {
        // Same timestamps but the signature was fetched: reflect it.
        await repo.saveLocal(remote, dirty: false);
        if (_repo == repo) state = AsyncData(remote);
      }
    } catch (e) {
      debugPrint('[profile] background reconcile failed: $e');
    }
  }

  DoctorProfileRepository _requireRepo() {
    final repo = _repo;
    if (repo == null) throw const AuthFailure('Not signed in.');
    return repo;
  }

  /// Saves text fields. Always persists locally; tries to push. Marks
  /// onboarding complete the first time the profile becomes complete.
  Future<ProfileSaveResult> save(DoctorProfile draft) async {
    final repo = _requireRepo();
    final current = state.value ?? DoctorProfile.empty;
    final now = DateTime.now();
    var next = draft.copyWith(
      signatureFileName: current.signatureFileName,
      signatureUpdatedAt: current.signatureUpdatedAt,
      updatedAt: now,
      onboardingCompletedAt: current.onboardingCompletedAt,
    );
    if (next.isComplete && next.onboardingCompletedAt == null) {
      next = next.copyWith(onboardingCompletedAt: now);
    }
    await repo.saveLocal(next, dirty: true);
    state = AsyncData(next);
    return _push(repo, next);
  }

  /// Stores a new signature PNG (drawn or uploaded) locally and remotely.
  Future<ProfileSaveResult> saveSignature(Uint8List png) async {
    final repo = _requireRepo();
    final current = state.value ?? DoctorProfile.empty;
    var next = await repo.writeSignatureLocal(current, png);
    if (next.isComplete && next.onboardingCompletedAt == null) {
      next = next.copyWith(onboardingCompletedAt: DateTime.now());
    }
    await repo.saveLocal(next, dirty: true);
    state = AsyncData(next);
    try {
      await repo.uploadSignature(png);
    } catch (e) {
      debugPrint('[profile] signature upload deferred: $e');
      return ProfileSaveResult(profile: next, synced: false);
    }
    return _push(repo, next);
  }

  Future<ProfileSaveResult> _push(
    DoctorProfileRepository repo,
    DoctorProfile profile,
  ) async {
    try {
      await repo.pushRemote(profile);
      await repo.saveLocal(profile, dirty: false);
      return ProfileSaveResult(profile: profile, synced: true);
    } catch (e) {
      debugPrint('[profile] push deferred: $e');
      return ProfileSaveResult(profile: profile, synced: false);
    }
  }

  Future<Uint8List?> signatureBytes() async {
    final repo = _repo;
    final profile = state.value;
    if (repo == null || profile == null) return null;
    return repo.signatureBytes(profile);
  }

  /// Removes the cached profile + signature from this device (Privacy >
  /// Delete local data). The account copy is untouched.
  Future<void> clearLocal() async {
    final repo = _repo;
    if (repo == null) return;
    await repo.clearLocal();
    state = const AsyncData(DoctorProfile.empty);
  }
}

final doctorProfileProvider =
    AsyncNotifierProvider<DoctorProfileController, DoctorProfile>(
      DoctorProfileController.new,
    );

/// Convenience: the profile or [DoctorProfile.empty] while loading / signed
/// out. Use [doctorProfileProvider] directly when the loading state matters
/// (router redirect, sign gate).
final doctorProfileValueProvider = Provider<DoctorProfile>(
  (ref) => ref.watch(doctorProfileProvider).value ?? DoctorProfile.empty,
);
