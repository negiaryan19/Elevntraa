import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/locale/locale_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/reveal.dart';
import '../../../domain/models/doctor_profile.dart';
import '../../../l10n/app_localizations.dart';
import '../data/backup_service.dart';
import '../data/doctor_profile_repository.dart';
import '../data/export_service.dart';
import 'backup_sheet.dart';
import 'doctor_profile_form.dart';
import 'help_support_sheet.dart';
import 'legal_screen.dart';
import 'privacy_screen.dart';
import 'signature_capture_sheet.dart';
import 'signature_preview.dart';
import 'widgets/settings_tile.dart';

/// When this device last completed a cloud backup, for the tile subtitle.
final _lastBackupProvider = FutureProvider.autoDispose<DateTime?>(
  (ref) => ref.watch(backupServiceProvider).lastBackupAt(),
);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _signingOut = false;
  bool _savingSignature = false;

  Future<void> _openProfileEditor() async {
    await DoctorProfileFormSheet.show(context);
  }

  Future<void> _openLanguagePicker() async {
    final current = ref.read(appLocaleProvider).languageCode;
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Root navigator so the barrier covers the bottom nav too; otherwise
      // the doctor can switch tabs behind the sheet.
      useRootNavigator: true,
      builder: (_) => _LanguageSheet(current: current),
    );
    if (picked != null && picked != current) {
      await ref.read(appLocaleProvider.notifier).setLocale(picked);
    }
  }

  Future<void> _captureSignature() async {
    final t = AppLocalizations.of(context)!;
    final bytes = await SignatureCaptureSheet.show(context);
    if (bytes == null || !mounted) return;

    setState(() => _savingSignature = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await ref
          .read(doctorProfileProvider.notifier)
          .saveSignature(bytes);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result.synced ? t.signatureSaved : t.profileSavedOffline,
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(t.signatureSaveFailed)));
    } finally {
      if (mounted) setState(() => _savingSignature = false);
    }
  }

  Future<void> _exportData() async {
    await ref.read(exportServiceProvider).exportAndShare(context);
  }

  Future<void> _confirmLogout() async {
    final t = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.logoutConfirmTitle),
        content: Text(t.logoutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.logoutConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _signingOut = true);
    // The auth stream drives the router straight to Login, so there is no
    // manual navigation here.
    await ref.read(authControllerProvider).signOut();
    if (mounted) setState(() => _signingOut = false);
  }

  /// "just now" / "12 minutes ago" / "yesterday" / "3 days ago", falling back
  /// to a plain date once a week has passed.
  String _relative(AppLocalizations t, DateTime when) {
    final diff = DateTime.now().difference(when);
    if (diff.inMinutes < 1) return t.settingsTimeJustNow;
    if (diff.inMinutes < 60) return t.settingsTimeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return t.settingsTimeHoursAgo(diff.inHours);
    if (diff.inDays < 7) return t.settingsTimeDaysAgo(diff.inDays);
    return MaterialLocalizations.of(context).formatMediumDate(when.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final profileAsync = ref.watch(doctorProfileProvider);
    final profile = profileAsync.value ?? DoctorProfile.empty;
    final isDark = ref.watch(themeModeProvider).value == ThemeMode.dark;
    final localeCode = ref.watch(appLocaleProvider).languageCode;
    final languageName = kSupportedLanguages
        .firstWhere(
          (l) => l.code == localeCode,
          orElse: () => kSupportedLanguages.first,
        )
        .nativeName;
    final lastBackup = ref.watch(_lastBackupProvider);
    final version = ref.watch(appVersionProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Reveal(
              delayMs: 0,
              child: _Header(
                profileLoading: profileAsync.isLoading,
                profile: profile,
                onTapProfile: _openProfileEditor,
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Account ───────────────────────────────────────────
                Reveal(
                  delayMs: 90,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SettingsSectionLabel(t.sectionAccount),
                      SettingsCard(
                        children: [
                          SettingsTile(
                            icon: Icons.person_outline_rounded,
                            tone: SettingsTone.blue,
                            label: t.profileSettings,
                            subtitle: t.profileSettingsSubtitle,
                            subtitleMaxLines: 2,
                            onTap: _openProfileEditor,
                          ),
                          const SettingsDivider(),
                          SettingsTile(
                            icon: Icons.draw_outlined,
                            tone: SettingsTone.teal,
                            label: t.settingsSignature,
                            subtitle: profile.hasSignature
                                ? t.settingsSignatureSubtitleAdded
                                : t.settingsSignatureSubtitleMissing,
                            subtitleMaxLines: 2,
                            busy: _savingSignature,
                            leading: profile.hasSignature
                                ? const SizedBox(
                                    width: 56,
                                    child: SignaturePreview(height: 34),
                                  )
                                : null,
                            onTap: _captureSignature,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── Preferences ───────────────────────────────────────
                Reveal(
                  delayMs: 180,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SettingsSectionLabel(t.sectionPreferences),
                      SettingsCard(
                        children: [
                          SettingsToggleTile(
                            icon: isDark
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            tone: isDark
                                ? SettingsTone.blue
                                : SettingsTone.amber,
                            label: t.darkMode,
                            subtitle: isDark
                                ? t.darkThemeActive
                                : t.lightThemeActive,
                            value: isDark,
                            onToggle: () =>
                                ref.read(themeModeProvider.notifier).toggle(),
                          ),
                          const SettingsDivider(),
                          SettingsTile(
                            icon: Icons.translate_rounded,
                            tone: SettingsTone.green,
                            label: t.appLanguage,
                            subtitle: languageName,
                            onTap: _openLanguagePicker,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── Data & Privacy ────────────────────────────────────
                Reveal(
                  delayMs: 270,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SettingsSectionLabel(t.sectionDataPrivacy),
                      SettingsCard(
                        children: [
                          SettingsTile(
                            icon: Icons.backup_outlined,
                            tone: SettingsTone.blue,
                            label: t.settingsBackupSync,
                            subtitle: switch (lastBackup.value) {
                              null => t.settingsBackupSubtitleNever,
                              final at => t.settingsBackupSubtitleLast(
                                _relative(t, at),
                              ),
                            },
                            onTap: () => BackupSheet.show(context).then((_) {
                              ref.invalidate(_lastBackupProvider);
                            }),
                          ),
                          const SettingsDivider(),
                          SettingsTile(
                            icon: Icons.download_outlined,
                            tone: SettingsTone.green,
                            label: t.exportData,
                            subtitle: t.settingsExportSubtitle,
                            subtitleMaxLines: 2,
                            onTap: _exportData,
                          ),
                          const SettingsDivider(),
                          SettingsTile(
                            icon: Icons.shield_outlined,
                            tone: SettingsTone.violet,
                            label: t.privacySecurity,
                            subtitle: t.settingsPrivacySubtitle,
                            subtitleMaxLines: 2,
                            onTap: () => PrivacyScreen.open(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── Legal ─────────────────────────────────────────────
                Reveal(
                  delayMs: 330,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SettingsSectionLabel(t.settingsSectionLegal),
                      SettingsCard(
                        children: [
                          SettingsTile(
                            icon: Icons.description_outlined,
                            tone: SettingsTone.orange,
                            label: t.termsConditions,
                            subtitle: t.termsConditionsSubtitle,
                            subtitleMaxLines: 2,
                            onTap: () =>
                                LegalScreen.open(context, LegalDoc.terms),
                          ),
                          const SettingsDivider(),
                          SettingsTile(
                            icon: Icons.policy_outlined,
                            tone: SettingsTone.violet,
                            label: t.settingsPrivacyPolicy,
                            subtitle: t.settingsPrivacyPolicySubtitle,
                            subtitleMaxLines: 2,
                            onTap: () =>
                                LegalScreen.open(context, LegalDoc.privacy),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── Support ───────────────────────────────────────────
                Reveal(
                  delayMs: 390,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SettingsSectionLabel(t.sectionSupport),
                      SettingsCard(
                        children: [
                          SettingsTile(
                            icon: Icons.help_outline_rounded,
                            tone: SettingsTone.blue,
                            label: t.helpSupport,
                            subtitle: t.helpSupportSubtitle,
                            subtitleMaxLines: 2,
                            onTap: () => HelpSupportSheet.show(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── Sign out + footer ─────────────────────────────────
                Reveal(
                  delayMs: 450,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _LogoutButton(
                        busy: _signingOut,
                        label: _signingOut ? t.settingsSigningOut : t.logout,
                        onTap: _signingOut ? null : _confirmLogout,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        version.when(
                          data: (info) =>
                              t.settingsVersion(info.version, info.buildNumber),
                          loading: () => '',
                          error: (_, _) => '',
                        ),
                        style: AppTypography.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '© ${DateTime.now().year} ${t.allRightsReserved}',
                        style: AppTypography.bodySmall.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.profileLoading,
    required this.profile,
    required this.onTapProfile,
  });

  final bool profileLoading;
  final DoctorProfile profile;
  final VoidCallback onTapProfile;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final hasName = profile.name.trim().isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2563EB), Color(0xFF14B8A6)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: AppSpacing.radiusMd,
                    ),
                    child: const Icon(
                      Icons.settings_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Text(
                    t.settings,
                    style: AppTypography.headlineLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                t.settingsSubtitle,
                style: AppTypography.bodySmall.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: AppSpacing.lg),
              GestureDetector(
                onTap: onTapProfile,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: AppSpacing.radiusXl,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: profileLoading
                                ? const _HeaderSkeleton()
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        hasName
                                            ? profile.name
                                            : t.settingsProfileSetUp,
                                        style: AppTypography.titleMedium
                                            .copyWith(color: Colors.white),
                                      ),
                                      if (profile.qualifications
                                          .trim()
                                          .isNotEmpty) ...[
                                        const SizedBox(height: AppSpacing.xxs),
                                        Text(
                                          profile.qualifications,
                                          style: AppTypography.bodySmall
                                              .copyWith(color: Colors.white70),
                                        ),
                                      ],
                                      if (profile.regNo.trim().isNotEmpty)
                                        Text(
                                          '${t.regPrefix} ${profile.regNo}',
                                          style: AppTypography.labelSmall
                                              .copyWith(color: Colors.white60),
                                        ),
                                    ],
                                  ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.s),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                      // A doctor whose profile is incomplete cannot sign a
                      // prescription — say so where they will see it.
                      if (!profileLoading && !profile.isComplete) ...[
                        const SizedBox(height: AppSpacing.m),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.m,
                            vertical: AppSpacing.s,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: AppSpacing.radiusMd,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                size: 16,
                                color: Color(0xFF92400E),
                              ),
                              const SizedBox(width: AppSpacing.s),
                              Expanded(
                                child: Text(
                                  t.settingsProfileIncompleteChip,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: const Color(0xFF92400E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(4),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [bar(140, 14), bar(100, 10), bar(70, 10)],
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({
    required this.busy,
    required this.label,
    required this.onTap,
  });

  final bool busy;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: AppSpacing.radiusXl,
          border: Border.all(color: scheme.error.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (busy)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.error,
                ),
              )
            else
              Icon(Icons.logout_rounded, color: scheme.error, size: 20),
            const SizedBox(width: AppSpacing.s),
            Text(
              label,
              style: AppTypography.titleSmall.copyWith(color: scheme.error),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Language sheet ──────────────────────────────────────────────────────────

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet({required this.current});
  final String current;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                t.chooseLanguage,
                style: AppTypography.headlineMedium.copyWith(
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                t.appLanguageSubtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              for (final lang in kSupportedLanguages)
                InkWell(
                  onTap: () => Navigator.of(context).pop(lang.code),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang.nativeName,
                                style: AppTypography.titleSmall.copyWith(
                                  color: scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                lang.englishName,
                                style: AppTypography.bodySmall.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (lang.code == current)
                          Icon(
                            Icons.check_circle_rounded,
                            color: scheme.primary,
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
