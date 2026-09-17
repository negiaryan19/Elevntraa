import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/reveal.dart';
import '../../../l10n/app_localizations.dart';
import '../auth_redirect.dart';

/// Shared layout for every authentication screen: the brand gradient header
/// (same gradient and translucent chips as Home / Settings), a headline and
/// subtitle on it, and a raised card holding the form. Scrolls as one piece
/// so the keyboard never overflows on small phones.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.icon = Icons.lock_outline_rounded,
    this.showBack = false,
    this.footer,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final IconData icon;

  /// Shows a back chip on the header. Pops when possible, otherwise returns
  /// to Login (auth pages can be reached directly by a redirect).
  final bool showBack;

  /// Optional content under the card (e.g. "New here? Create account").
  final Widget? footer;

  static const double _cardOverlap = 28;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              title: title,
              subtitle: subtitle,
              icon: icon,
              showBack: showBack,
              bottomPadding: AppSpacing.xl + _cardOverlap,
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(kLoginPath);
                }
              },
            ),
            Transform.translate(
              offset: const Offset(0, -_cardOverlap),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Reveal(
                      delayMs: 90,
                      child: Container(
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: AppSpacing.radiusXl,
                          border: Border.all(color: scheme.outline),
                          boxShadow: isDark
                              ? AppColors.cardShadowDark
                              : AppColors.cardShadow,
                        ),
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: child,
                      ),
                    ),
                    if (footer != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Reveal(delayMs: 180, child: footer!),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Reveal(
                      delayMs: 240,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: Text(
                              t.authSecureNote,
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmall.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.showBack,
    required this.bottomPadding,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool showBack;
  final double bottomPadding;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Soft decorative glow, like the Home backdrop.
          Positioned(
            top: -90,
            right: -70,
            child: IgnorePointer(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.22),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                bottomPadding,
              ),
              child: Reveal(
                delayMs: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (showBack) ...[
                          _HeaderChip(
                            onTap: onBack,
                            tooltip: t.authBack,
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.m),
                        ],
                        _HeaderChip(
                          child: Icon(icon, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                t.appName,
                                style: AppTypography.titleMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                t.appTagline,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: AppSpacing.adaptive(context, AppSpacing.xl),
                    ),
                    Text(
                      title,
                      style: AppTypography.headlineLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.child, this.onTap, this.tooltip});

  final Widget child;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: AppSpacing.radiusMd,
      ),
      child: child,
    );
    if (onTap == null) return chip;
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppSpacing.radiusMd,
        onTap: onTap,
        child: chip,
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}
