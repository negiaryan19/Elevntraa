import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Rounded, softly-shadowed surface used as the building block for screens.
/// Has a real shadow (not Material's blurry default).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.onTap,
    this.color,
    this.outlined = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppColors.surface;
    final decoration = BoxDecoration(
      color: bg,
      borderRadius: AppSpacing.radiusLg,
      border: outlined ? Border.all(color: AppColors.outline) : null,
      boxShadow: outlined ? null : AppColors.cardShadow,
    );

    final content = Padding(padding: padding, child: child);

    if (onTap == null) {
      return DecoratedBox(decoration: decoration, child: content);
    }

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: decoration,
        child: InkWell(
          borderRadius: AppSpacing.radiusLg,
          onTap: onTap,
          splashColor: AppColors.primary.withValues(alpha: 0.06),
          highlightColor: AppColors.primary.withValues(alpha: 0.03),
          child: content,
        ),
      ),
    );
  }
}
