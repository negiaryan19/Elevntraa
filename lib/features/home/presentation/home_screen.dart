import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/repositories/patient_repository.dart';
import '../../../domain/models/patient.dart';
import '../../settings/data/doctor_profile_repository.dart';

final _recentPatientsProvider =
    FutureProvider.autoDispose<List<PatientProfile>>((ref) async {
      final repo = ref.read(patientRepositoryProvider);
      final list = await repo.recent();
      return list.take(5).toList();
    });

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final doctor = ref.watch(doctorProfileControllerProvider);
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
                        title: 'Recent patients',
                        actionLabel: 'See all',
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
    duration: const Duration(milliseconds: 520),
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
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

/// The hero "start consultation" visual: a flowing wave with a comet that
/// rides along it and gives one small ripple per cycle when it tops a crest.
/// Decorative only (no mic); loops forever so the card always feels alive.
class _Waveform extends StatefulWidget {
  const _Waveform({this.bars = 30});
  final int bars;

  @override
  State<_Waveform> createState() => _WaveformState();
}

class _CometParticle {
  _CometParticle(this.u, this.vy, this.bornMs);
  final double u;
  final double vy;
  final double bornMs;
}

class _WaveformState extends State<_Waveform>
    with SingleTickerProviderStateMixin {
  late final _ticker = createTicker(_onTick);

  double _nowMs = 0;
  double _lastCu = 0;
  bool _splashedThisCycle = false;
  double _targetU = 0.4;
  final math.Random _rng = math.Random();
  double _cometU = 0;
  double _cometVy = 0;
  List<double> _wave = const [];
  final List<_CometParticle> _splashes = [];
  final List<_CometParticle> _trail = [];

  @override
  void initState() {
    super.initState();
    _ticker.start();
  }

  double _raw(double u, double t) {
    final env = math.sin(u * math.pi);
    return (math.sin(u * 8 - t * 0.003) * 0.6 +
            math.sin(u * 15 - t * 0.0045) * 0.4) *
        env;
  }

  void _onTick(Duration elapsed) {
    final t = elapsed.inMicroseconds / 1000.0;
    _nowMs = t;
    final amp = 0.8 + 0.2 * math.sin(t * 0.0012);

    final n = widget.bars.clamp(12, 120);
    _wave = List<double>.generate(n + 1, (i) => _raw(i / n, t) * amp);

    final cu = (t * 0.00045) % 1.0;
    if (cu < _lastCu) {
      // New sweep: reset and pick a fresh random spot in [0.20, 0.78] so the
      // ripple lands somewhere different each trip across the button.
      _splashedThisCycle = false;
      _targetU = 0.20 + _rng.nextDouble() * 0.58;
    }
    _lastCu = cu;

    final cRaw = _raw(cu, t);
    _cometU = cu;
    _cometVy = cRaw * amp;

    // When the comet reaches this cycle's random target, splash at the highest
    // point of the wave in a small window around it: a real local maximum, at a
    // randomized position, exactly once per sweep (no end-of-wave fallback).
    if (!_splashedThisCycle && cu >= _targetU) {
      var bestU = _targetU;
      var bestV = -2.0;
      for (var uu = _targetU - 0.07; uu <= _targetU + 0.07; uu += 0.01) {
        final v = _raw(uu, t);
        if (v > bestV) {
          bestV = v;
          bestU = uu;
        }
      }
      _splashes.add(_CometParticle(bestU, bestV * amp, t));
      _splashedThisCycle = true;
    }

    _trail.add(_CometParticle(cu, _cometVy, t));
    _splashes.removeWhere((s) => t - s.bornMs > 460);
    _trail.removeWhere((s) => t - s.bornMs > 320);

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: CustomPaint(
        size: Size.infinite,
        painter: _CometWavePainter(
          nowMs: _nowMs,
          wave: _wave,
          cometU: _cometU,
          cometVy: _cometVy,
          splashes: _splashes,
          trail: _trail,
        ),
      ),
    );
  }
}

class _CometWavePainter extends CustomPainter {
  _CometWavePainter({
    required this.nowMs,
    required this.wave,
    required this.cometU,
    required this.cometVy,
    required this.splashes,
    required this.trail,
  });

  final double nowMs;
  final List<double> wave;
  final double cometU;
  final double cometVy;
  final List<_CometParticle> splashes;
  final List<_CometParticle> trail;

  @override
  void paint(Canvas canvas, Size size) {
    if (wave.isEmpty) return;
    canvas.clipRect(Offset.zero & size);
    final cy = size.height / 2;
    final hr = size.height / 2 - 7;

    double sx(double u) => u * size.width;
    double sy(double vy) => cy - vy * hr;

    final path = Path();
    final n = wave.length - 1;
    for (var i = 0; i <= n; i++) {
      final x = i / n * size.width;
      final y = sy(wave[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white.withValues(alpha: 0.6),
    );

    for (final p in trail) {
      final age = nowMs - p.bornMs;
      final a = (1 - age / 320).clamp(0.0, 1.0);
      if (a <= 0) continue;
      canvas.drawCircle(
        Offset(sx(p.u), sy(p.vy)),
        2.0 * a + 0.6,
        Paint()..color = Colors.white.withValues(alpha: a * 0.6),
      );
    }

    for (final s in splashes) {
      final age = nowMs - s.bornMs;
      final a = (1 - age / 460).clamp(0.0, 1.0);
      if (a <= 0) continue;
      final c = Offset(sx(s.u), sy(s.vy));
      canvas.drawCircle(
        c,
        3 + age * 0.04,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: a),
      );
      canvas.drawCircle(
        c,
        2.4 * a,
        Paint()..color = Colors.white.withValues(alpha: a),
      );
    }

    final head = Offset(sx(cometU), sy(cometVy));
    canvas.drawCircle(
      head,
      6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Colors.white.withValues(alpha: 0.55),
    );
    canvas.drawCircle(head, 3.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _CometWavePainter old) => old.nowMs != nowMs;
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
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
            ),
            borderRadius: AppSpacing.radiusMd,
            boxShadow: isDark ? AppColors.glowBlueDark : AppColors.glowBlue,
          ),
          child: const Icon(
            Icons.medical_services_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Rxvarta',
                style: AppTypography.titleMedium.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Smart Medical Documentation',
                style: AppTypography.bodySmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const StatusChip(
          label: 'Online',
          tone: StatusTone.success,
          icon: Icons.circle,
          dense: true,
        ),
      ],
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name, required this.scheme});
  final String name;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    final part = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    final display = name.trim().isEmpty ? 'Doctor' : name.trim();

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
                      'Start new consultation',
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Record and transcribe a patient visit',
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
              label: 'New patient',
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
              label: 'Find patient',
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
              label: 'All patients',
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
    final meta = [
      if (patient.age != null) '${patient.age} yrs',
      _sexLabel(patient.sex),
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

  static String _sexLabel(Sex? sex) {
    switch (sex) {
      case Sex.male:
        return 'Male';
      case Sex.female:
        return 'Female';
      case Sex.other:
        return 'Other';
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
            'No patients yet',
            style: AppTypography.titleSmall.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Start a consultation to add your first patient.',
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
            'Secure • HIPAA Compliant • End-to-End Encrypted',
            style: AppTypography.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
