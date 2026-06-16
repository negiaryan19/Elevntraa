import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/utils/app_paths.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cache the documents directory so attachment paths resolve synchronously.
  await AppPaths.init();

  // Load .env. A missing file is non-fatal — onboarding can also write
  // keys to secure storage, so first launch without a bundled .env is OK.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Intentional: missing .env on first run is expected.
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: RxvartaApp()));
}
