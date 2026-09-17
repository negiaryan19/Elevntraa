import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/network/connectivity_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../data/repositories/patient_repository.dart';
import '../../../domain/models/patient.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/data/doctor_profile_repository.dart';
import '../../settings/presentation/doctor_profile_form.dart';

/// The five most recent patients, straight from the database: finishing a
/// consultation updates this list without a pull-to-refresh (roadmap item
/// 32), and it follows the signed-in doctor's own database.
final _recentPatientsProvider =
    StreamProvider.autoDispose<List<PatientProfile>>((ref) {
      return ref.watch(patientRepositoryProvider).watchRecent(limit: 5);
    });

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final doctor = ref.watch(doctorProfileValueProvider);
    final profileAsync = ref.watch(doctorProfileProvider);
    // Nudge only once the profile has actually loaded (never on the loading
    // placeholder) and only for a signed-in doctor.
    final showProfileNudge =
        ref.watch(isSignedInProvider) &&
        profileAsync.hasValue &&
        !profileAsync.requireValue.isComplete;
    final recent = ref.watch(_recentPatientsProvider);

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -140,
            right: -110,
            child: _GlowCircle(
              color: isDark ? AppColors.darkPrimary : AppColors.primary,
              alpha: isDark ? 0.20 : 0.13,
              size: 320,
            ),
          ),
          Positioned(
            bottom: -70,
            left: -120,
            child: _GlowCircle(
              color: isDark ? AppColors.darkSecondary : AppColors.secondary,
              alpha: isDark ? 0.16 : 0.10,
              size: 260,
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: RefreshIndicator(
                color: scheme.primary,
                onRefresh: () async {
                  ref.invalidate(_recentPatientsProvider);
                  await ref.read(_recentPatientsProvider.future);
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  children: [
                    _Reveal(
                      delayMs: 0,
                      child: _Header(scheme: scheme, isDark: isDark),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _Reveal(
                      delayMs: 90,
                      child: _Greeting(name: doctor.name, scheme: scheme),
                    ),
                    if (showProfileNudge) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _Reveal(
                        delayMs: 135,
                        child: _Pressable(
                          onTap: () => DoctorProfileFormSheet.show(context),
                          child: _ProfileNudgeCard(
                            scheme: scheme,
                            isDark: isDark,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    _Reveal(
                      delayMs: 180,
                      child: _Pressable(
                        onTap: () => context.push(AppRoute.intake.path),
                        child: _ConsultationHero(isDark: isDark),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _Reveal(
                      delayMs: 270,
                      child: _QuickActions(scheme: scheme, isDark: isDark),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _Reveal(
                      delayMs: 360,
                      child: _SectionHeader(
                        title: AppLocalizations.of(context)!.recentPatients,
                        actionLabel: AppLocalizations.of(context)!.seeAll,
                        scheme: scheme,
                        onAction: () => context.go(AppRoute.patients.path),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    recent.when(
                      data: (list) => list.isEmpty
                          ? _Reveal(
                              delayMs: 440,
                              child: _EmptyRecent(scheme: scheme),
                            )
                          : Column(
                              children: [
                                for (var i = 0; i < list.length; i++) ...[
                                  _Reveal(
                                    delayMs: 440 + i * 90,
                                    child: _Pressable(
                                      onTap: () => context.push(
                                        AppRoute.patient.build(
                                          params: {'patientId': list[i].id},
                                        ),
                                      ),
                                      child: _PatientRow(
                                        patient: list[i],
                                        isDark: isDark,
                                        scheme: scheme,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.m),
                                ],
                              ],
                            ),
                      loading: () => Column(
                        children: [
                          _RowSkeleton(),
                          const SizedBox(height: AppSpacing.m),
                          _RowSkeleton(),
                          const SizedBox(height: AppSpacing.m),
                          _RowSkeleton(),
                        ],
                      ),
                      error: (_, _) => _EmptyRecent(scheme: scheme),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _Reveal(
                      delayMs: 560,
                      child: _SecurityFooter(scheme: scheme),
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

// ── Motion primitives ─────────────────────────────────────────────────────

/// Rises from below AND sharpens from blurred to crisp — a "coming into
/// focus" entrance that suits a transcription product.
class _Reveal extends StatefulWidget {
  const _Reveal({required this.child, this.delayMs = 0});
  final Widget child;
  final int delayMs;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 312),
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: (widget.delayMs * 0.6).round()), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) {
        final v = _t.value;
        final dy = (1 - v) * 44;
        final blur = (1 - v) * 9;
        Widget result = child!;
        if (blur > 0.2) {
          result = ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: result,
          );
        }
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, dy), child: result),
        );
      },
    );
  }
}

class _Pressable extends StatefulWidget {
  const _Pressable({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  double _scale = 1;

  void _set(double s) {
    if (mounted) setState(() => _scale = s);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(0.97),
      onTapUp: (_) => _set(1),
      onTapCancel: () => _set(1),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// The hero "start consultation" visual: bars rising from a baseline with a
/// soft fill hugging their tops. Decorative only; loops forever so the card
/// always feels alive.
class _Waveform extends StatefulWidget {
  const _Waveform({this.bars = 30}) : assert(bars > 0, 'bars must be positive');
  final int bars;

  @override
  State<_Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<_Waveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return CustomPaint(
            size: Size.infinite,
            painter: _BaselineBarsPainter(
              tt: _c.value * 2 * math.pi,
              bars: widget.bars,
            ),
          );
        },
      ),
    );
  }
}

class _BaselineBarsPainter extends CustomPainter {
  _BaselineBarsPainter({required this.tt, required this.bars});
  final double tt;
  final int bars;

  double _a(double u) {
    final w =
        (0.5 + 0.5 * math.sin(u * 6.0 + tt * 1.7)) *
        (0.45 + 0.55 * (0.5 + 0.5 * math.sin(u * 11.0 - tt * 1.1)));
    return 0.14 + 0.86 * w;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final w = size.width;
    final usable = h - 4;

    // Soft fill hugging the bar tops.
    final fill = Path()..moveTo(0, h);
    for (var u = 0.0; u <= 1.0001; u += 0.02) {
      fill.lineTo(u * w, h - _a(u) * usable);
    }
    fill.lineTo(w, h);
    fill.close();
    canvas.drawPath(
      fill,
      Paint()..color = Colors.white.withValues(alpha: 0.16),
    );

    // Bars from the baseline.
    final n = bars;
    final slot = w / n;
    final bw = slot * 0.5;
    final radius = Radius.circular(bw / 2);
    for (var i = 0; i < n; i++) {
      final u = (i + 0.5) / n;
      final a = _a(u);
      final bh = a * usable;
      final x = slot * i + (slot - bw) / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, h - bh, bw, bh),
        radius,
      );
      canvas.drawRRect(
        rect,
        Paint()..color = Colors.white.withValues(alpha: 0.35 + 0.45 * a),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BaselineBarsPainter old) =>
      old.tt != tt || old.bars != bars;
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({
    required this.color,
    required this.alpha,
    required this.size,
  });
  final Color color;
  final double alpha;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: alpha),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sections ──────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.scheme, required this.isDark});
  final ColorScheme scheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.appName,
                style: AppTypography.titleMedium.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                AppLocalizations.of(context)!.appTagline,
                style: AppTypography.bodySmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const _ConnectivityChip(),
      ],
    );
  }
}

/// Live network indicator shown in the home header. Green dot + "Online" when
/// the internet is genuinely reachable, red dot + "Offline" otherwise — colours
/// come from [ColorScheme] tokens so both dark and light themes stay coherent.
class _ConnectivityChip extends ConsumerWidget {
  const _ConnectivityChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectivityStatusProvider);
    final scheme = Theme.of(context).colorScheme;

    // secondary (teal) reads as the positive "online" accent and adapts to the
    // active brightness; error is the theme's red; onSurfaceVariant is the
    // muted tone used while the first probe is still in flight.
    final t = AppLocalizations.of(context)!;
    final (Color color, String label) = switch (status) {
      ConnectivityStatus.online => (scheme.secondary, t.online),
      ConnectivityStatus.offline => (scheme.error, t.offline),
      ConnectivityStatus.checking => (scheme.onSurfaceVariant, t.checking),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppSpacing.radiusPill,
        border: Border.all(color: color.withValues(alpha: 0.55), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name, required this.scheme});
  final String name;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final hour = now.hour;
    final part = hour < 12
        ? t.goodMorning
        : hour < 17
        ? t.goodAfternoon
        : t.goodEvening;
    final display = name.trim().isEmpty ? t.doctorFallback : name.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: AppSpacing.radiusPill,
            border: Border.all(color: scheme.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 12,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                _prettyDate(now),
                style: AppTypography.labelSmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        Text(
          '$part,',
          style: AppTypography.titleMedium.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          display,
          style: AppTypography.displayLarge.copyWith(color: scheme.onSurface),
        ),
      ],
    );
  }

  static String _prettyDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
  }
}

class _ConsultationHero extends StatelessWidget {
  const _ConsultationHero({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppSpacing.radiusXl,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
        ),
        boxShadow: isDark ? AppColors.glowBlueDark : AppColors.glowBlue,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: AppSpacing.radiusLg,
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.startNewConsultation,
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.startNewConsultationSubtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const _Waveform(bars: 30),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.scheme, required this.isDark});
  final ColorScheme scheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Pressable(
            onTap: () => context.push(AppRoute.intakeForm.path),
            child: _ActionTile(
              icon: Icons.person_add_alt_1_rounded,
              label: AppLocalizations.of(context)!.newPatient,
              accent: AppColors.primary,
              isDark: isDark,
              scheme: scheme,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _Pressable(
            onTap: () => context.push(AppRoute.intakeExisting.path),
            child: _ActionTile(
              icon: Icons.search_rounded,
              label: AppLocalizations.of(context)!.findPatient,
              accent: AppColors.secondary,
              isDark: isDark,
              scheme: scheme,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _Pressable(
            onTap: () => context.go(AppRoute.patients.path),
            child: _ActionTile(
              icon: Icons.people_alt_rounded,
              label: AppLocalizations.of(context)!.allPatients,
              accent: const Color(0xFF8B5CF6),
              isDark: isDark,
              scheme: scheme,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.accent,
    required this.isDark,
    required this.scheme,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final bool isDark;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: scheme.outline),
        boxShadow: isDark ? AppColors.cardShadowDark : AppColors.cardShadow,
      ),
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.s,
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.22 : 0.12),
              borderRadius: AppSpacing.radiusMd,
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelMedium.copyWith(color: scheme.onSurface),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.scheme,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final ColorScheme scheme;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTypography.titleLarge.copyWith(color: scheme.onSurface),
        ),
        if (actionLabel != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            behavior: HitTestBehavior.opaque,
            child: Text(
              actionLabel!,
              style: AppTypography.labelLarge.copyWith(color: scheme.primary),
            ),
          ),
      ],
    );
  }
}

class _PatientRow extends StatelessWidget {
  const _PatientRow({
    required this.patient,
    required this.isDark,
    required this.scheme,
  });

  final PatientProfile patient;
  final bool isDark;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final meta = [
      if (patient.age != null) '${patient.age} ${t.years}',
      _sexLabel(t, patient.sex),
      if (patient.whatsappNumber != null) '+91 ${patient.whatsappNumber}',
    ].where((s) => s.isNotEmpty).join('  •  ');

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: scheme.outline),
        boxShadow: isDark ? AppColors.cardShadowDark : AppColors.cardShadow,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          _Avatar(name: patient.name),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSmall.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: scheme.onSurfaceVariant,
            size: 20,
          ),
        ],
      ),
    );
  }

  static String _sexLabel(AppLocalizations t, Sex? sex) {
    switch (sex) {
      case Sex.male:
        return t.male;
      case Sex.female:
        return t.female;
      case Sex.other:
        return t.other;
      case null:
        return '';
    }
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
        ),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(name),
        style: AppTypography.titleSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static String _initials(String n) {
    final parts = n
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    String f(String s) => s.substring(0, 1).toUpperCase();
    if (parts.length == 1) return f(parts.first);
    return f(parts.first) + f(parts.last);
  }
}

class _RowSkeleton extends StatelessWidget {
  const _RowSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LoadingShimmer(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: AppSpacing.radiusLg,
          border: Border.all(color: scheme.outline),
        ),
        child: Row(
          children: [
            const ShimmerBar(width: 46, height: 46, radius: 23),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBar(width: 140, height: 12),
                  SizedBox(height: AppSpacing.s),
                  ShimmerBar(width: 90, height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRecent extends StatelessWidget {
  const _EmptyRecent({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 36,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            AppLocalizations.of(context)!.noPatientsYet,
            style: AppTypography.titleSmall.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            AppLocalizations.of(context)!.noPatientsYetSubtitle,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact "finish your profile" card shown until the doctor's identity and
/// signature are complete — without them no prescription can be signed.
class _ProfileNudgeCard extends StatelessWidget {
  const _ProfileNudgeCard({required this.scheme, required this.isDark});
  final ColorScheme scheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    const accent = AppColors.warning;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: accent.withValues(alpha: isDark ? 0.5 : 0.4)),
        boxShadow: isDark ? AppColors.cardShadowDark : AppColors.cardShadow,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.22 : 0.14),
              borderRadius: AppSpacing.radiusMd,
            ),
            child: const Icon(Icons.badge_rounded, color: accent, size: 20),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.profileIncompleteNudgeTitle,
                  style: AppTypography.titleSmall.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  t.profileIncompleteNudgeBody,
                  style: AppTypography.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          Icon(
            Icons.chevron_right_rounded,
            color: scheme.onSurfaceVariant,
            size: 22,
          ),
        ],
      ),
    );
  }
}

class _SecurityFooter extends StatelessWidget {
  const _SecurityFooter({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Row(
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
            AppLocalizations.of(context)!.securityFooter,
            style: AppTypography.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
