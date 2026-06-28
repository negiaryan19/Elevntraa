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
const _kBlue300 = Color(0xFF6B8FFF);
const _kTeal500 = Color(0xFF14B8A6);
const _kTeal600 = Color(0xFF0D9488);
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

enum _RecordingMode { choice, addExtra, startNew }

class RecordingScreen extends ConsumerStatefulWidget {
  const RecordingScreen({
    super.key,
    required this.visitId,
    this.append = false,
    this.fromReview = false,
  });

  final String visitId;

  /// When true this is an "Add More" session: the new audio is appended to the
  /// existing consultation transcript (held in [cumulativeTranscriptProvider])
  /// rather than starting a fresh consultation.
  final bool append;

  /// When true the screen was opened from Review screen. Shows a choice UI
  /// instead of the normal recording interface.
  final bool fromReview;

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
  bool _heardVoice = false;

  /// Active recording sub-mode when [widget.fromReview] is true.
  /// null when the screen was opened normally (not from Review).
  _RecordingMode? _mode;

  // Saved before clearing cumulativeTranscriptProvider in _onChoiceStartNew so
  // it can be restored if the doctor abandons the start-new flow mid-recording.
  String? _savedTranscriptBeforeStartNew;

  late final AnimationController _pulse1;
  late final AnimationController _pulse2;

  @override
  void initState() {
    super.initState();
    _mode = widget.fromReview ? _RecordingMode.choice : null;
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

    _heardVoice = false;
    _ampWatch?.cancel();
    _ampWatch = ref.read(recordingServiceProvider).amplitude.listen((a) {
      if (a > 0.02 && !_heardVoice && mounted) {
        setState(() => _heardVoice = true);
      }
    });

    _accumulated = Duration.zero;
    _segmentStartedAt = DateTime.now();
    _startPulse();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (_segmentStartedAt == null || _isPaused) return;
      final segment = DateTime.now().difference(_segmentStartedAt!);
      controller.tickElapsed(_accumulated + segment);
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
      _heardVoice = false;
    });

    final controller = ref.read(
      consultationControllerProvider(widget.visitId).notifier,
    );
    await controller.stopAndProcess();

    if (mounted &&
        ref.read(consultationControllerProvider(widget.visitId)).stage ==
            ConsultationStage.done) {
      // Replace, not push: the user must not be able to swipe back into the
      // (now finished) recording screen from Review. This keeps the stack flat
      // across repeated "Add More" cycles.
      context.pushReplacement(
        AppRoute.review.build(params: {'visitId': widget.visitId}),
      );
    }
  }

  /// Handles every "leave this screen" intent (Android back gesture, hardware
  /// back, AppBar back arrow), gating it on the current recording state:
  /// - idle: leave immediately (no recording happened)
  /// - recording / paused: confirm stop & discard
  /// - transcribing / extracting: block — processing can't be interrupted
  /// - error (with elapsed > 0): confirm discard — recording happened but
  ///   processing failed; the user should not silently lose their session
  Future<void> _attemptExit() async {
    final consultState = ref.read(
      consultationControllerProvider(widget.visitId),
    );
    final stage = consultState.stage;

    if (stage == ConsultationStage.transcribing ||
        stage == ConsultationStage.extracting) {
      return; // busy — ignore back
    }

    if (stage == ConsultationStage.recording) {
      final confirmed = await _confirmDiscardRecording();
      if (!confirmed || !mounted) return;
      await ref
          .read(consultationControllerProvider(widget.visitId).notifier)
          .cancelRecording();
      if (mounted) _leave();
      return;
    }

    // stage == error with elapsed > 0: recording ran but processing failed.
    if (stage == ConsultationStage.error &&
        consultState.elapsed > Duration.zero) {
      final confirmed = await _confirmDiscardStopped();
      if (!confirmed || !mounted) return;
    }

    _leave();
  }

  void _leave() {
    // If the doctor confirmed "Start New" but then abandoned the recording,
    // restore the transcript so future "Add Extra" runs still have it.
    if (_savedTranscriptBeforeStartNew != null) {
      ref.read(cumulativeTranscriptProvider.notifier).state =
          _savedTranscriptBeforeStartNew!;
      _savedTranscriptBeforeStartNew = null;
    }
    if (widget.fromReview) {
      context.pushReplacement(
        AppRoute.review.build(params: {'visitId': widget.visitId}),
      );
    } else {
      context.canPop() ? context.pop() : context.go(AppRoute.home.path);
    }
  }

  Future<bool> _confirmDiscardRecording() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Stop recording and go back?'),
        content: const Text(
          'Your recording will be lost. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Stop & Go Back'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<bool> _confirmDiscardStopped() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard recording?'),
        content: const Text(
          'Your recorded audio will be discarded. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Discard & Go Back'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// "Add Extra Conversation" — keep existing transcript, switch to normal
  /// recording UI so the doctor can record additional audio.
  void _onChoiceAddExtra() => setState(() => _mode = _RecordingMode.addExtra);

  /// "Start New Conversation" — confirm, then clear transcript and controller
  /// state before showing the normal recording UI.
  Future<void> _onChoiceStartNew() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Start fresh?'),
        content: const Text(
          'This will replace your current consultation data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Start Fresh'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _savedTranscriptBeforeStartNew = ref.read(cumulativeTranscriptProvider);
    ref.read(cumulativeTranscriptProvider.notifier).state = '';
    ref.read(consultationControllerProvider(widget.visitId).notifier).reset();
    setState(() => _mode = _RecordingMode.startNew);
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
    // Recording ran but processing failed — still needs a discard confirmation.
    final hasStoppedRecording =
        state.stage == ConsultationStage.error && state.elapsed > Duration.zero;
    final isActiveRecording = isRecording && !_isPaused;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tipColor = isDark ? _kBlue300 : _kBlue600;

    return PopScope(
      // fromReview → always intercept so _leave() can pushReplacement to Review.
      // Otherwise: idle → pop freely; block when recording/processing/error.
      canPop:
          !widget.fromReview && !isRecording && !isBusy && !hasStoppedRecording,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _attemptExit();
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0D0F1A),
                      Color(0xFF13162A),
                      Color(0xFF0D1525),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFEFF6FF),
                      Colors.white,
                      Color(0xFFF0FDFA),
                    ],
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
                        // Always enabled — the discard confirmation is handled
                        // by _attemptExit based on the recording state. Disabled
                        // only while audio is being processed.
                        onPressed: isBusy ? null : _attemptExit,
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: isBusy
                              ? Theme.of(context).colorScheme.onSurfaceVariant
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Consultation Recording',
                              style: AppTypography.headlineMedium.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              isBusy
                                  ? 'Processing audio...'
                                  : _mode == _RecordingMode.choice
                                  ? 'Choose recording option'
                                  : isRecording
                                  ? _isPaused
                                        ? 'Paused'
                                        : 'Recording conversation...'
                                  : 'Doctor + Patient',
                              style: AppTypography.bodySmall.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.append || _mode == _RecordingMode.addExtra)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.s,
                      AppSpacing.lg,
                      0,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.s,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0D3D2E)
                            : const Color(0xFFECFDF5),
                        borderRadius: AppSpacing.radiusLg,
                        border: Border.all(color: _kTeal500),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.add_circle_outline_rounded,
                            color: _kTeal600,
                            size: 18,
                          ),
                          const SizedBox(width: AppSpacing.s),
                          Expanded(
                            child: Text(
                              'Adding to consultation — new audio will be merged '
                              'with the existing transcript.',
                              style: AppTypography.bodySmall.copyWith(
                                color: _kTeal600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                // Progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: _StepProgressBar(activeStep: 1),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Language picker (compact) — hidden in choice mode
                if (_mode != _RecordingMode.choice)
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
                              color: isSelected
                                  ? null
                                  : Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainer,
                              borderRadius: AppSpacing.radiusPill,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                              ),
                            ),
                            child: Text(
                              lang.label,
                              style: AppTypography.labelSmall.copyWith(
                                color: isSelected
                                    ? Colors.white
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                // Tip card — shown only when idle (not in choice mode)
                if (!isRecording && !isBusy && _mode != _RecordingMode.choice)
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
                        color: isDark
                            ? const Color(0xFF1A2060)
                            : const Color(0xFFEFF6FF),
                        borderRadius: AppSpacing.radiusLg,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF3D4470)
                              : const Color(0xFFBFDBFE),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: tipColor,
                            size: 18,
                          ),
                          const SizedBox(width: AppSpacing.s),
                          Expanded(
                            child: Text(
                              'Place phone on the desk between doctor and patient, then tap Start.',
                              style: AppTypography.bodySmall.copyWith(
                                color: tipColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                // Choice UI (returned from Review) or normal recording area
                if (_mode == _RecordingMode.choice)
                  _buildChoiceBody(state, isDark)
                else
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
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
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
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
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
                                              : _heardVoice
                                              ? 'Recording conversation...'
                                              : 'Say something...'
                                        : isBusy
                                        ? _busyLabel(state.stage)
                                        : 'Ready — both voices will be captured',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              // 55-minute soft warning (free-tier batch limit is 1 h)
                              if (isRecording &&
                                  state.elapsed.inMinutes >= 55) ...[
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
                                    color: isDark
                                        ? const Color(0xFF3D2E0A)
                                        : const Color(0xFFFEF3C7),
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
                                        color: Color(0xFFF59E0B),
                                        size: 16,
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      Text(
                                        'Recording approaching limit',
                                        style: AppTypography.labelSmall
                                            .copyWith(
                                              color: isDark
                                                  ? const Color(0xFFFCD34D)
                                                  : const Color(0xFF92400E),
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
                              const SizedBox(height: AppSpacing.lg),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                // Action buttons — hidden in choice mode (choice body has its own CTAs)
                if (_mode != _RecordingMode.choice)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!isRecording && !isBusy)
                          _GradientCta(
                            label: 'Start Consultation',
                            leadingIcon: Icons.record_voice_over_rounded,
                            onTap: _onStartPressed,
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
                            padding: const EdgeInsets.only(top: AppSpacing.s),
                            child: Text(
                              'Minimum 5 seconds required',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmall.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
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

  Widget _buildChoiceBody(ConsultationState state, bool isDark) {
    final tipColor = isDark ? _kBlue300 : _kBlue600;
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Existing recording info banner
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1A2060)
                    : const Color(0xFFEFF6FF),
                borderRadius: AppSpacing.radiusLg,
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF3D4470)
                      : const Color(0xFFBFDBFE),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.audio_file_rounded, color: tipColor, size: 20),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'You have an existing recording for this consultation.',
                          style: AppTypography.bodySmall.copyWith(
                            color: tipColor,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Duration: ${_fmt(state.elapsed)}',
                          style: AppTypography.labelSmall.copyWith(
                            color: tipColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _ChoiceActionCard(
              icon: Icons.mic_rounded,
              title: 'Add Extra Conversation',
              subtitle: 'Record more and merge with existing data',
              gradient: const LinearGradient(colors: [_kBlue600, _kTeal500]),
              onTap: _onChoiceAddExtra,
            ),
            const SizedBox(height: AppSpacing.md),
            _ChoiceActionCard(
              icon: Icons.refresh_rounded,
              title: 'Start New Conversation',
              subtitle: 'Clear previous and record fresh',
              onTap: _onChoiceStartNew,
            ),
          ],
        ),
      ),
    );
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
                    color: i <= activeStep
                        ? null
                        : Theme.of(context).colorScheme.surfaceContainerHigh,
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
                    ? Theme.of(context).colorScheme.primary
                    : i < activeStep
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
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
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: AppSpacing.radiusLg,
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 2,
          ),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: AppSpacing.s),
            Text(
              label,
              style: AppTypography.titleSmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
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

/// Large tappable card used on the "returned from review" choice screen.
class _ChoiceActionCard extends StatelessWidget {
  const _ChoiceActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.gradient,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasGradient = gradient != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: gradient,
          color: hasGradient ? null : scheme.surfaceContainer,
          borderRadius: AppSpacing.radiusLg,
          border: hasGradient
              ? null
              : Border.all(color: scheme.outlineVariant, width: 2),
          boxShadow: hasGradient
              ? const [
                  BoxShadow(
                    color: _kBlueShadow,
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ]
              : AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 28,
              color: hasGradient ? Colors.white : scheme.onSurface,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleSmall.copyWith(
                      color: hasGradient ? Colors.white : scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: hasGradient
                          ? Colors.white.withValues(alpha: 0.8)
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
