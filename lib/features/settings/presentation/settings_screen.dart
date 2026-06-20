import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/reveal.dart';
import '../../../domain/models/doctor_profile.dart';
import '../data/doctor_profile_repository.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Future<void> _openProfileEditor() async {
    final current = ref.read(doctorProfileControllerProvider);
    final updated = await showModalBottomSheet<DoctorProfile>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(initial: current),
    );
    if (updated != null) {
      await ref.read(doctorProfileControllerProvider.notifier).update(updated);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile updated')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctor = ref.watch(doctorProfileControllerProvider);
    final isDark = ref.watch(themeModeProvider).value == ThemeMode.dark;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Gradient header ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Reveal(
              delayMs: 0,
              child: Container(
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
                              'Settings',
                              style: AppTypography.headlineLarge.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Manage your app preferences',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        // Profile card
                        GestureDetector(
                          onTap: _openProfileEditor,
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
                            child: Row(
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
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doctor.name,
                                        style: AppTypography.titleMedium
                                            .copyWith(color: Colors.white),
                                      ),
                                      const SizedBox(height: AppSpacing.xxs),
                                      Text(
                                        doctor.qualifications,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: Colors.white70,
                                        ),
                                      ),
                                      Text(
                                        'Reg. ${doctor.regNo}',
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
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Account group
                Reveal(
                  delayMs: 90,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionLabel('Account'),
                      _SettingsCard(
                        children: [
                          _Tile(
                            icon: Icons.person_outline_rounded,
                            iconBg:
                                Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF1A2060)
                                : const Color(0xFFEFF6FF),
                            iconColor: const Color(0xFF2563EB),
                            label: 'Profile Settings',
                            subtitle: 'Update your name and clinic details',
                            onTap: _openProfileEditor,
                          ),
                          _Divider(),
                          _Tile(
                            icon: Icons.medical_services_outlined,
                            iconBg:
                                Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF0D3D2E)
                                : const Color(0xFFECFDF5),
                            iconColor: const Color(0xFF10B981),
                            label: 'Medical Credentials',
                            subtitle: 'Qualifications and registration number',
                            onTap: _openProfileEditor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Preferences group
                Reveal(
                  delayMs: 180,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionLabel('Preferences'),
                      _SettingsCard(
                        children: [
                          // Dark mode — wired to real provider
                          _ToggleTile(
                            icon: isDark
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            iconBg: isDark
                                ? const Color(0xFF1D2235)
                                : const Color(0xFFFFFBEB),
                            iconColor: isDark
                                ? const Color(0xFF60A5FA)
                                : const Color(0xFFF59E0B),
                            label: 'Dark Mode',
                            subtitle: isDark
                                ? 'Dark theme active'
                                : 'Light theme active',
                            value: isDark,
                            onToggle: () =>
                                ref.read(themeModeProvider.notifier).toggle(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Data & Privacy group
                Reveal(
                  delayMs: 270,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionLabel('Data & Privacy'),
                      _SettingsCard(
                        children: [
                          _Tile(
                            icon: Icons.backup_outlined,
                            iconBg:
                                Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF1A2060)
                                : const Color(0xFFEFF6FF),
                            iconColor: const Color(0xFF2563EB),
                            label: 'Data Backup',
                            subtitle: 'Backup your consultation history',
                          ),
                          _Divider(),
                          _Tile(
                            icon: Icons.download_outlined,
                            iconBg:
                                Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF0D3D2E)
                                : const Color(0xFFECFDF5),
                            iconColor: const Color(0xFF10B981),
                            label: 'Export Data',
                            subtitle: 'Download all your data',
                          ),
                          _Divider(),
                          _Tile(
                            icon: Icons.shield_outlined,
                            iconBg:
                                Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF1E1A40)
                                : const Color(0xFFF5F3FF),
                            iconColor: const Color(0xFF8B5CF6),
                            label: 'Privacy & Security',
                            subtitle: 'Manage your privacy settings',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Support group
                Reveal(
                  delayMs: 360,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionLabel('Support'),
                      _SettingsCard(
                        children: [
                          _Tile(
                            icon: Icons.description_outlined,
                            iconBg:
                                Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF2A1A0A)
                                : const Color(0xFFFFF7ED),
                            iconColor: const Color(0xFFF97316),
                            label: 'Terms & Conditions',
                            subtitle: 'Read our terms of service',
                          ),
                          _Divider(),
                          _Tile(
                            icon: Icons.help_outline_rounded,
                            iconBg:
                                Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF1A2060)
                                : const Color(0xFFEFF6FF),
                            iconColor: const Color(0xFF2563EB),
                            label: 'Help & Support',
                            subtitle: 'Get help or contact us',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Logout + footer
                Reveal(
                  delayMs: 440,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: AppSpacing.radiusXl,
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.logout_rounded,
                                color: Color(0xFFDC2626),
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.s),
                              Text(
                                'Logout',
                                style: AppTypography.titleSmall.copyWith(
                                  color: const Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Rxvarta v1.0.0',
                        style: AppTypography.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '© 2026 All rights reserved',
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

// ── Reusable sub-widgets ──────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
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

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
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

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: AppSpacing.lg + 40 + AppSpacing.md,
      color: Theme.of(context).colorScheme.outline,
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: AppSpacing.radiusMd,
              ),
              child: Icon(icon, color: iconColor, size: 20),
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
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
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onToggle,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String subtitle;
  final bool value;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: AppSpacing.radiusMd,
              ),
              child: Icon(icon, color: iconColor, size: 20),
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            _Toggle(value: value),
          ],
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.value});
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
                colors: [Color(0xFF2563EB), Color(0xFF14B8A6)],
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

// ── Edit Profile Sheet ────────────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.initial});
  final DoctorProfile initial;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _name;
  late final TextEditingController _quals;
  late final TextEditingController _regNo;
  late final TextEditingController _clinicName;
  late final TextEditingController _clinicAddress;
  late final TextEditingController _clinicPhone;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _name = TextEditingController(text: p.name);
    _quals = TextEditingController(text: p.qualifications);
    _regNo = TextEditingController(text: p.regNo);
    _clinicName = TextEditingController(text: p.clinicName);
    _clinicAddress = TextEditingController(text: p.clinicAddress);
    _clinicPhone = TextEditingController(text: p.clinicPhone);
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _quals,
      _regNo,
      _clinicName,
      _clinicAddress,
      _clinicPhone,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      DoctorProfile(
        name: _name.text.trim(),
        qualifications: _quals.text.trim(),
        regNo: _regNo.text.trim(),
        clinicName: _clinicName.text.trim(),
        clinicAddress: _clinicAddress.text.trim(),
        clinicPhone: _clinicPhone.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
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
                  'Edit Profile',
                  style: AppTypography.headlineMedium.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Appears on prescription letterhead.',
                  style: AppTypography.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _Field(
                  label: 'Doctor name',
                  controller: _name,
                  hint: 'Dr. Rajesh Sharma',
                  required: true,
                ),
                _Field(
                  label: 'Qualifications',
                  controller: _quals,
                  hint: 'MBBS, MD (Medicine)',
                  required: true,
                ),
                _Field(
                  label: 'Registration number',
                  controller: _regNo,
                  hint: 'MH-12345',
                  required: true,
                ),
                _Field(
                  label: 'Clinic / Hospital name',
                  controller: _clinicName,
                  hint: 'Rxvarta Clinic',
                ),
                _Field(
                  label: 'Clinic address',
                  controller: _clinicAddress,
                  hint: 'Area, City, State PIN',
                  maxLines: 2,
                ),
                _Field(
                  label: 'Clinic phone',
                  controller: _clinicPhone,
                  hint: '+91 98765 43210',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _save,
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.required = false,
    this.maxLines = 1,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final bool required;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: AppTypography.bodyMedium.copyWith(color: scheme.onSurface),
            validator: required
                ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
                : null,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
    );
  }
}
