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
  static const double xxxl = 64;

  // Common gaps as ready-made widgets so layouts stay terse.
  static const SizedBox gapXs = SizedBox(height: xs, width: xs);
  static const SizedBox gapS = SizedBox(height: s, width: s);
  static const SizedBox gapM = SizedBox(height: m, width: m);
  static const SizedBox gapMd = SizedBox(height: md, width: md);
  static const SizedBox gapLg = SizedBox(height: lg, width: lg);
  static const SizedBox gapXl = SizedBox(height: xl, width: xl);

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets cardPaddingLg = EdgeInsets.all(lg);

  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(12));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(24));
  static const BorderRadius radiusPill = BorderRadius.all(Radius.circular(999));
}
