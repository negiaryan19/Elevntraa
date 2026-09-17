import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/doctor_profile.dart';
import '../../../l10n/app_localizations.dart';
import '../data/doctor_profile_repository.dart';
import 'signature_capture_sheet.dart';
import 'signature_preview.dart';

const _kBlue600 = Color(0xFF2563EB);
const _kTeal500 = Color(0xFF14B8A6);

/// Localized name of a profile field, for "still missing" lists (sign gate,
/// onboarding) so the doctor sees the same label as on the form.
String doctorProfileFieldLabel(AppLocalizations t, DoctorProfileField field) {
  return switch (field) {
    DoctorProfileField.name => t.doctorName,
    DoctorProfileField.qualifications => t.qualifications,
    DoctorProfileField.regNo => t.registrationNumber,
    DoctorProfileField.clinicName => t.clinicName,
    DoctorProfileField.clinicAddress => t.clinicAddress,
    DoctorProfileField.phone => t.profilePhone,
    DoctorProfileField.signature => t.signatureTitle,
  };
}

/// Which group of text fields to render.
enum DoctorProfileSection { doctor, clinic }

/// How [DoctorProfileForm] is hosted.
enum DoctorProfileFormMode {
  /// Inside [DoctorProfileFormSheet]: drag handle, Cancel + Save, unsaved
  /// changes guard on dismiss.
  sheet,

  /// A full-screen page: no handle, single Save button, no pop guard.
  fullScreen,
}

/// Text controllers for every editable profile field. Shared by the settings
/// sheet and the onboarding steps so validation and trimming live in one
/// place. Call [dispose] when done.
class DoctorProfileFormController {
  DoctorProfileFormController(DoctorProfile initial) : _initial = initial {
    name = TextEditingController(text: initial.name);
    qualifications = TextEditingController(text: initial.qualifications);
    regNo = TextEditingController(text: initial.regNo);
    phone = TextEditingController(text: initial.phone);
    clinicName = TextEditingController(text: initial.clinicName);
    clinicAddress = TextEditingController(text: initial.clinicAddress);
    clinicPhone = TextEditingController(text: initial.clinicPhone);
    _listenable = Listenable.merge(all);
  }

  DoctorProfile _initial;
  late final TextEditingController name;
  late final TextEditingController qualifications;
  late final TextEditingController regNo;
  late final TextEditingController phone;
  late final TextEditingController clinicName;
  late final TextEditingController clinicAddress;
  late final TextEditingController clinicPhone;
  late final Listenable _listenable;

  List<TextEditingController> get all => [
    name,
    qualifications,
    regNo,
    phone,
    clinicName,
    clinicAddress,
    clinicPhone,
  ];

  /// Fires on any keystroke in any field.
  Listenable get listenable => _listenable;

  /// The text fields as a profile. Signature and timestamps are NOT carried
  /// here; [DoctorProfileController.save] merges them from the stored
  /// profile.
  DoctorProfile toDraft() => DoctorProfile(
    name: name.text.trim(),
    qualifications: qualifications.text.trim(),
    regNo: regNo.text.trim(),
    phone: phone.text.trim(),
    clinicName: clinicName.text.trim(),
    clinicAddress: clinicAddress.text.trim(),
    clinicPhone: clinicPhone.text.trim(),
  );

  bool get isDirty {
    final d = toDraft();
    final p = _initial;
    return d.name != p.name.trim() ||
        d.qualifications != p.qualifications.trim() ||
        d.regNo != p.regNo.trim() ||
        d.phone != p.phone.trim() ||
        d.clinicName != p.clinicName.trim() ||
        d.clinicAddress != p.clinicAddress.trim() ||
        d.clinicPhone != p.clinicPhone.trim();
  }

  /// Treat the current text as the saved baseline (after a successful save).
  void markSaved() => _initial = toDraft();

  void dispose() {
    for (final c in all) {
      c.dispose();
    }
  }
}

/// Saves [draft] through [doctorProfileProvider] and tells the doctor what
/// happened on [messenger]: "Profile updated", "Saved on this device — will
/// sync when online", or an error with a Retry action (which calls
/// [onRetry]). Returns null when the profile could not be stored even
/// locally.
Future<ProfileSaveResult?> saveDoctorProfileWithFeedback({
  required WidgetRef ref,
  required ScaffoldMessengerState messenger,
  required AppLocalizations t,
  required DoctorProfile draft,
  VoidCallback? onRetry,
  bool announceSuccess = true,
}) async {
  try {
    final result = await ref.read(doctorProfileProvider.notifier).save(draft);
    if (announceSuccess) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              result.synced ? t.profileUpdated : t.profileSavedOffline,
            ),
          ),
        );
    }
    return result;
  } catch (e) {
    final detail = e is Failure ? e.message : e.toString();
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('${t.profileSaveFailed}: $detail'),
          duration: const Duration(seconds: 6),
          action: onRetry == null
              ? null
              : SnackBarAction(label: t.profileRetry, onPressed: onRetry),
        ),
      );
    return null;
  }
}

// ── Fields ────────────────────────────────────────────────────────────────────

/// The text inputs of one [DoctorProfileSection]. Must sit inside a [Form]
/// — validation mirrors [DoctorProfile.missingFields] (everything required
/// except the clinic phone).
class DoctorProfileFields extends StatelessWidget {
  const DoctorProfileFields({
    super.key,
    required this.controller,
    required this.section,
    this.autofocus = false,
  });

  final DoctorProfileFormController controller;
  final DoctorProfileSection section;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return switch (section) {
      DoctorProfileSection.doctor => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Field(
            label: t.doctorName,
            controller: controller.name,
            hint: t.profileNameHint,
            required: true,
            autofocus: autofocus,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
          ),
          _Field(
            label: t.qualifications,
            controller: controller.qualifications,
            hint: t.profileQualificationsHint,
            required: true,
            textCapitalization: TextCapitalization.characters,
          ),
          _Field(
            label: t.registrationNumber,
            controller: controller.regNo,
            hint: t.profileRegNoHint,
            required: true,
            textCapitalization: TextCapitalization.characters,
          ),
          _Field(
            label: t.profilePhone,
            controller: controller.phone,
            hint: t.profilePhoneHint,
            required: true,
            keyboardType: TextInputType.phone,
            validator: (v) => _phoneValidator(t, v, required: true),
          ),
        ],
      ),
      DoctorProfileSection.clinic => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Field(
            label: t.clinicName,
            controller: controller.clinicName,
            hint: t.profileClinicNameHint,
            required: true,
            autofocus: autofocus,
            textCapitalization: TextCapitalization.words,
          ),
          _Field(
            label: t.clinicAddress,
            controller: controller.clinicAddress,
            hint: t.profileClinicAddressHint,
            required: true,
            maxLines: 2,
            keyboardType: TextInputType.streetAddress,
            textCapitalization: TextCapitalization.words,
          ),
          _Field(
            label: '${t.clinicPhone} (${t.profileOptional})',
            controller: controller.clinicPhone,
            hint: t.profileClinicPhoneHint,
            keyboardType: TextInputType.phone,
            validator: (v) => _phoneValidator(t, v, required: false),
          ),
        ],
      ),
    };
  }

  static String? _phoneValidator(
    AppLocalizations t,
    String? v, {
    required bool required,
  }) {
    final text = (v ?? '').trim();
    if (text.isEmpty) return required ? t.required : null;
    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10 || digits.length > 15) return t.profilePhoneInvalid;
    return null;
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
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final bool required;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool autofocus;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: AppTypography.labelSmall.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              children: [
                if (required)
                  TextSpan(
                    text: ' *',
                    style: AppTypography.labelSmall.copyWith(
                      color: scheme.error,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            autofocus: autofocus,
            textInputAction: maxLines > 1
                ? TextInputAction.newline
                : TextInputAction.next,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: AppTypography.bodyMedium.copyWith(color: scheme.onSurface),
            validator:
                validator ??
                (required
                    ? (v) => (v == null || v.trim().isEmpty) ? t.required : null
                    : null),
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
    );
  }
}

/// Section title used above each field group.
class DoctorProfileSectionHeader extends StatelessWidget {
  const DoctorProfileSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_kBlue600, _kTeal500]),
              borderRadius: AppSpacing.radiusSm,
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AppTypography.bodySmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Signature section ────────────────────────────────────────────────────────

/// Current signature preview plus an "Add / Update signature" button that
/// opens [SignatureCaptureSheet] and persists the result through
/// [DoctorProfileController.saveSignature]. Reports the outcome on the
/// nearest [ScaffoldMessenger].
class DoctorSignatureSection extends ConsumerStatefulWidget {
  const DoctorSignatureSection({
    super.key,
    this.showHeader = true,
    this.previewHeight = 120,
    this.onSaved,
    this.announceSuccess = true,
  });

  final bool showHeader;
  final double previewHeight;
  final ValueChanged<ProfileSaveResult>? onSaved;

  /// Show a snackbar after a successful save. Turned off where the preview
  /// already makes the result obvious and the snackbar would cover the
  /// screen's primary button (onboarding's Finish); failures always show.
  final bool announceSuccess;

  @override
  ConsumerState<DoctorSignatureSection> createState() =>
      _DoctorSignatureSectionState();
}

class _DoctorSignatureSectionState
    extends ConsumerState<DoctorSignatureSection> {
  bool _busy = false;

  Future<void> _capture() async {
    if (_busy) return;
    final png = await SignatureCaptureSheet.show(context);
    if (png == null || !mounted) return;
    await _persist(png);
  }

  Future<void> _persist(Uint8List png) async {
    if (!mounted) return;
    setState(() => _busy = true);
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await ref
          .read(doctorProfileProvider.notifier)
          .saveSignature(png);
      if (!mounted) return;
      // A profile that could not reach the server is always worth saying;
      // a clean save is only announced where it will not cover a button.
      if (widget.announceSuccess || !result.synced) {
        messenger
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(
                result.synced ? t.signatureSaved : t.profileSavedOffline,
              ),
            ),
          );
      }
      widget.onSaved?.call(result);
    } catch (e) {
      final detail = e is Failure ? e.message : e.toString();
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('${t.signatureSaveFailed}: $detail'),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: t.profileRetry,
              onPressed: () => _persist(png),
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final hasSignature = ref.watch(
      doctorProfileValueProvider.select((p) => p.hasSignature),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showHeader)
          DoctorProfileSectionHeader(
            icon: Icons.draw_rounded,
            title: t.signatureTitle,
            subtitle: t.signatureSubtitle,
          ),
        SignaturePreview(height: widget.previewHeight),
        const SizedBox(height: AppSpacing.s),
        OutlinedButton.icon(
          onPressed: _busy ? null : _capture,
          icon: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(hasSignature ? Icons.edit_rounded : Icons.add_rounded),
          label: Text(hasSignature ? t.signatureUpdate : t.signatureAdd),
        ),
      ],
    );
  }
}

// ── Full form ────────────────────────────────────────────────────────────────

/// Complete profile editor: doctor details, clinic details, signature, and a
/// Save button. Used by [DoctorProfileFormSheet]; can also be embedded in a
/// page with [DoctorProfileFormMode.fullScreen].
class DoctorProfileForm extends ConsumerStatefulWidget {
  const DoctorProfileForm({
    super.key,
    this.mode = DoctorProfileFormMode.sheet,
    this.initial,
    this.onSaved,
    this.onCancel,
    this.announceSuccess = true,
  });

  final DoctorProfileFormMode mode;

  /// Starting values; defaults to the stored profile.
  final DoctorProfile? initial;

  /// Called after the text fields were stored on the device.
  final ValueChanged<ProfileSaveResult>? onSaved;

  /// Cancel button / dismissed without saving (sheet mode).
  final VoidCallback? onCancel;

  /// Whether to show the "Profile updated" SnackBar here. A sheet that closes
  /// itself on save should pass false and let the caller announce it.
  final bool announceSuccess;

  @override
  ConsumerState<DoctorProfileForm> createState() => _DoctorProfileFormState();
}

class _DoctorProfileFormState extends ConsumerState<DoctorProfileForm> {
  late final DoctorProfileFormController _form;
  final _formKey = GlobalKey<FormState>();
  bool _dirty = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _form = DoctorProfileFormController(
      widget.initial ?? ref.read(doctorProfileValueProvider),
    );
    _form.listenable.addListener(_onChanged);
  }

  void _onChanged() {
    final dirty = _form.isDirty;
    if (dirty != _dirty) setState(() => _dirty = dirty);
  }

  @override
  void dispose() {
    _form.listenable.removeListener(_onChanged);
    _form.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final result = await saveDoctorProfileWithFeedback(
      ref: ref,
      messenger: ScaffoldMessenger.of(context),
      t: AppLocalizations.of(context)!,
      draft: _form.toDraft(),
      onRetry: _save,
      announceSuccess: widget.announceSuccess,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result == null) return;
    _form.markSaved();
    setState(() => _dirty = false);
    widget.onSaved?.call(result);
  }

  /// Shown when the sheet is dismissed with unsaved edits. Returns true when
  /// the sheet may close without saving.
  Future<bool> _confirmDiscard() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(dialogContext)!.unsavedChanges),
        content: Text(AppLocalizations.of(dialogContext)!.unsavedChangesBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(AppLocalizations.of(dialogContext)!.discard),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(AppLocalizations.of(dialogContext)!.save),
          ),
        ],
      ),
    );
    if (result == true) return true;
    if (result == false) await _save();
    // Either saved (onSaved closes the sheet) or the dialog was cancelled.
    return false;
  }

  void _cancel() {
    final onCancel = widget.onCancel;
    if (onCancel != null) {
      onCancel();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context)!;
    final isSheet = widget.mode == DoctorProfileFormMode.sheet;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isSheet) ...[
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(
                top: AppSpacing.md,
                bottom: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.editProfile,
                  style: AppTypography.headlineMedium.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  t.editProfileSubtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t.profileRequiredHint,
                    style: AppTypography.bodySmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  DoctorProfileSectionHeader(
                    icon: Icons.badge_rounded,
                    title: t.profileSectionDoctor,
                  ),
                  DoctorProfileFields(
                    controller: _form,
                    section: DoctorProfileSection.doctor,
                  ),
                  const SizedBox(height: AppSpacing.s),
                  DoctorProfileSectionHeader(
                    icon: Icons.local_hospital_rounded,
                    title: t.profileSectionClinic,
                  ),
                  DoctorProfileFields(
                    controller: _form,
                    section: DoctorProfileSection.clinic,
                  ),
                  const SizedBox(height: AppSpacing.s),
                  const DoctorSignatureSection(),
                ],
              ),
            ),
          ),
        ),
        _Actions(
          saving: _saving,
          showCancel: isSheet,
          onCancel: _cancel,
          onSave: _save,
        ),
      ],
    );

    if (!isSheet) return body;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final discard = await _confirmDiscard();
        if (discard && context.mounted) Navigator.of(context).pop();
      },
      child: body,
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.saving,
    required this.showCancel,
    required this.onCancel,
    required this.onSave,
  });

  final bool saving;
  final bool showCancel;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.m,
        AppSpacing.lg,
        AppSpacing.m,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (showCancel) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: saving ? null : onCancel,
                  child: Text(t.cancel),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: ElevatedButton(
                onPressed: saving ? null : onSave,
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(t.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sheet ────────────────────────────────────────────────────────────────────

/// The profile editor as a modal bottom sheet (Settings > Profile, the home
/// nudge card, the sign gate).
class DoctorProfileFormSheet extends StatelessWidget {
  const DoctorProfileFormSheet({super.key});

  /// Opens the editor; resolves true when the profile was saved.
  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<ProfileSaveResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Root navigator so the barrier covers the whole screen (including
      // the bottom nav); otherwise tabs stay tappable behind the sheet and
      // bypass the unsaved-changes guard.
      useRootNavigator: true,
      builder: (_) => const DoctorProfileFormSheet(),
    );
    if (result == null) return false;
    if (context.mounted) {
      final t = AppLocalizations.of(context)!;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            result.synced ? t.profileUpdated : t.profileSavedOffline,
          ),
        ),
      );
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final height = MediaQuery.sizeOf(context).height * 0.92;
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        // Own messenger + scaffold so SnackBars (errors, Retry) appear inside
        // the sheet instead of underneath its barrier, and the keyboard inset
        // is handled by the scaffold.
        child: ScaffoldMessenger(
          child: Scaffold(
            backgroundColor: scheme.surface,
            body: Builder(
              builder: (innerContext) => DoctorProfileForm(
                mode: DoctorProfileFormMode.sheet,
                announceSuccess: false,
                onSaved: (result) =>
                    Navigator.of(innerContext, rootNavigator: true).pop(result),
                onCancel: () =>
                    Navigator.of(innerContext, rootNavigator: true).maybePop(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
