import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Wraps any widget in a calibrated shimmer using the warm-paper palette.
/// Use shimmers for content placeholders — never spinners — so the user
/// sees the shape of what's loading.
class LoadingShimmer extends StatelessWidget {
  const LoadingShimmer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceAlt,
      highlightColor: AppColors.surface,
      period: const Duration(milliseconds: 1400),
      child: child,
    );
  }
}

/// Common skeleton primitive — a single rounded bar.
class ShimmerBar extends StatelessWidget {
  const ShimmerBar({
    super.key,
    this.width = double.infinity,
    this.height = 12,
    this.radius = 6,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Pre-shaped skeleton for a "list of recent visits" card.
class VisitCardSkeleton extends StatelessWidget {
  const VisitCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return LoadingShimmer(
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.radiusLg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                ShimmerBar(width: 44, height: 44, radius: 22),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBar(width: 160, height: 14),
                      SizedBox(height: AppSpacing.s),
                      ShimmerBar(width: 100, height: 10),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const ShimmerBar(height: 10),
            const SizedBox(height: AppSpacing.s),
            const ShimmerBar(width: 220, height: 10),
          ],
        ),
      ),
    );
  }
}
