import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Keeps a consultation recording going while the screen is locked or the
/// doctor switches apps (roadmap item 9).
///
/// Without it Android treats the app as backgrounded the moment the screen
/// locks: the microphone delivers silence and the app's network connections
/// are closed. A foreground service of type `microphone` keeps the app in
/// use for the length of the recording and shows an ongoing notification
/// saying so. iOS keeps recording through `UIBackgroundModes: audio` in
/// Info.plist, so nothing is started there.
class RecordingKeepAlive {
  const RecordingKeepAlive();

  static const _serviceId = 4101;

  Future<void> start({required String title, required String text}) async {
    if (!Platform.isAndroid) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'consultation_recording',
        channelName: title,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        // The recorder lives in the app process: a service restarted on its
        // own would record nothing. (Closing the app ends the service through
        // `android:stopWithTask` in the manifest. The plugin's own
        // `stopWithTask` option must stay off: it stops the service as soon as
        // no screen is visible, which is exactly when the screen locks.)
        allowAutoRestart: false,
      ),
    );
    try {
      // Android 13+ hides the notification without this; the service still
      // runs if the doctor declines.
      if (await FlutterForegroundTask.checkNotificationPermission() !=
          NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }
      if (await FlutterForegroundTask.isRunningService) return;
      final result = await FlutterForegroundTask.startService(
        serviceId: _serviceId,
        serviceTypes: [ForegroundServiceTypes.microphone],
        notificationTitle: title,
        notificationText: text,
      );
      if (result is ServiceRequestFailure) throw result.error;
    } catch (e) {
      // Recording with the screen on still works; say why it may not with
      // the screen off.
      debugPrint('[recording] keep-alive service did not start: $e');
    }
  }

  Future<void> stop() async {
    if (!Platform.isAndroid) return;
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
    } catch (e) {
      debugPrint('[recording] keep-alive service did not stop: $e');
    }
  }
}
