import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/mic_permission.dart';
import '../data/recording_service.dart';
import 'consultation_controller.dart';
import 'widgets/live_waveform.dart';

const _kBlue600 = Color(0xFF2563EB);
const _kTeal500 = Color(0xFF14B8A6);
const _kBlueShadow = Color(0x4D2563EB);

class _Language {
  const _Language(this.code, this.label);
  final String code;
  final String label;
}

const _languages = [
  _Language('unknown', 'Auto-detect'),
  _Language('hi-IN', 'Hindi'),
  _Language('en-IN', 'English'),
  _Language('bn-IN', 'Bengali'),
  _Language('mr-IN', 'Marathi'),
  _Language('gu-IN', 'Gujarati'),
  _Language('pa-IN', 'Punjabi'),
  _Language('ta-IN', 'Tamil'),
  _Language('te-IN', 'Telugu'),
  _Language('kn-IN', 'Kannada'),
  _Language('ml-IN', 'Malayalam'),
  _Language('od-IN', 'Odia'),
];

class RecordingScreen extends ConsumerStatefulWidget {
  const RecordingScreen({super.key, required this.visitId});

  final String visitId;

  @override
  ConsumerState<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends ConsumerState<RecordingScreen>
    with TickerProviderStateMixin {
  Timer? _ticker;
  DateTime? _segmentStartedAt;
  Duration _accumulated = Duration.zero;
  bool _isPaused = false;

  /// Live mic health check. If the recorder runs but the amplitude stream
  /// never rises above the noise floor, the OS is delivering no audio
  /// (mic permission off in iOS Settings, or input routed elsewhere) and
  /// the file will be silent — surface that while recording, not after.
  StreamSubscription<double>? _ampWatch;
  double _peakAmp = 0;
  bool _silenceHint = false;

  late final AnimationController _pulse1;
  late final AnimationController _pulse2;

  @override
  void initState() {
    super.initState();
    _pulse1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulse2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ampWatch?.cancel();
    _pulse1.dispose();
    _pulse2.dispose();
    super.dispose();
  }

  void _startPulse() {
    _pulse1.repeat();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _pulse2.repeat();
    });
  }

  void _stopPulse() {
    _pulse1.stop();
    _pulse2.stop();
    _pulse1.reset();
    _pulse2.reset();
  }

  Future<void> _onStartPressed() async {
    final granted = await MicPermission.isGranted();
    if (!granted) {
      final result = await MicPermission.request();
      if (result == MicPermissionResult.permanentlyDenied) {
        if (mounted) _showPermissionSheet();
        return;
      }
      if (result != MicPermissionResult.granted) {
        // Plain (non-permanent) denial — the OS will ask again next time, so
        // don't deep-link to settings, just tell the doctor why nothing
        // happened instead of failing silently.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Microphone permission is needed to record the consultation.',
              ),
            ),
          );
        }
        return;
      }
    }

    final controller = ref.read(
      consultationControllerProvider(widget.visitId).notifier,
    );
    await controller.startRecording();

    // startRecording catches its own failures and parks the state in
    // ConsultationStage.error. If the recorder never actually started, bail
    // out before wiring up the timer/pulse so the UI doesn't pretend it's
    // recording — the error banner is already shown by the build method.
    if (!mounted ||
        ref.read(consultationControllerProvider(widget.visitId)).stage !=
            ConsultationStage.recording) {
      return;
    }

    _peakAmp = 0;
    _silenceHint = false;
    _ampWatch?.cancel();
    _ampWatch = ref.read(recordingServiceProvider).amplitude.listen((a) {
      if (a > _peakAmp) _peakAmp = a;
    });

    _accumulated = Duration.zero;
    _segmentStartedAt = DateTime.now();
    _startPulse();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (_segmentStartedAt == null || _isPaused) return;
      final segment = DateTime.now().difference(_segmentStartedAt!);
      controller.tickElapsed(_accumulated + segment);

      // 4s of recording without a single amplitude blip means no audio is
      // reaching us — warn now so the doctor doesn't lose the consultation.
      final silent =
          _accumulated + segment > const Duration(seconds: 4) &&
          _peakAmp < 0.02;
      if (silent != _silenceHint && mounted) {
        setState(() => _silenceHint = silent);
      }
    });
  }

  Future<void> _onPauseResume() async {
    final controller = ref.read(
      consultationControllerProvider(widget.visitId).notifier,
    );
    final willPause = !_isPaused;
    setState(() => _isPaused = willPause);
    if (willPause) {
      // Bank what we've recorded so far so elapsed doesn't grow while paused.
      if (_segmentStartedAt != null) {
        _accumulated += DateTime.now().difference(_segmentStartedAt!);
        _segmentStartedAt = null;
      }
      _stopPulse();
      await controller.pauseRecording();
    } else {
      _segmentStartedAt = DateTime.now();
      _startPulse();
      await controller.resumeRecording();
    }
  }

  Future<void> _onDone() async {
    _ticker?.cancel();
    _ampWatch?.cancel();
    _stopPulse();
    setState(() {
      _isPaused = false;
      _silenceHint = false;
    });

    final controller = ref.read(
      consultationControllerProvider(widget.visitId).notifier,
    );
    await controller.stopAndProcess();

    if (mounted &&
        ref.read(consultationControllerProvider(widget.visitId)).stage ==
            ConsultationStage.done) {
      context.go(AppRoute.review.build(params: {'visitId': widget.visitId}));
    }
  }

  void _showPermissionSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.mic_off_rounded,
              size: 36,
              color: AppColors.warning,
            ),
            AppSpacing.gapMd,
            Text(
              'Microphone access needed',
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            AppSpacing.gapS,
            Text(
              'Enable microphone permission in settings to record.',
              textAlign: TextAlign.center,
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            AppSpacing.gapLg,
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                MicPermission.openSettings();
              },
              child: const Text('Open settings'),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(consultationControllerProvider(widget.visitId));
    final recorder = ref.watch(recordingServiceProvider);

    final isRecording = state.stage == ConsultationStage.recording;
    final isBusy =
        state.stage == ConsultationStage.transcribing ||
        state.stage == ConsultationStage.extracting;
    final isActiveRecording = isRecording && !_isPaused;

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
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s,
                  AppSpacing.md,
                  AppSpacing.lg,
                  0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: isRecording
                          ? null
                          : () => context.canPop()
                                ? context.pop()
                                : context.go('/'),
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: isRecording
                            ? AppColors.textMuted
                            : const Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Consultation Recording',
                            style: AppTypography.headlineMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            isBusy
                                ? 'Processing audio...'
                                : isRecording
                                ? _isPaused
                                      ? 'Paused'
                                      : 'Recording conversation...'
                                : 'Doctor + Patient',
                            style: AppTypography.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _StepProgressBar(activeStep: 1),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Language picker (compact)
              SizedBox(
                height: 36,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  scrollDirection: Axis.horizontal,
                  itemCount: _languages.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.s),
                  itemBuilder: (_, i) {
                    final lang = _languages[i];
                    final isSelected = lang.code == state.languageCode;
                    return GestureDetector(
                      onTap: (!isRecording && !isBusy)
                          ? () => ref
                                .read(
                                  consultationControllerProvider(
                                    widget.visitId,
                                  ).notifier,
                                )
                                .setLanguage(lang.code)
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [_kBlue600, _kTeal500],
                                )
                              : null,
                          color: isSelected ? null : Colors.white,
                          borderRadius: AppSpacing.radiusPill,
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : const Color(0xFFD1D5DB),
                          ),
                        ),
                        child: Text(
                          lang.label,
                          style: AppTypography.labelSmall.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Tip card — shown only when idle
              if (!isRecording && !isBusy)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.m,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: AppSpacing.radiusLg,
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: _kBlue600,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.s),
                        Expanded(
                          child: Text(
                            'Place phone on the desk between doctor and patient, then tap Start.',
                            style: AppTypography.bodySmall.copyWith(
                              color: _kBlue600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              // Main recording area — scrollable so error text never overflows
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Large circle + pulse
                          AnimatedBuilder(
                            animation: Listenable.merge([_pulse1, _pulse2]),
                            builder: (context, _) {
                              return SizedBox(
                                width: 240,
                                height: 240,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    if (isActiveRecording) ...[
                                      _PulseRing(
                                        progress: _pulse1.value,
                                        baseSize: 192,
                                        maxScale: 1.5,
                                        color: const Color(0xFF60A5FA),
                                      ),
                                      _PulseRing(
                                        progress: _pulse2.value,
                                        baseSize: 192,
                                        maxScale: 1.8,
                                        color: _kTeal500,
                                      ),
                                    ],
                                    Container(
                                      width: 192,
                                      height: 192,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [_kBlue600, _kTeal500],
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: isActiveRecording
                                                ? _kBlueShadow
                                                : const Color(0x1A000000),
                                            blurRadius: isActiveRecording
                                                ? 40
                                                : 20,
                                          ),
                                        ],
                                      ),
                                      child: isBusy
                                          ? const CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 3,
                                            )
                                          : Icon(
                                              isRecording
                                                  ? Icons.mic_rounded
                                                  : Icons
                                                        .record_voice_over_rounded,
                                              color: Colors.white,
                                              size: 80,
                                            ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          // Waveform
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                            ),
                            child: LiveWaveform(
                              amplitudeStream: recorder.amplitude,
                              active: isActiveRecording,
                              barCount: 40,
                              height: 80,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          // Timer
                          Text(
                            _fmt(state.elapsed),
                            style: AppTypography.displayMedium.copyWith(
                              color: isActiveRecording
                                  ? _kBlue600
                                  : AppColors.textSecondary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isActiveRecording
                                      ? Colors.red
                                      : const Color(0xFFD1D5DB),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                isRecording
                                    ? _isPaused
                                          ? 'Paused'
                                          : 'Recording conversation...'
                                    : isBusy
                                    ? _busyLabel(state.stage)
                                    : 'Ready — both voices will be captured',
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                          // Live "mic is silent" warning — recording is running but
                          // no audio is arriving, so the file will be empty.
                          if (isActiveRecording && _silenceHint) ...[
                            const SizedBox(height: AppSpacing.md),
                            GestureDetector(
                              onTap: MicPermission.openSettings,
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.s,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: AppSpacing.radiusMd,
                                  border: Border.all(
                                    color: const Color(0xFFF59E0B),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.mic_off_rounded,
                                      color: Color(0xFFD97706),
                                      size: 16,
                                    ),
                                    const SizedBox(width: AppSpacing.s),
                                    Expanded(
                                      child: Text(
                                        'No audio detected. Check that Microphone '
                                        'is ON for Rxvarta in iPhone Settings, '
                                        'and disconnect Bluetooth headphones. '
                                        'Tap here to open Settings.',
                                        style: AppTypography.labelSmall
                                            .copyWith(
                                              color: const Color(0xFF92400E),
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          // 55-minute soft warning (free-tier batch limit is 1 h)
                          if (isRecording && state.elapsed.inMinutes >= 55) ...[
                            const SizedBox(height: AppSpacing.md),
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.s,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: AppSpacing.radiusMd,
                                border: Border.all(
                                  color: const Color(0xFFF59E0B),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Color(0xFFD97706),
                                    size: 16,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    'Recording approaching limit',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: const Color(0xFF92400E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (state.error != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                              ),
                              child: Text(
                                state.error!,
                                textAlign: TextAlign.center,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.xxl),
                          // Buttons
                          if (!isRecording && !isBusy)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                              ),
                              child: _GradientCta(
                                label: 'Start Consultation',
                                leadingIcon: Icons.record_voice_over_rounded,
                                onTap: _onStartPressed,
                              ),
                            )
                          else if (isRecording)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _OutlineButton(
                                  icon: _isPaused
                                      ? Icons.play_arrow_rounded
                                      : Icons.pause_rounded,
                                  label: _isPaused ? 'Resume' : 'Pause',
                                  onTap: _onPauseResume,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                _GreenButton(
                                  icon: Icons.check_rounded,
                                  label: 'Done',
                                  enabled: state.elapsed.inSeconds >= 5,
                                  onTap: state.elapsed.inSeconds >= 5
                                      ? _onDone
                                      : null,
                                ),
                              ],
                            ),
                          if (state.elapsed.inSeconds < 5 && isRecording)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.md,
                              ),
                              child: Text(
                                'Minimum 5 seconds required',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _busyLabel(ConsultationStage s) {
    return s == ConsultationStage.transcribing
        ? 'Transcribing conversation...'
        : 'Extracting prescription...';
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _StepProgressBar extends StatelessWidget {
  const _StepProgressBar({required this.activeStep});

  final int activeStep;
  static const _steps = ['Details', 'Recording', 'Review', 'Share'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < _steps.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: i <= activeStep
                        ? const LinearGradient(colors: [_kBlue600, _kTeal500])
                        : null,
                    color: i <= activeStep ? null : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            _steps.length,
            (i) => Text(
              _steps[i],
              style: AppTypography.labelSmall.copyWith(
                color: i == activeStep
                    ? _kBlue600
                    : i < activeStep
                    ? const Color(0xFF0D9488)
                    : const Color(0xFF9CA3AF),
                fontWeight: i == activeStep ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PulseRing extends StatelessWidget {
  const _PulseRing({
    required this.progress,
    required this.baseSize,
    required this.maxScale,
    required this.color,
  });

  final double progress;
  final double baseSize;
  final double maxScale;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scale = 1.0 + (maxScale - 1.0) * progress;
    final opacity = (0.7 * (1.0 - progress)).clamp(0.0, 1.0);
    return Transform.scale(
      scale: scale,
      child: Container(
        width: baseSize,
        height: baseSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: opacity), width: 3),
        ),
      ),
    );
  }
}

class _GradientCta extends StatelessWidget {
  const _GradientCta({
    required this.label,
    required this.leadingIcon,
    required this.onTap,
  });

  final String label;
  final IconData leadingIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kBlue600, _kTeal500],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: AppSpacing.radiusLg,
          boxShadow: const [
            BoxShadow(
              color: _kBlueShadow,
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(leadingIcon, color: Colors.white, size: 22),
            const SizedBox(width: AppSpacing.m),
            Text(
              label,
              style: AppTypography.titleSmall.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: 18,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppSpacing.radiusLg,
          border: Border.all(color: const Color(0xFFD1D5DB), width: 2),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.textPrimary),
            const SizedBox(width: AppSpacing.s),
            Text(label, style: AppTypography.titleSmall),
          ],
        ),
      ),
    );
  }
}

class _GreenButton extends StatelessWidget {
  const _GreenButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: 18,
        ),
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [Color(0xFF16A34A), Color(0xFF10B981)],
                )
              : null,
          color: enabled ? null : const Color(0xFFE5E7EB),
          borderRadius: AppSpacing.radiusLg,
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: const Color(0x4D16A34A),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: enabled ? Colors.white : const Color(0xFF9CA3AF),
            ),
            const SizedBox(width: AppSpacing.s),
            Text(
              label,
              style: AppTypography.titleSmall.copyWith(
                color: enabled ? Colors.white : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
