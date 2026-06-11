import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }
enum AppButtonSize { regular, large }

/// Single button widget the whole app uses. Variants are purely cosmetic;
/// size affects vertical rhythm only.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.regular,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    final height = size == AppButtonSize.large ? 56.0 : 48.0;

    final colors = _colorsFor(variant, disabled);

    final child = loading
        ? SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(colors.foreground),
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: colors.foreground),
                AppSpacing.gapS,
              ],
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.foreground,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

    final button = Material(
      color: colors.background,
      borderRadius: AppSpacing.radiusMd,
      child: InkWell(
        borderRadius: AppSpacing.radiusMd,
        onTap: disabled ? null : onPressed,
        splashColor: colors.foreground.withValues(alpha: 0.08),
        highlightColor: colors.foreground.withValues(alpha: 0.04),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppSpacing.radiusMd,
            border: colors.border == null
                ? null
                : Border.all(color: colors.border!, width: 1.2),
          ),
          child: Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }

  _ButtonColors _colorsFor(AppButtonVariant v, bool disabled) {
    if (disabled) {
      return const _ButtonColors(
        background: AppColors.surfaceAlt,
        foreground: AppColors.textMuted,
      );
    }
    switch (v) {
      case AppButtonVariant.primary:
        return const _ButtonColors(
          background: AppColors.primary,
          foreground: AppColors.onPrimary,
        );
      case AppButtonVariant.secondary:
        return const _ButtonColors(
          background: AppColors.surface,
          foreground: AppColors.primary,
          border: AppColors.outlineStrong,
        );
      case AppButtonVariant.ghost:
        return const _ButtonColors(
          background: Colors.transparent,
          foreground: AppColors.primary,
        );
      case AppButtonVariant.danger:
        return const _ButtonColors(
          background: AppColors.error,
          foreground: Colors.white,
        );
    }
  }
}

class _ButtonColors {
  const _ButtonColors({
    required this.background,
    required this.foreground,
    this.border,
  });

  final Color background;
  final Color foreground;
  final Color? border;
}
