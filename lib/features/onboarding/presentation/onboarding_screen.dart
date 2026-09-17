import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/reveal.dart';
import '../../../domain/models/doctor_profile.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/data/doctor_profile_repository.dart';
import '../../settings/presentation/doctor_profile_form.dart';

const _kBlue600 = Color(0xFF2563EB);
const _kTeal500 = Color(0xFF14B8A6);
const _kTeal600 = Color(0xFF0D9488);

/// First-run setup for a signed-in doctor (roadmap items 2–5): the three
/// things every prescription must carry — the doctor, the clinic and a real
/// signature. No step can be skipped; the router keeps the doctor here until
/// [DoctorProfile.isComplete].
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum _Step { doctor, clinic, signature }

/// The in-progress onboarding form, held outside the widget tree.
///
/// Saving the signature updates [doctorProfileProvider], which the router
/// watches; that rebuilds this route and would otherwise recreate the text
/// controllers from the stored (still empty) profile, throwing away what the
/// doctor typed on steps 1 and 2. Cleared once onboarding completes.
final onboardingDraftProvider =
    NotifierProvider<OnboardingDraft, DoctorProfile?>(OnboardingDraft.new);

class OnboardingDraft extends Notifier<DoctorProfile?> {
  @override
  DoctorProfile? build() => null;

  void save(DoctorProfile draft) => state = draft;

  void clear() => state = null;
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  DoctorProfileFormController? _form;
  final _doctorKey = GlobalKey<FormState>();
  final _clinicKey = GlobalKey<FormState>();
  _Step _step = _Step.doctor;
  bool _saving = false;

  @override
  void dispose() {
    _form?.listenable.removeListener(_rememberDraft);
    _form?.dispose();
    super.dispose();
  }

  void _rememberDraft() {
    final form = _form;
    if (form == null) return;
    ref.read(onboardingDraftProvider.notifier).save(form.toDraft());
  }

  GlobalKey<FormState>? _keyFor(_Step step) => switch (step) {
    _Step.doctor => _doctorKey,
    _Step.clinic => _clinicKey,
    _Step.signature => null,
  };

  void _next() {
    final key = _keyFor(_step);
    if (key != null && !(key.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _step = _Step.values[_step.index + 1]);
  }

  void _back() {
    if (_step.index == 0) return;
    FocusScope.of(context).unfocus();
    setState(() => _step = _Step.values[_step.index - 1]);
  }

  Future<void> _finish() async {
    final form = _form;
    if (form == null || _saving) return;
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    if (!ref.read(doctorProfileValueProvider).hasSignature) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(t.onboardingSignatureRequired)));
      return;
    }
    setState(() => _saving = true);
    final result = await saveDoctorProfileWithFeedback(
      ref: ref,
      messenger: messenger,
      t: t,
      draft: form.toDraft(),
      onRetry: _finish,
      announceSuccess: false,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result == null) return;
    final profile = result.profile;
    if (profile.isComplete) {
      form.markSaved();
      ref.read(onboardingDraftProvider.notifier).clear();
      if (!result.synced) {
        messenger
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(t.profileSavedOffline)));
      }
      // The router also redirects on the provider change; navigating here
      // makes the transition immediate.
      context.go(AppRoute.home.path);
      return;
    }
    // Should not happen (each step validated), but never strand the doctor:
    // jump to the first step that still has a gap.
    final missing = profile.missingFields;
    if (missing.contains(DoctorProfileField.signature) && missing.length == 1) {
      messenger.showSnackBar(
        SnackBar(content: Text(t.onboardingSignatureRequired)),
      );
      return;
    }
    final first = missing.first;
    setState(() {
      _step = switch (first) {
        DoctorProfileField.clinicName ||
        DoctorProfileField.clinicAddress => _Step.clinic,
        DoctorProfileField.signature => _Step.signature,
        _ => _Step.doctor,
      };
    });
  }

  Future<void> _signOut() async {
    await ref.read(authControllerProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileAsync = ref.watch(doctorProfileProvider);

    if (_form == null) {
      // A failed first load must not strand the doctor on a spinner: start
      // blank and let the save push the profile.
      final value =
          profileAsync.value ??
          (profileAsync.hasError ? DoctorProfile.empty : null);
      if (value == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      _form = DoctorProfileFormController(
        ref.read(onboardingDraftProvider) ?? value,
      );
      // Mirror every keystroke into the draft provider so a rebuild of this
      // route (the router refreshes when the profile changes) cannot lose it.
      _form!.listenable.addListener(_rememberDraft);
    }
    final form = _form!;
    final email = ref.watch(currentUserProvider)?.email;
    final isLast = _step == _Step.signature;

    return Scaffold(
      backgroundColor: Colors.transparent,
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
                  colors: [Color(0xFFEFF6FF), Colors.white, Color(0xFFF0FDFA)],
                  stops: [0.0, 0.5, 1.0],
                ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.adaptive(context, AppSpacing.lg),
                  AppSpacing.m,
                  0,
                ),
                child: Reveal(
                  delayMs: 0,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_kBlue600, _kTeal500],
                          ),
                          borderRadius: AppSpacing.radiusMd,
                          boxShadow: isDark
                              ? AppColors.glowBlueDark
                              : AppColors.glowBlue,
                        ),
                        child: const Icon(
                          Icons.medical_services_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.onboardingTitle,
                              style: AppTypography.headlineMedium.copyWith(
                                color: scheme.onSurface,
                              ),
                            ),
                            Text(
                              t.onboardingSubtitle,
                              style: AppTypography.bodySmall.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            if (email != null && email.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                t.onboardingSignedInAs(email),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelSmall.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _saving ? null : _signOut,
                        style: TextButton.styleFrom(
                          foregroundColor: scheme.onSurfaceVariant,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s,
                          ),
                        ),
                        icon: const Icon(Icons.logout_rounded, size: 16),
                        label: Text(
                          t.onboardingSignOut,
                          style: AppTypography.labelMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.adaptive(context, AppSpacing.lg)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _StepProgressBar(activeStep: _step.index),
              ),
              SizedBox(height: AppSpacing.adaptive(context, AppSpacing.md)),
              // Step content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xs,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Reveal(
                    key: ValueKey(_step),
                    durationMs: 360,
                    child: _StepCard(
                      child: switch (_step) {
                        _Step.doctor => Form(
                          key: _doctorKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _StepIntro(
                                title: t.onboardingDoctorTitle,
                                body: t.onboardingDoctorBody,
                              ),
                              DoctorProfileFields(
                                controller: form,
                                section: DoctorProfileSection.doctor,
                              ),
                              Text(
                                t.profileRequiredHint,
                                style: AppTypography.bodySmall.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _Step.clinic => Form(
                          key: _clinicKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _StepIntro(
                                title: t.onboardingClinicTitle,
                                body: t.onboardingClinicBody,
                              ),
                              DoctorProfileFields(
                                controller: form,
                                section: DoctorProfileSection.clinic,
                              ),
                            ],
                          ),
                        ),
                        _Step.signature => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _StepIntro(
                              title: t.onboardingSignatureTitle,
                              body: t.onboardingSignatureBody,
                            ),
                            const DoctorSignatureSection(
                              showHeader: false,
                              previewHeight: 150,
                              // The preview shows the result; a snackbar here
                              // would sit on top of the Finish button.
                              announceSuccess: false,
                            ),
                          ],
                        ),
                      },
                    ),
                  ),
                ),
              ),
              _BottomBar(
                canGoBack: _step.index > 0,
                isLast: isLast,
                saving: _saving,
                onBack: _back,
                onNext: isLast ? _finish : _next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _StepProgressBar extends StatelessWidget {
  const _StepProgressBar({required this.activeStep});
  final int activeStep;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context)!;
    final steps = [
      t.onboardingStepDoctor,
      t.onboardingStepClinic,
      t.onboardingStepSignature,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.s),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: i <= activeStep
                        ? const LinearGradient(colors: [_kBlue600, _kTeal500])
                        : null,
                    color: i <= activeStep ? null : scheme.surfaceContainerHigh,
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
            steps.length,
            (i) => Text(
              steps[i],
              style: AppTypography.labelSmall.copyWith(
                color: i == activeStep
                    ? _kBlue600
                    : i < activeStep
                    ? _kTeal600
                    : scheme.onSurfaceVariant,
                fontWeight: i == activeStep ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppSpacing.radiusXl,
        border: Border.all(color: scheme.outline),
        boxShadow: isDark ? AppColors.cardShadowDark : AppColors.cardShadow,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: child,
    );
  }
}

class _StepIntro extends StatelessWidget {
  const _StepIntro({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.titleLarge.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            body,
            style: AppTypography.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.canGoBack,
    required this.isLast,
    required this.saving,
    required this.onBack,
    required this.onNext,
  });

  final bool canGoBack;
  final bool isLast;
  final bool saving;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, -2),
            blurRadius: 12,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.m,
        AppSpacing.lg,
        AppSpacing.m,
      ),
      child: Row(
        children: [
          if (canGoBack) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: saving ? null : onBack,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: Text(t.onboardingBack),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            flex: 2,
            child: _GradientCta(
              label: isLast ? t.onboardingFinish : t.onboardingContinue,
              icon: isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
              busy: saving,
              onTap: saving ? null : onNext,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientCta extends StatelessWidget {
  const _GradientCta({
    required this.label,
    required this.icon,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_kBlue600, _kTeal500]),
          borderRadius: AppSpacing.radiusLg,
          boxShadow: const [
            BoxShadow(
              color: Color(0x4D2563EB),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                style: AppTypography.titleSmall.copyWith(color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            if (busy)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            else
              Icon(icon, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}
