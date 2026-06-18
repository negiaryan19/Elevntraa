import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../settings/data/doctor_profile_repository.dart';

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
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),
                      const _HeroIcon(),
                      SizedBox(height: AppSpacing.adaptive(context, AppSpacing.lg)),
                      Text(
                        'Welcome Back, Doctor',
                        style: AppTypography.displayMedium,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppSpacing.adaptive(context, AppSpacing.s)),
                      Text(
                        'Transform patient conversations into perfect prescriptions with AI-powered transcription',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppSpacing.adaptive(context, AppSpacing.xl)),
                      const _StatsRow(),
                      SizedBox(height: AppSpacing.adaptive(context, AppSpacing.xl)),
                      _CtaButton(
                        onTap: () => context.push(AppRoute.intake.path),
                      ),
                      SizedBox(height: AppSpacing.adaptive(context, AppSpacing.m)),
                      Text(
                        'Click to begin recording a patient consultation',
                        style: AppTypography.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(flex: 1),
                    ],
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

class _AppHeader extends ConsumerWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctor = ref.watch(doctorProfileControllerProvider);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.adaptive(context, AppSpacing.lg),
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
          // Expanded: left block takes all remaining space so the right
          // side (name + icon) is never pushed off screen.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Rxvarta',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Smart Medical Documentation',
                  style: AppTypography.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          // Flexible: right block yields space to the left side on narrow
          // screens; the name ellipsizes before pushing off the edge.
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.monitor_heart_rounded,
                  color: _kTeal600,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    'Dr. ${_firstName(doctor.name)}',
                    style: AppTypography.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroIcon extends StatelessWidget {
  const _HeroIcon();

  @override
  Widget build(BuildContext context) {
    final size = AppSpacing.adaptiveSize(context, 96, min: 52);
    final iconSize = size * 0.5;
    final radius = size * 0.25;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kBlue600, _kTeal500],
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(color: _kBlueShadow, blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: Icon(
        Icons.medical_services_rounded,
        color: Colors.white,
        size: iconSize,
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
    final pad = AppSpacing.adaptive(context, AppSpacing.md);
    return Container(
      padding: EdgeInsets.all(pad),
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
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.adaptive(context, 20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: AppSpacing.m),
                  Flexible(
                    child: Text(
                      'Start New Consultation',
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
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
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.xs + MediaQuery.of(context).padding.bottom,
      ),
      child: Text(
        'Secure • HIPAA Compliant • End-to-End Encrypted',
        style: AppTypography.bodySmall,
        textAlign: TextAlign.center,
      ),
    );
  }
}

String _firstName(String fullName) {
  final parts = fullName.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '';

  final ignoredPrefixes = {
    'dr', 'dr.',
    'prof', 'prof.',
    'mr', 'mr.',
    'mrs', 'mrs.',
    'ms', 'ms.',
    'doctor', 'doc',
  };

  for (final part in parts) {
    final cleanPart = part.toLowerCase();
    if (!ignoredPrefixes.contains(cleanPart)) {
      return part;
    }
  }

  return parts.first;
}
