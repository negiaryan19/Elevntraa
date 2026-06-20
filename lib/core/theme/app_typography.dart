import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static const List<String> _indianScriptFallbacks = [
    'Noto Sans Devanagari',
    'Noto Sans Tamil',
    'Noto Sans Telugu',
    'Noto Sans Kannada',
    'Noto Sans Gujarati',
    'Noto Sans Oriya',
    'Noto Sans Bengali',
  ];

  static TextStyle _ui({
    required double size,
    FontWeight weight = FontWeight.w500,
    double? height,
    double? letterSpacing,
    Color? color,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color ?? AppColors.textPrimary,
    ).copyWith(fontFamilyFallback: _indianScriptFallbacks);
  }

  static TextStyle get displayLarge =>
      _ui(size: 36, weight: FontWeight.w700, height: 1.15, letterSpacing: -0.5);
  static TextStyle get displayMedium =>
      _ui(size: 30, weight: FontWeight.w700, height: 1.2, letterSpacing: -0.4);
  static TextStyle get headlineLarge =>
      _ui(size: 24, weight: FontWeight.w700, height: 1.25, letterSpacing: -0.2);
  static TextStyle get headlineMedium =>
      _ui(size: 20, weight: FontWeight.w600, height: 1.3);
  static TextStyle get titleLarge =>
      _ui(size: 18, weight: FontWeight.w600, height: 1.35);
  static TextStyle get titleMedium =>
      _ui(size: 16, weight: FontWeight.w600, height: 1.4);
  static TextStyle get titleSmall =>
      _ui(size: 14, weight: FontWeight.w600, height: 1.4);
  static TextStyle get bodyLarge => _ui(
    size: 16,
    weight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );
  static TextStyle get bodyMedium => _ui(
    size: 14,
    weight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );
  static TextStyle get bodySmall => _ui(
    size: 13,
    weight: FontWeight.w400,
    height: 1.45,
    color: AppColors.textSecondary,
  );
  static TextStyle get labelLarge =>
      _ui(size: 14, weight: FontWeight.w600, height: 1.2, letterSpacing: 0.2);
  static TextStyle get labelMedium =>
      _ui(size: 12, weight: FontWeight.w600, height: 1.2, letterSpacing: 0.3);
  static TextStyle get labelSmall =>
      _ui(size: 11, weight: FontWeight.w600, height: 1.2, letterSpacing: 0.4);
  static TextStyle get rxBody =>
      _ui(size: 14, weight: FontWeight.w500, height: 1.6);

  static TextThemeBuilder get textTheme => TextThemeBuilder();
}

class TextThemeBuilder {
  TextThemeBuilder();

  TextTheme build() => TextTheme(
    displayLarge: AppTypography.displayLarge,
    displayMedium: AppTypography.displayMedium,
    displaySmall: AppTypography.headlineLarge,
    headlineLarge: AppTypography.headlineLarge,
    headlineMedium: AppTypography.headlineMedium,
    headlineSmall: AppTypography.titleLarge,
    titleLarge: AppTypography.titleLarge,
    titleMedium: AppTypography.titleMedium,
    titleSmall: AppTypography.titleSmall,
    bodyLarge: AppTypography.bodyLarge,
    bodyMedium: AppTypography.bodyMedium,
    bodySmall: AppTypography.bodySmall,
    labelLarge: AppTypography.labelLarge,
    labelMedium: AppTypography.labelMedium,
    labelSmall: AppTypography.labelSmall,
  );

  TextTheme buildDark() => build().copyWith(
    displayLarge: AppTypography.displayLarge.copyWith(
      color: AppColors.darkTextPrimary,
    ),
    displayMedium: AppTypography.displayMedium.copyWith(
      color: AppColors.darkTextPrimary,
    ),
    displaySmall: AppTypography.headlineLarge.copyWith(
      color: AppColors.darkTextPrimary,
    ),
    headlineLarge: AppTypography.headlineLarge.copyWith(
      color: AppColors.darkTextPrimary,
    ),
    headlineMedium: AppTypography.headlineMedium.copyWith(
      color: AppColors.darkTextPrimary,
    ),
    headlineSmall: AppTypography.titleLarge.copyWith(
      color: AppColors.darkTextPrimary,
    ),
    titleLarge: AppTypography.titleLarge.copyWith(
      color: AppColors.darkTextPrimary,
    ),
    titleMedium: AppTypography.titleMedium.copyWith(
      color: AppColors.darkTextPrimary,
    ),
    titleSmall: AppTypography.titleSmall.copyWith(
      color: AppColors.darkTextPrimary,
    ),
    bodyLarge: AppTypography.bodyLarge.copyWith(
      color: AppColors.darkTextPrimary,
    ),
    bodyMedium: AppTypography.bodyMedium.copyWith(
      color: AppColors.darkTextPrimary,
    ),
    bodySmall: AppTypography.bodySmall.copyWith(
      color: AppColors.darkTextSecondary,
    ),
    labelLarge: AppTypography.labelLarge.copyWith(
      color: AppColors.darkTextPrimary,
    ),
    labelMedium: AppTypography.labelMedium.copyWith(
      color: AppColors.darkTextSecondary,
    ),
    labelSmall: AppTypography.labelSmall.copyWith(
      color: AppColors.darkTextSecondary,
    ),
  );
}
