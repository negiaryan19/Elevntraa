import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_provider.dart';
import 'router.dart';

class RxvartaApp extends ConsumerWidget {
  const RxvartaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeAsync = ref.watch(themeModeProvider);

    // While prefs load, show a blank screen in system theme — no flash
    final themeMode = themeAsync.value ?? ThemeMode.system;

    return MaterialApp.router(
      title: 'Rxvarta',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      scrollBehavior: const _NoBounceScrollBehavior(),
      // Screens are laid out for the default text scale. A larger system
      // text size (common on iOS via Dynamic Type) inflates text until
      // labels wrap and fixed-height screens overflow into scrolling.
      // Clamp the scale so layouts stay intact; honors up to 110%.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(
              minScaleFactor: 1.0,
              maxScaleFactor: 1.3,
            ),
          ),
          child: child!,
        );
      },
      routerConfig: router,
    );
  }
}

/// Forces Android-style clamping physics on every scroll view, including iOS.
/// Without this iOS applies its default rubber-band bounce, so screens whose
/// content fits still wobble when dragged. Clamping means a view only scrolls
/// when its content genuinely overflows.
class _NoBounceScrollBehavior extends MaterialScrollBehavior {
  const _NoBounceScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();
}
