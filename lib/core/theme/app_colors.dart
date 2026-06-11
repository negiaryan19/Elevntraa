import 'package:flutter/material.dart';

/// Single source of truth for color. Widgets must consume these via
/// [Theme.of(context).colorScheme] or [AppColors] directly — never inline hex.
///
/// Palette intent: calm, clinical-but-warm. A deep teal anchors trust;
/// surfaces are a warm off-white (not pure #FFFFFF) so the prescription
/// feels like paper, not a screen.
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF0F6B5C); // deep teal
  static const Color primaryDark = Color(0xFF084C42);
  static const Color primaryLight = Color(0xFF3E9387);
  static const Color onPrimary = Color(0xFFF7F5EF);

  static const Color secondary = Color(0xFFB8845E); // warm clay accent
  static const Color onSecondary = Color(0xFFFFFFFF);

  // ── Surfaces (warm off-white system) ───────────────────────────────────
  static const Color background = Color(0xFFFAF7F1); // warm paper
  static const Color surface = Color(0xFFFFFCF6);
  static const Color surfaceAlt = Color(0xFFF1ECE2);
  static const Color outline = Color(0xFFE3DDD0);
  static const Color outlineStrong = Color(0xFFC9C2B2);

  // ── Text ───────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1B2421);
  static const Color textSecondary = Color(0xFF566661);
  static const Color textMuted = Color(0xFF8A958F);
  static const Color textInverse = Color(0xFFF7F5EF);

  // ── Semantic ───────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2F7D5B);
  static const Color successSoft = Color(0xFFE2F1E9);
  static const Color warning = Color(0xFFB8761F); // [needs review] amber
  static const Color warningSoft = Color(0xFFFBEDD2);
  static const Color error = Color(0xFFB3261E);
  static const Color errorSoft = Color(0xFFF7DCDA);
  static const Color info = Color(0xFF2C6E91);
  static const Color infoSoft = Color(0xFFDDEAF2);

  // ── Effects ────────────────────────────────────────────────────────────
  /// Soft, single-direction shadow used by cards. Real depth, not Material's
  /// blurry default.
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x14000000),
      offset: Offset(0, 2),
      blurRadius: 8,
    ),
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 8),
      blurRadius: 24,
    ),
  ];
}
