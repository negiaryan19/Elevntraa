import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Resolves on-device file locations. The documents directory is cached once
/// at startup so the rest of the app can build absolute paths synchronously
/// (image widgets and the PDF builder need a path immediately).
///
/// Attachments are stored as *relative* file names (e.g. `<uuid>.jpg`) so a
/// reinstall or OS container-path change can't orphan them — we always resolve
/// against the current documents directory. Legacy absolute paths still work
/// (see [resolveAttachment]).
class AppPaths {
  AppPaths._();

  static String? _documentsDir;

  /// Must be called once during app startup, before any attachment is read.
  static Future<void> init() async {
    _documentsDir = (await getApplicationDocumentsDirectory()).path;
  }

  static String get documentsDir {
    final dir = _documentsDir;
    if (dir == null) {
      throw StateError('AppPaths.init() must be called before use.');
    }
    return dir;
  }

  /// Directory where scanned report images live.
  static String get attachmentsDir => p.join(documentsDir, 'attachments');

  /// Turns a stored attachment reference into an absolute path. Accepts both
  /// new relative file names and any legacy absolute paths unchanged.
  static String resolveAttachment(String stored) {
    if (p.isAbsolute(stored)) return stored;
    return p.join(attachmentsDir, stored);
  }
}
