import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:permission_handler/permission_handler.dart';

/// Single source of truth for mic permission. Wraps permission_handler with
/// a tri-state result so the recording screen can react cleanly.
enum MicPermissionResult { granted, denied, permanentlyDenied }

class MicPermission {
  MicPermission._();

  /// permission_handler only ships implementations for Android, iOS, Windows
  /// and web (see its pubspec `plugin.platforms`). On macOS and Linux every
  /// call throws MissingPluginException, which used to escape
  /// `_onStartPressed` as an unhandled async error — the Start Consultation
  /// button silently did nothing.
  ///
  /// On those platforms the recorder's own permission check is the real gate:
  /// `RecordingService.start()` calls `AudioRecorder.hasPermission()` and
  /// throws [PermissionFailure] when capture is denied, and the OS shows its
  /// own microphone prompt on first use. So we report "granted" here and let
  /// the recorder decide, instead of blocking on a plugin that isn't there.
  static bool get _hasPlatformImplementation =>
      kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isWindows;

  static Future<MicPermissionResult> request() async {
    if (!_hasPlatformImplementation) return MicPermissionResult.granted;
    try {
      final status = await Permission.microphone.request();
      if (status.isGranted || status.isLimited) {
        return MicPermissionResult.granted;
      }
      if (status.isPermanentlyDenied) {
        return MicPermissionResult.permanentlyDenied;
      }
      return MicPermissionResult.denied;
    } on MissingPluginException {
      // Safety net: the plugin is absent on a platform we expected to support.
      // Defer to the recorder rather than dead-ending the doctor.
      return MicPermissionResult.granted;
    }
  }

  static Future<bool> isGranted() async {
    if (!_hasPlatformImplementation) return true;
    try {
      final status = await Permission.microphone.status;
      return status.isGranted || status.isLimited;
    } on MissingPluginException {
      return true;
    }
  }

  /// Open the system settings so the user can grant a permanently-denied
  /// permission. Returns true if the settings page was opened.
  static Future<bool> openSettings() async {
    if (!_hasPlatformImplementation) return false;
    try {
      return await openAppSettings();
    } on MissingPluginException {
      return false;
    }
  }
}
