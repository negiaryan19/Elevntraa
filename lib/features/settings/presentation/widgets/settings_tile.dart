import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Building blocks of the Settings screen and its sheets (Backup, Help &
/// Support, Privacy): a section label, a rounded card, a hairline divider and
/// the two row types (tap row with chevron, toggle row with a switch).
///
/// Kept in one small file so every settings-style surface looks identical.

/// Icon colour presets for a [SettingsTile]. Each resolves to a soft tinted
/// square behind a saturated icon, adjusted for dark mode.
enum SettingsTone { blue, green, violet, orange, amber, red, teal, grey }

class SettingsToneColors {
  const SettingsToneColors({
    required this.background,
    required this.foreground,
  });
  final Color background;
  final Color foreground;
}

SettingsToneColors settingsToneColors(BuildContext context, SettingsTone tone) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (tone) {
    SettingsTone.blue => SettingsToneColors(
      background: dark ? const Color(0xFF1A2060) : const Color(0xFFEFF6FF),
      foreground: const Color(0xFF2563EB),
    ),
    SettingsTone.green => SettingsToneColors(
      background: dark ? const Color(0xFF0D3D2E) : const Color(0xFFECFDF5),
      foreground: const Color(0xFF10B981),
    ),
    SettingsTone.violet => SettingsToneColors(
      background: dark ? const Color(0xFF1E1A40) : const Color(0xFFF5F3FF),
      foreground: const Color(0xFF8B5CF6),
    ),
    SettingsTone.orange => SettingsToneColors(
      background: dark ? const Color(0xFF2A1A0A) : const Color(0xFFFFF7ED),
      foreground: const Color(0xFFF97316),
    ),
    SettingsTone.amber => SettingsToneColors(
      background: dark ? const Color(0xFF2A2410) : const Color(0xFFFFFBEB),
      foreground: const Color(0xFFF59E0B),
    ),
    SettingsTone.red => SettingsToneColors(
      background: dark ? const Color(0xFF3A1A1F) : AppColors.errorSoft,
      foreground: AppColors.error,
    ),
    SettingsTone.teal => SettingsToneColors(
      background: dark ? const Color(0xFF0F3A38) : const Color(0xFFF0FDFA),
      foreground: const Color(0xFF14B8A6),
    ),
    SettingsTone.grey => SettingsToneColors(
      background: dark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
      foreground: dark ? AppColors.darkTextSecondary : AppColors.textSecondary,
    ),
  };
}

/// Upper-case group label above a [SettingsCard].
class SettingsSectionLabel extends StatelessWidget {
  const SettingsSectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.s, bottom: AppSpacing.m),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

/// Rounded, outlined, softly shadowed container for a stack of tiles.
class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppSpacing.radiusXl,
        border: Border.all(color: scheme.outline),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? AppColors.cardShadowDark
            : AppColors.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Column(children: children),
      ),
    );
  }
}

/// Hairline between two tiles, indented past the icon column.
class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: AppSpacing.lg + 40 + AppSpacing.md,
      color: Theme.of(context).colorScheme.outline,
    );
  }
}

/// Tap row: tinted icon square, label, subtitle and a chevron (or a custom
/// [trailing] widget / spinner while [busy]).
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    this.tone = SettingsTone.blue,
    this.iconBg,
    this.iconColor,
    this.leading,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.busy = false,
    this.destructive = false,
    this.subtitleMaxLines = 1,
  });

  final IconData icon;
  final String label;
  final String? subtitle;

  /// Colour preset for the icon square; ignored when [iconBg]/[iconColor]
  /// are given explicitly.
  final SettingsTone tone;
  final Color? iconBg;
  final Color? iconColor;

  /// Replaces the icon square entirely (e.g. a signature thumbnail).
  final Widget? leading;

  /// Replaces the chevron.
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  /// Shows a small progress indicator instead of the chevron and disables
  /// taps.
  final bool busy;

  /// Label and icon in the error colour (destructive actions).
  final bool destructive;
  final int subtitleMaxLines;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = settingsToneColors(context, tone);
    final fg = destructive ? scheme.error : (iconColor ?? colors.foreground);
    final bg = destructive
        ? scheme.errorContainer
        : (iconBg ?? colors.background);
    final interactive = enabled && !busy && onTap != null;

    final labelColor = destructive ? scheme.error : scheme.onSurface;

    return InkWell(
      onTap: interactive ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              leading ??
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: AppSpacing.radiusMd,
                    ),
                    child: Icon(icon, color: fg, size: 20),
                  ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.titleSmall.copyWith(
                        color: labelColor,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTypography.bodySmall.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: subtitleMaxLines,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              if (busy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                trailing ??
                    Icon(
                      Icons.chevron_right_rounded,
                      color: scheme.onSurfaceVariant,
                      size: 20,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Row with a gradient switch on the right. Tapping anywhere toggles.
class SettingsToggleTile extends StatelessWidget {
  const SettingsToggleTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onToggle,
    this.subtitle,
    this.tone = SettingsTone.blue,
    this.iconBg,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final SettingsTone tone;
  final Color? iconBg;
  final Color? iconColor;
  final bool value;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = settingsToneColors(context, tone);
    return Semantics(
      toggled: value,
      button: true,
      label: label,
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg ?? colors.background,
                  borderRadius: AppSpacing.radiusMd,
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? colors.foreground,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.titleSmall.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTypography.bodySmall.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              SettingsToggle(value: value),
            ],
          ),
        ),
      ),
    );
  }
}

/// The brand-gradient switch used by [SettingsToggleTile]. Purely visual:
/// the parent handles taps.
class SettingsToggle extends StatelessWidget {
  const SettingsToggle({super.key, required this.value});
  final bool value;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: 48,
      height: 28,
      decoration: BoxDecoration(
        gradient: value
            ? const LinearGradient(
                colors: [AppColors.gradientStart, AppColors.gradientEnd],
              )
            : null,
        color: value ? null : Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 20,
          height: 20,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small drag handle used at the top of settings bottom sheets.
class SettingsSheetHandle extends StatelessWidget {
  const SettingsSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
