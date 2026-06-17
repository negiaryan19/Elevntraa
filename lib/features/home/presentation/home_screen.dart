import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

// Figma palette: blue-600 → teal-500 gradient system
const _kBlue600 = Color(0xFF2563EB);
const _kTeal500 = Color(0xFF14B8A6);
const _kTeal600 = Color(0xFF0D9488);
const _kPurple600 = Color(0xFF9333EA);
const _kBlueShadow = Color(0x4D2563EB); // blue-500/30

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEFF6FF), Colors.white, Color(0xFFF0FDFA)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const _AppHeader(),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        // On iOS the screen (e.g. iPhone 17 Pro) is much taller
                        // than the Android test device, so centering left large
                        // empty gaps above/below and pushed the CTA into dead
                        // space. Top-align on iOS so content flows naturally;
                        // Android keeps its original centered layout untouched.
                        mainAxisAlignment: Platform.isIOS
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: AppSpacing.xl),
                          const _HeroIcon(),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'Welcome Back, Doctor',
                            style: AppTypography.displayMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.m),
                          Text(
                            'Transform patient conversations into perfect prescriptions with AI-powered transcription',
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          const _StatsRow(),
                          const SizedBox(height: AppSpacing.xxl),
                          _CtaButton(
                            onTap: () => context.push(AppRoute.intake.path),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'Click to begin recording a patient consultation',
                            style: AppTypography.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const _HomeFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.s,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_kBlue600, _kTeal500],
              ),
              borderRadius: AppSpacing.radiusMd,
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          // Flexible so a narrow device (≈320dp) doesn't overflow this row:
          // the title block yields width to the trailing icon + name instead
          // of pushing past the screen edge.
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Rxvarta',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Smart Medical Documentation',
                  style: AppTypography.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          const Icon(Icons.monitor_heart_rounded, color: _kTeal600, size: 20),
          const SizedBox(width: AppSpacing.xs),
          Text('Dr. Sharma', style: AppTypography.labelLarge),
        ],
      ),
    );
  }
}

class _HeroIcon extends StatelessWidget {
  const _HeroIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kBlue600, _kTeal500],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: _kBlueShadow, blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: const Icon(
        Icons.medical_services_rounded,
        color: Colors.white,
        size: 48,
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _StatCard(
            value: '247',
            label: 'Consultations',
            valueColor: _kBlue600,
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            value: '98%',
            label: 'Accuracy',
            valueColor: _kTeal600,
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            value: '2.5h',
            label: 'Saved Today',
            valueColor: _kPurple600,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTypography.headlineLarge.copyWith(color: valueColor),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTypography.bodySmall),
        ],
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  const _CtaButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppSpacing.radiusLg,
        boxShadow: const [
          BoxShadow(color: _kBlueShadow, blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppSpacing.radiusLg,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.radiusLg,
          splashColor: Colors.white24,
          highlightColor: Colors.white12,
          child: Ink(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [_kBlue600, _kTeal500],
              ),
              borderRadius: AppSpacing.radiusLg,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: 20,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: AppSpacing.m),
                  Text(
                    'Start New Consultation',
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeFooter extends StatelessWidget {
  const _HomeFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: Text(
        'Secure • HIPAA Compliant • End-to-End Encrypted',
        style: AppTypography.bodySmall,
        textAlign: TextAlign.center,
      ),
    );
  }
}
