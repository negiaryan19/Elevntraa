import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum StatusTone { neutral, success, warning, error, info, primary }

/// Pill-shaped tag used for [needs review] flags, language tags, signed/
/// unsigned status, etc. Tone drives both color and meaning.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = StatusTone.neutral,
    this.icon,
    this.dense = false,
  });

  final String label;
  final StatusTone tone;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final palette = _palette(tone);
    final padV = dense ? 4.0 : 6.0;
    final padH = dense ? AppSpacing.s : AppSpacing.m;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: AppSpacing.radiusPill,
        border: Border.all(color: palette.border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 12 : 14, color: palette.foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: palette.foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _ChipPalette _palette(StatusTone t) {
    switch (t) {
      case StatusTone.success:
        return const _ChipPalette(
          background: AppColors.successSoft,
          foreground: AppColors.success,
          border: AppColors.success,
        );
      case StatusTone.warning:
        return const _ChipPalette(
          background: AppColors.warningSoft,
          foreground: AppColors.warning,
          border: AppColors.warning,
        );
      case StatusTone.error:
        return const _ChipPalette(
          background: AppColors.errorSoft,
          foreground: AppColors.error,
          border: AppColors.error,
        );
      case StatusTone.info:
        return const _ChipPalette(
          background: AppColors.infoSoft,
          foreground: AppColors.info,
          border: AppColors.info,
        );
      case StatusTone.primary:
        return const _ChipPalette(
          background: Color(0xFFD7EAE5),
          foreground: AppColors.primaryDark,
          border: AppColors.primary,
        );
      case StatusTone.neutral:
        return const _ChipPalette(
          background: AppColors.surfaceAlt,
          foreground: AppColors.textSecondary,
          border: AppColors.outlineStrong,
        );
    }
  }
}

class _ChipPalette {
  const _ChipPalette({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}
