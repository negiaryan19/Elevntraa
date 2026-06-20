import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand gradient ─────────────────────────────────────────────────────
  static const Color gradientStart = Color(0xFF2563EB);
  static const Color gradientEnd = Color(0xFF14B8A6);

  // ── Light brand ────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFF14B8A6);
  static const Color onSecondary = Color(0xFFFFFFFF);

  // ── Light surfaces ─────────────────────────────────────────────────────
  static const Color background = Color(0xFFF8FAFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF1F5FF);
  static const Color outline = Color(0xFFE5E7EB);
  static const Color outlineStrong = Color(0xFFD1D5DB);

  // ── Light text ─────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textInverse = Color(0xFFFFFFFF);

  // ── Dark surfaces (deep navy palette) ─────────────────────────────────
  static const Color darkBackground = Color(0xFF0D0F1A); // deepest navy
  static const Color darkSurface = Color(0xFF13162A); // card bg
  static const Color darkSurfaceAlt = Color(0xFF1C2040); // elevated surface
  static const Color darkSurfaceHigh = Color(0xFF242849); // hover/active
  static const Color darkOutline = Color(0xFF2A2F52); // subtle border
  static const Color darkOutlineStrong = Color(0xFF3D4470); // visible border

  // ── Dark text ──────────────────────────────────────────────────────────
  static const Color darkTextPrimary = Color(
    0xFFEEF0FF,
  ); // near-white with blue tint
  static const Color darkTextSecondary = Color(0xFF8B93C8); // muted blue-grey
  static const Color darkTextMuted = Color(0xFF4F568A); // very muted

  // ── Dark accent (brighter versions for dark bg) ────────────────────────
  static const Color darkPrimary = Color(0xFF6B8FFF); // blue on dark
  static const Color darkSecondary = Color(0xFF2DD4BF); // teal on dark

  // ── Semantic ───────────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color successSoft = Color(0xFFD1FAE5);
  static const Color successDark = Color(0xFF059669);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorSoft = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFFF87171);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoSoft = Color(0xFFEFF6FF);

  // ── Shadows ────────────────────────────────────────────────────────────
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x08000000), offset: Offset(0, 1), blurRadius: 3),
    BoxShadow(color: Color(0x12000000), offset: Offset(0, 4), blurRadius: 16),
  ];

  static const List<BoxShadow> cardShadowDark = [
    BoxShadow(color: Color(0x50000000), offset: Offset(0, 2), blurRadius: 8),
    BoxShadow(color: Color(0x30000000), offset: Offset(0, 8), blurRadius: 24),
  ];

  static const List<BoxShadow> glowBlue = [
    BoxShadow(color: Color(0x502563EB), blurRadius: 24, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> glowBlueDark = [
    BoxShadow(color: Color(0x606B8FFF), blurRadius: 28, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> glowTeal = [
    BoxShadow(color: Color(0x4014B8A6), blurRadius: 20, offset: Offset(0, 8)),
  ];
}
