import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/doctor_profile.dart';
import '../data/doctor_profile_repository.dart';

const _kBlue600 = Color(0xFF2563EB);
const _kTeal500 = Color(0xFF14B8A6);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

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
    final groups = _buildGroups();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // Gradient header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [_kBlue600, _kTeal500],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.adaptive(context, AppSpacing.lg),
                  AppSpacing.lg,
                  AppSpacing.adaptive(context, AppSpacing.lg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: AppTypography.headlineLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Manage your app preferences',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Profile card (tap to edit)
                    GestureDetector(
                      onTap: _openProfileEditor,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: AppSpacing.radiusXl,
                        ),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            Container(
                              width: AppSpacing.adaptiveSize(context, 64, min: 44),
                              height: AppSpacing.adaptiveSize(context, 64, min: 44),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: _kBlue600,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doctor.name,
                                    style: AppTypography.titleMedium.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(
                                    doctor.qualifications,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Text(
                                    'Reg. No: ${doctor.regNo}',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: Colors.white60,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.s),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                color: Colors.white,
                                size: 18,
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
          // Settings list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.lg,
              ),
              children: [
                ...groups.map((group) => _SettingsGroup(group: group)),
                const SizedBox(height: AppSpacing.md),
                // Logout
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: AppSpacing.radiusXl,
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
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Rxvarta v1.0.0',
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '© 2026 All rights reserved',
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_Group> _buildGroups() => [
    _Group(
      title: 'Account',
      items: [
        _GroupItem(
          icon: Icons.person_outline_rounded,
          label: 'Profile Settings',
          description: 'Update your name and clinic details',
          onTap: _openProfileEditor,
        ),
        _GroupItem(
          icon: Icons.medical_services_outlined,
          label: 'Medical Credentials',
          description: 'Qualifications and registration number',
          onTap: _openProfileEditor,
        ),
      ],
    ),
    _Group(
      title: 'Preferences',
      items: [
        _GroupItem(
          icon: Icons.notifications_outlined,
          label: 'Notifications',
          description: 'Manage notification preferences',
          toggleValue: _notificationsEnabled,
          onToggle: () =>
              setState(() => _notificationsEnabled = !_notificationsEnabled),
        ),
        _GroupItem(
          icon: Icons.dark_mode_outlined,
          label: 'Dark Mode',
          description: 'Switch to dark theme',
          toggleValue: _darkModeEnabled,
          onToggle: () => setState(() => _darkModeEnabled = !_darkModeEnabled),
        ),
        _GroupItem(
          icon: Icons.language_rounded,
          label: 'Language',
          description: 'English (US)',
        ),
      ],
    ),
    _Group(
      title: 'Data & Privacy',
      items: [
        _GroupItem(
          icon: Icons.backup_outlined,
          label: 'Data Backup',
          description: 'Backup your consultation history',
        ),
        _GroupItem(
          icon: Icons.download_outlined,
          label: 'Export Data',
          description: 'Download all your data',
        ),
        _GroupItem(
          icon: Icons.shield_outlined,
          label: 'Privacy & Security',
          description: 'Manage your privacy settings',
        ),
      ],
    ),
    _Group(
      title: 'Support',
      items: [
        _GroupItem(
          icon: Icons.description_outlined,
          label: 'Terms & Conditions',
          description: 'Read our terms of service',
        ),
        _GroupItem(
          icon: Icons.help_outline_rounded,
          label: 'Help & Support',
          description: 'Get help or contact us',
        ),
      ],
    ),
  ];
}

/// Bottom-sheet form for editing the doctor / clinic identity. Pops with the
/// updated [DoctorProfile] on save, or null if dismissed.
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
    _name.dispose();
    _quals.dispose();
    _regNo.dispose();
    _clinicName.dispose();
    _clinicAddress.dispose();
    _clinicPhone.dispose();
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('Edit Profile', style: AppTypography.headlineMedium),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'This appears on the prescription letterhead and signature.',
                  style: AppTypography.bodySmall,
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
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppSpacing.radiusLg,
                            border: Border.all(
                              color: const Color(0xFFD1D5DB),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: GestureDetector(
                        onTap: _save,
                        child: Container(
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_kBlue600, _kTeal500],
                            ),
                            borderRadius: AppSpacing.radiusLg,
                          ),
                          child: Text(
                            'Save',
                            style: AppTypography.titleSmall.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.labelSmall),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: AppTypography.bodyMedium,
            validator: required
                ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
                : null,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.m,
              ),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: AppSpacing.radiusMd,
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppSpacing.radiusMd,
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppSpacing.radiusMd,
                borderSide: const BorderSide(color: _kBlue600, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Group {
  const _Group({required this.title, required this.items});
  final String title;
  final List<_GroupItem> items;
}

class _GroupItem {
  const _GroupItem({
    required this.icon,
    required this.label,
    required this.description,
    this.toggleValue,
    this.onToggle,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final String description;
  final bool? toggleValue;
  final VoidCallback? onToggle;
  final VoidCallback? onTap;
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.group});
  final _Group group;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.s,
              bottom: AppSpacing.m,
            ),
            child: Text(
              group.title.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppSpacing.radiusXl,
              border: Border.all(color: const Color(0xFFF3F4F6)),
              boxShadow: AppColors.cardShadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < group.items.length; i++) ...[
                  _SettingsTile(item: group.items[i]),
                  if (i < group.items.length - 1)
                    const Divider(height: 1, indent: AppSpacing.lg),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.item});
  final _GroupItem item;

  @override
  Widget build(BuildContext context) {
    final isToggle = item.toggleValue != null;

    return InkWell(
      onTap: isToggle ? item.onToggle : (item.onTap ?? () {}),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: AppSpacing.radiusMd,
              ),
              child: Icon(item.icon, color: _kBlue600, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label, style: AppTypography.titleSmall),
                  Text(
                    item.description,
                    style: AppTypography.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            if (isToggle)
              GestureDetector(
                onTap: item.onToggle,
                child: _Toggle(value: item.toggleValue!),
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9CA3AF),
                size: 20,
              ),
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
      duration: const Duration(milliseconds: 200),
      width: 48,
      height: 28,
      decoration: BoxDecoration(
        color: value ? _kBlue600 : const Color(0xFFD1D5DB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 200),
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
