import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';

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
