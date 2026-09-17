import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import 'widgets/settings_tile.dart';

/// Version / build number of the running binary, read once.
final appVersionProvider = FutureProvider<PackageInfo>(
  (ref) => PackageInfo.fromPlatform(),
);

/// Settings > Help & Support (roadmap item 27).
///
/// Offers e-mail and WhatsApp support when the build carries
/// `SUPPORT_EMAIL` / `SUPPORT_WHATSAPP` (see [AppConfig]); when neither is
/// set it says so plainly instead of opening a dead link. "Report a problem"
/// pre-fills the e-mail with the app version, platform and a template
/// asking for steps to reproduce.
class HelpSupportSheet extends ConsumerWidget {
  const HelpSupportSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => const HelpSupportSheet(),
    );
  }

  /// Digits of the configured WhatsApp number (wa.me wants no `+`, spaces
  /// or dashes), or null when unset / unusable.
  static String? whatsappDigits(String? raw) {
    if (raw == null) return null;
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    return digits.length < 8 ? null : digits;
  }

  /// `mailto:` with a properly encoded subject and body. `Uri(query:)` would
  /// encode spaces as `+`, which mail clients show literally.
  static Uri mailto({
    required String to,
    required String subject,
    required String body,
  }) {
    final query = {'subject': subject, 'body': body}.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
    return Uri(scheme: 'mailto', path: to, query: query);
  }

  static Uri whatsapp(String digits, {String? text}) => Uri.https(
    'wa.me',
    '/$digits',
    text == null || text.isEmpty ? null : {'text': text},
  );

  static String _platformLabel() {
    try {
      return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
    } catch (_) {
      return 'unknown';
    }
  }

  static String _versionLabel(PackageInfo? info) =>
      info == null ? 'unknown' : '${info.version} (${info.buildNumber})';

  Future<void> _open(BuildContext context, Uri uri) async {
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);
    var ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok) {
      messenger
        ?..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(t.helpCouldNotOpen)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context)!;
    final info = ref.watch(appVersionProvider).value;
    final email = AppConfig.supportEmail;
    final wa = whatsappDigits(AppConfig.supportWhatsapp);
    final configured = email != null || wa != null;
    final version = _versionLabel(info);
    final platform = _platformLabel();

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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SettingsSheetHandle(),
              Text(
                t.helpTitle,
                style: AppTypography.headlineMedium.copyWith(
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                t.helpSubtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (!configured) ...[
                _NotConfiguredNote(text: t.helpNotConfigured),
                const SizedBox(height: AppSpacing.md),
              ],
              SettingsCard(
                children: [
                  if (email != null) ...[
                    SettingsTile(
                      icon: Icons.mail_outline_rounded,
                      tone: SettingsTone.blue,
                      label: t.helpEmail,
                      subtitle: email,
                      onTap: () => _open(
                        context,
                        mailto(
                          to: email,
                          subject: t.helpEmailSubject,
                          body: t.helpEmailBody(version, platform),
                        ),
                      ),
                    ),
                    const SettingsDivider(),
                  ],
                  if (wa != null) ...[
                    SettingsTile(
                      icon: Icons.chat_rounded,
                      tone: SettingsTone.green,
                      label: t.helpWhatsapp,
                      subtitle: '+$wa',
                      onTap: () => _open(
                        context,
                        whatsapp(
                          wa,
                          text: t.helpEmailBody(version, platform).trim(),
                        ),
                      ),
                    ),
                    const SettingsDivider(),
                  ],
                  SettingsTile(
                    icon: Icons.bug_report_outlined,
                    tone: SettingsTone.orange,
                    label: t.helpReportProblem,
                    subtitle: t.helpReportProblemSubtitle,
                    enabled: configured,
                    onTap: !configured
                        ? null
                        : () => _open(
                            context,
                            email != null
                                ? mailto(
                                    to: email,
                                    subject: t.helpReportSubject,
                                    body: t.helpReportBody(version, platform),
                                  )
                                : whatsapp(
                                    wa!,
                                    text: t.helpReportBody(version, platform),
                                  ),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      info == null
                          ? t.appName
                          : t.helpVersion(info.version, info.buildNumber),
                      style: AppTypography.bodySmall.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotConfiguredNote extends StatelessWidget {
  const _NotConfiguredNote({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = settingsToneColors(context, SettingsTone.amber);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: AppSpacing.radiusMd,
        border: Border.all(color: colors.foreground.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: colors.foreground),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
