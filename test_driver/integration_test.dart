import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Driver for `flutter drive --driver=test_driver/integration_test.dart`
/// with `--target=integration_test/[file].dart`. Saves every
/// `binding.takeScreenshot(name)` call as `build/e2e/[name].png`.
Future<void> main() async {
  await integrationDriver(
    onScreenshot:
        (String name, List<int> bytes, [Map<String, Object?>? args]) async {
          final dir = Directory('build/e2e');
          if (!dir.existsSync()) dir.createSync(recursive: true);
          File('${dir.path}/$name.png').writeAsBytesSync(bytes);
          return true;
        },
  );
}
