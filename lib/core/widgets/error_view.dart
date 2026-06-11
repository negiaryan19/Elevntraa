import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_button.dart';

/// Designed error state — recoverable, with a retry action. Network calls
/// should surface failures through this, never through a raw exception
/// snackbar.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    this.title = 'Something went wrong',
    this.message,
    this.onRetry,
    this.retryLabel = 'Try again',
  });

  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 72,
              width: 72,
              decoration: const BoxDecoration(
                color: AppColors.errorSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: AppColors.error,
              ),
            ),
            AppSpacing.gapLg,
            Text(title, textAlign: TextAlign.center, style: textTheme.titleLarge),
            if (message != null) ...[
              AppSpacing.gapS,
              Text(
                message!,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (onRetry != null) ...[
              AppSpacing.gapLg,
              AppButton(
                label: retryLabel,
                onPressed: onRetry,
                icon: Icons.refresh_rounded,
                expand: false,
                variant: AppButtonVariant.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
