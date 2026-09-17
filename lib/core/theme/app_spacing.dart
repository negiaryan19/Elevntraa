import 'package:flutter/widgets.dart';

/// Strict 8pt grid. Use these tokens instead of raw doubles in widgets.
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // Common gaps as ready-made widgets so layouts stay terse.
  static const SizedBox gapS = SizedBox(height: s, width: s);
  static const SizedBox gapMd = SizedBox(height: md, width: md);
  static const SizedBox gapLg = SizedBox(height: lg, width: lg);

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(12));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(24));
  static const BorderRadius radiusPill = BorderRadius.all(Radius.circular(999));

  /// Returns a scaled value based on screen height so fixed spacings shrink
  /// on very small phones (<600dp), small phones (<680dp) and medium phones
  /// (<780dp) while staying full-size on the Pixel 6a baseline and above.
  static double adaptive(BuildContext context, double baseValue) {
    final height = MediaQuery.of(context).size.longestSide;
    if (height < 600) return baseValue * 0.45;
    if (height < 680) return baseValue * 0.6;
    if (height < 780) return baseValue * 0.78;
    return baseValue;
  }
}
