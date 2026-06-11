import 'package:permission_handler/permission_handler.dart';

/// Single source of truth for mic permission. Wraps permission_handler with
/// a tri-state result so the recording screen can react cleanly.
enum MicPermissionResult { granted, denied, permanentlyDenied }

class MicPermission {
  MicPermission._();

  static Future<MicPermissionResult> request() async {
    final status = await Permission.microphone.request();
    if (status.isGranted || status.isLimited) return MicPermissionResult.granted;
    if (status.isPermanentlyDenied) return MicPermissionResult.permanentlyDenied;
    return MicPermissionResult.denied;
  }

  static Future<bool> isGranted() async {
    final status = await Permission.microphone.status;
    return status.isGranted || status.isLimited;
  }

  /// Open the system settings so the user can grant a permanently-denied
  /// permission. Returns true if the settings page was opened.
  static Future<bool> openSettings() => openAppSettings();
}
