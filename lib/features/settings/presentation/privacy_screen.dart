import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../data/local_data_wiper.dart';
import 'legal_screen.dart';
import 'widgets/settings_tile.dart';

/// Settings > Privacy & Security (roadmap item 26).
///
/// States plainly where data lives, who processes it, how long it is kept and
/// who is responsible for what under the DPDP Act, and offers the one
/// destructive action a doctor may genuinely need on a shared or sold phone:
/// deleting everything this device holds.
class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const PrivacyScreen()));
  }

  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen> {
  bool _wiping = false;

  Future<void> _confirmAndWipe() async {
    final t = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _DeleteConfirmDialog(word: t.privacyDeleteLocalWord),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _wiping = true);
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(t.privacyDeleting),
        duration: const Duration(seconds: 30),
      ),
    );

    LocalWipeReport report;
    try {
      report = await LocalDataWiper.wipe(ref);
    } catch (e) {
      report = LocalWipeReport(errors: [e.toString()]);
    }

    // Sign out last: the router then leaves this screen for Login on its own.
    try {
      await ref.read(authControllerProvider).signOut();
    } catch (_) {
      // Already reported through the wipe result; the local session is gone
      // either way.
    }

    if (!mounted) return;
    setState(() => _wiping = false);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            report.ok
                ? t.privacyDeleted
                : t.privacyDeletePartial(report.errors.join(', ')),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(t.privacySecurity)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          Text(
            t.privacyIntro,
            style: AppTypography.bodyMedium.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          _Section(
            icon: Icons.phone_iphone_rounded,
            tone: SettingsTone.blue,
            title: t.privacyWhereStoredTitle,
            bullets: [
              t.privacyWhereStoredDevice,
              t.privacyWhereStoredCloud,
              t.privacyWhereStoredAudio,
            ],
          ),
          _Section(
            icon: Icons.hub_outlined,
            tone: SettingsTone.violet,
            title: t.privacyProcessorsTitle,
            bullets: [
              t.privacyProcessorSarvam,
              t.privacyProcessorGoogle,
              t.privacyProcessorSupabase,
            ],
          ),
          _Section(
            icon: Icons.schedule_rounded,
            tone: SettingsTone.teal,
            title: t.privacyRetentionTitle,
            bullets: [
              t.privacyRetentionAudio,
              t.privacyRetentionTranscript,
              t.privacyRetentionJobs,
            ],
          ),
          _Section(
            icon: Icons.gavel_rounded,
            tone: SettingsTone.orange,
            title: t.privacyRoleTitle,
            body: t.privacyRoleBody,
          ),
          _Section(
            icon: Icons.lock_outline_rounded,
            tone: SettingsTone.green,
            title: t.privacySecurityTitle,
            body: t.privacySecurityBody,
          ),
          _Section(
            icon: Icons.delete_outline_rounded,
            tone: SettingsTone.grey,
            title: t.privacyDeleteTitle,
            body: t.privacyDeleteBody,
          ),

          const SizedBox(height: AppSpacing.s),
          SettingsCard(
            children: [
              SettingsTile(
                icon: Icons.policy_outlined,
                label: t.privacyReadPolicy,
                tone: SettingsTone.violet,
                onTap: () => LegalScreen.open(context, LegalDoc.privacy),
              ),
              const SettingsDivider(),
              SettingsTile(
                icon: Icons.delete_forever_rounded,
                label: t.privacyDeleteLocal,
                subtitle: t.privacyDeleteLocalSubtitle,
                subtitleMaxLines: 3,
                destructive: true,
                busy: _wiping,
                onTap: _confirmAndWipe,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Typed-word confirmation: deleting every record on the phone should take a
/// deliberate act, not one stray tap.
class _DeleteConfirmDialog extends StatefulWidget {
  const _DeleteConfirmDialog({required this.word});
  final String word;

  @override
  State<_DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends State<_DeleteConfirmDialog> {
  final _controller = TextEditingController();
  bool _matches = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final next =
          _controller.text.trim().toUpperCase() == widget.word.toUpperCase();
      if (next != _matches) setState(() => _matches = next);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(t.privacyDeleteLocal),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.privacyDeleteLocalBody(widget.word),
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: t.privacyDeleteLocalHint(widget.word),
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(t.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: _matches ? () => Navigator.of(context).pop(true) : null,
          child: Text(t.privacyDeleteLocalConfirm),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.tone,
    required this.title,
    this.body,
    this.bullets = const [],
  });

  final IconData icon;
  final SettingsTone tone;
  final String title;
  final String? body;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = settingsToneColors(context, tone);
    final text = AppTypography.bodyMedium.copyWith(
      color: scheme.onSurfaceVariant,
      height: 1.5,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: AppSpacing.radiusSm,
                ),
                child: Icon(icon, size: 18, color: colors.foreground),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          if (body != null) Text(body!, style: text),
          for (final bullet in bullets)
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.xs,
                left: AppSpacing.xs,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: colors.foreground,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(child: Text(bullet, style: text)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
