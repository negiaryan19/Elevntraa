import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_paths.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/repositories/patient_repository.dart';
import '../../../domain/models/patient.dart';
import '../../../domain/models/report_attachment.dart';
import '../../../l10n/app_localizations.dart';
import 'consultation_controller.dart';
import 'intake_controller.dart';

const _kBlue600 = Color(0xFF2563EB);
const _kBlue300 = Color(0xFF6B8FFF);
const _kTeal500 = Color(0xFF14B8A6);

class IntakeScreen extends ConsumerStatefulWidget {
  const IntakeScreen({super.key, this.patientId});

  /// When set, the form opens in "returning patient" mode: it prefills the
  /// saved details and the new visit attaches to this existing patient instead
  /// of creating a new record.
  final String? patientId;

  @override
  ConsumerState<IntakeScreen> createState() => _IntakeScreenState();
}

class _IntakeScreenState extends ConsumerState<IntakeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();

  Sex? _sex;
  bool _consent = false;
  bool _submitting = false;
  String? _error;

  /// The patient this consultation attaches to. Starts as the routed
  /// [widget.patientId] (returning patient) and can also get set if a duplicate
  /// phone number is matched for a "new" patient.
  String? _existingPatientId;
  bool _loadingPatient = false;

  /// Scanned/attached previous reports for this consultation.
  List<ReportAttachment> _attachments = [];

  bool get _isReturning => _existingPatientId != null;

  @override
  void initState() {
    super.initState();
    _existingPatientId = widget.patientId;
    if (widget.patientId != null) _prefill(widget.patientId!);
  }

  Future<void> _prefill(String patientId) async {
    setState(() => _loadingPatient = true);
    final patient = await ref.read(patientRepositoryProvider).byId(patientId);
    if (!mounted) return;
    setState(() {
      if (patient != null) {
        _nameCtrl.text = patient.name;
        _ageCtrl.text = patient.age?.toString() ?? '';
        _whatsappCtrl.text = patient.whatsappNumber ?? '';
        _sex = patient.sex;
      }
      _loadingPatient = false;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _whatsappCtrl.dispose();
    super.dispose();
  }

  // ── Previous-report attachments ─────────────────────────────────────────────

  Future<void> _addReport(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2000,
        imageQuality: 85,
      );
      if (picked == null) return;
      // Copy into persistent app storage so the report survives after the
      // picker's temp cache is cleared. We store only the relative file name
      // (resolved against the documents dir at read time) so a reinstall or
      // container-path change can't orphan it.
      final attachDir = Directory(AppPaths.attachmentsDir);
      if (!attachDir.existsSync()) attachDir.createSync(recursive: true);
      final ext = p.extension(picked.path).isEmpty
          ? '.jpg'
          : p.extension(picked.path);
      final fileName = '${const Uuid().v4()}$ext';
      await File(picked.path).copy(p.join(attachDir.path, fileName));
      if (!mounted) return;
      setState(
        () =>
            _attachments = [..._attachments, ReportAttachment(path: fileName)],
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.couldNotAddReport}: $e',
            ),
          ),
        );
      }
    }
  }

  Future<void> _pickReportSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: _kBlue600),
              title: Text(AppLocalizations.of(ctx)!.takePhoto),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: _kBlue600,
              ),
              title: Text(AppLocalizations.of(ctx)!.chooseFromGallery),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _addReport(source);
  }

  void _moveReport(int i, int delta) {
    final j = i + delta;
    if (j < 0 || j >= _attachments.length) return;
    final list = [..._attachments];
    final tmp = list[i];
    list[i] = list[j];
    list[j] = tmp;
    setState(() => _attachments = list);
  }

  void _removeReport(int i) {
    final removed = _attachments[i];
    setState(() => _attachments = [..._attachments]..removeAt(i));
    // Best-effort cleanup of the orphaned file.
    try {
      final f = File(AppPaths.resolveAttachment(removed.path));
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
  }

  /// Updates a caption without setState so the text field keeps focus/cursor.
  void _setCaption(int i, String caption) {
    if (i < 0 || i >= _attachments.length) return;
    _attachments[i] = _attachments[i].copyWith(caption: caption);
  }

  bool get _isFormValid =>
      _nameCtrl.text.trim().isNotEmpty &&
      _ageCtrl.text.trim().isNotEmpty &&
      _sex != null &&
      _whatsappCtrl.text.trim().length == 10 &&
      _consent &&
      !_submitting;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_consent) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final controller = ref.read(intakeControllerProvider);

      // For a brand-new patient, warn if the number already belongs to someone
      // in history and offer to use that existing record instead of duplicating.
      if (!_isReturning) {
        final existing = await controller.findByPhone(
          _whatsappCtrl.text.trim(),
        );
        if (existing != null && mounted) {
          final useExisting = await _confirmUseExisting(existing);
          if (useExisting == null) {
            // Dismissed — do nothing, let the doctor decide.
            setState(() => _submitting = false);
            return;
          }
          if (useExisting) {
            _existingPatientId = existing.id;
          }
        }
      }

      final result = await controller.submit(
        name: _nameCtrl.text,
        age: int.tryParse(_ageCtrl.text.trim()),
        sex: _sex,
        whatsappNumber: _whatsappCtrl.text,
        existingPatientId: _existingPatientId,
        attachments: _attachments,
      );
      if (!mounted) return;
      // Fresh consultation — clear any transcript left over from a previous
      // one so "Add More" appends only within this consultation.
      ref.read(cumulativeTranscriptProvider.notifier).state = '';
      // Push (not go) so the recording screen sits on top of intake and the
      // back gesture returns here instead of exiting the app.
      await context.push(
        AppRoute.recording.build(params: {'visitId': result.visitId}),
      );
      // Returned from recording (back / discard). Clear the submitting flag so
      // the form is usable again instead of showing a stuck spinner.
      if (mounted) setState(() => _submitting = false);
    } catch (e) {
      setState(() {
        _submitting = false;
        _error = '${AppLocalizations.of(context)!.couldNotSavePatient}: $e';
      });
    }
  }

  /// Returns true → reuse [existing]; false → create a new record anyway;
  /// null → the doctor dismissed the dialog.
  Future<bool?> _confirmUseExisting(PatientProfile existing) {
    final t = AppLocalizations.of(context)!;
    final meta = [
      if (existing.age != null) '${existing.age} ${t.years}',
      if (existing.whatsappNumber != null) '+91 ${existing.whatsappNumber}',
    ].join(' • ');
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.patientAlreadyExists),
        content: Text(
          '${t.patientExistsBody}\n\n'
          '${existing.name}${meta.isEmpty ? '' : '\n$meta'}\n\n'
          '${t.patientExistsQuestion}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.createNew),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.useExisting),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = AppLocalizations.of(context)!;
    return Scaffold(
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
          child: Form(
            key: _formKey,
            onChanged: () => setState(() {}),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.s,
                    AppSpacing.adaptive(context, AppSpacing.md),
                    AppSpacing.lg,
                    0,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () =>
                            context.canPop() ? context.pop() : context.go('/'),
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isReturning
                                  ? t.newConsultation
                                  : t.patientDetails,
                              style: AppTypography.headlineMedium.copyWith(
                                color: scheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _isReturning
                                  ? t.confirmDetailsConsent
                                  : t.enterBasicInfo,
                              style: AppTypography.bodySmall.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.adaptive(context, AppSpacing.lg)),
                // Progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: _StepProgressBar(activeStep: 0),
                ),
                SizedBox(height: AppSpacing.adaptive(context, AppSpacing.lg)),
                // Form card
                if (_loadingPatient)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: isDark
                              ? AppColors.cardShadowDark
                              : AppColors.cardShadow,
                          border: Border.all(color: scheme.outline),
                        ),
                        padding: EdgeInsets.all(
                          AppSpacing.adaptive(context, AppSpacing.xl),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name
                            _FieldLabel(
                              icon: Icons.person_outline_rounded,
                              label: t.patientName,
                            ),
                            const SizedBox(height: AppSpacing.s),
                            _IntakeTextField(
                              controller: _nameCtrl,
                              hint: t.patientNameHint,
                              textInputAction: TextInputAction.next,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? t.nameRequired
                                  : null,
                            ),
                            SizedBox(
                              height: AppSpacing.adaptive(
                                context,
                                AppSpacing.lg,
                              ),
                            ),
                            // Age + Gender
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _FieldLabel(
                                        icon: Icons.cake_outlined,
                                        label: t.age,
                                      ),
                                      const SizedBox(height: AppSpacing.s),
                                      _IntakeTextField(
                                        controller: _ageCtrl,
                                        hint: t.age,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          LengthLimitingTextInputFormatter(3),
                                        ],
                                        textInputAction: TextInputAction.next,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _FieldLabel(
                                        icon: Icons.people_outline_rounded,
                                        label: t.gender,
                                      ),
                                      const SizedBox(height: AppSpacing.s),
                                      _GenderDropdown(
                                        value: _sex == null
                                            ? null
                                            : _sex == Sex.male
                                            ? 'male'
                                            : _sex == Sex.female
                                            ? 'female'
                                            : 'other',
                                        onChanged: (v) => setState(() {
                                          if (v == 'male') {
                                            _sex = Sex.male;
                                          } else if (v == 'female') {
                                            _sex = Sex.female;
                                          } else if (v == 'other') {
                                            _sex = Sex.other;
                                          } else {
                                            _sex = null;
                                          }
                                        }),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: AppSpacing.adaptive(
                                context,
                                AppSpacing.lg,
                              ),
                            ),
                            // WhatsApp
                            _FieldLabel(
                              icon: Icons.phone_outlined,
                              label: t.whatsappNumber,
                            ),
                            const SizedBox(height: AppSpacing.s),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 52,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                  ),
                                  decoration: BoxDecoration(
                                    color: scheme.surfaceContainer,
                                    borderRadius: AppSpacing.radiusMd,
                                    border: Border.all(
                                      color: scheme.outline,
                                      width: 2,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '+91',
                                    style: AppTypography.titleSmall.copyWith(
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.s),
                                Expanded(
                                  child: _IntakeTextField(
                                    controller: _whatsappCtrl,
                                    hint: t.mobileHint,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(10),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              t.prescriptionShareNote,
                              style: AppTypography.bodySmall.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            SizedBox(
                              height: AppSpacing.adaptive(
                                context,
                                AppSpacing.lg,
                              ),
                            ),
                            // Previous reports
                            _FieldLabel(
                              icon: Icons.description_outlined,
                              label: t.previousReports,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              t.previousReportsDesc,
                              style: AppTypography.bodySmall.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.s),
                            for (var i = 0; i < _attachments.length; i++)
                              _ReportTile(
                                key: ValueKey(_attachments[i].path),
                                attachment: _attachments[i],
                                isFirst: i == 0,
                                isLast: i == _attachments.length - 1,
                                onCaption: (c) => _setCaption(i, c),
                                onUp: () => _moveReport(i, -1),
                                onDown: () => _moveReport(i, 1),
                                onDelete: () => _removeReport(i),
                              ),
                            const SizedBox(height: AppSpacing.s),
                            _AddReportButton(onTap: _pickReportSource),
                            SizedBox(
                              height: AppSpacing.adaptive(
                                context,
                                AppSpacing.lg,
                              ),
                            ),
                            // Consent
                            GestureDetector(
                              onTap: () => setState(() => _consent = !_consent),
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: _consent
                                          ? _kBlue600
                                          : Colors.transparent,
                                      borderRadius: AppSpacing.radiusSm,
                                      border: Border.all(
                                        color: _consent
                                            ? _kBlue600
                                            : scheme.outline,
                                        width: 2,
                                      ),
                                    ),
                                    child: _consent
                                        ? const Icon(
                                            Icons.check,
                                            size: 14,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: AppSpacing.s),
                                  Expanded(
                                    child: Text(
                                      t.consentLine,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: scheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: AppSpacing.adaptive(
                                context,
                                AppSpacing.xl,
                              ),
                            ),
                            if (_error != null) ...[
                              Text(
                                _error!,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                            // Submit button
                            _GradientCta(
                              label: t.continueToRecording,
                              trailingIcon: Icons.arrow_forward_rounded,
                              enabled: _isFormValid,
                              loading: _submitting,
                              onTap: _isFormValid ? _submit : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _StepProgressBar extends StatelessWidget {
  const _StepProgressBar({required this.activeStep});

  final int activeStep;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context)!;
    final steps = [t.stepDetails, t.stepRecording, t.stepReview, t.stepShare];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Container(
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
                    ? const Color(0xFF0D9488)
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 16, color: isDark ? _kBlue300 : _kBlue600),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            label,
            style: AppTypography.labelMedium.copyWith(color: scheme.onSurface),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _IntakeTextField extends StatelessWidget {
  const _IntakeTextField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabledBorder = OutlineInputBorder(
      borderRadius: AppSpacing.radiusMd,
      borderSide: BorderSide(color: scheme.outline, width: 2),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: AppSpacing.radiusMd,
      borderSide: const BorderSide(color: _kBlue600, width: 2),
    );
    final errorBorder = OutlineInputBorder(
      borderRadius: AppSpacing.radiusMd,
      borderSide: BorderSide(color: AppColors.error, width: 2),
    );
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      validator: validator,
      style: AppTypography.bodyMedium.copyWith(color: scheme.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        enabledBorder: enabledBorder,
        focusedBorder: focusedBorder,
        errorBorder: errorBorder,
        focusedErrorBorder: errorBorder,
        filled: false,
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({
    super.key,
    required this.attachment,
    required this.isFirst,
    required this.isLast,
    required this.onCaption,
    required this.onUp,
    required this.onDown,
    required this.onDelete,
  });

  final ReportAttachment attachment;
  final bool isFirst;
  final bool isLast;
  final ValueChanged<String> onCaption;
  final VoidCallback onUp;
  final VoidCallback onDown;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      padding: const EdgeInsets.all(AppSpacing.s),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: AppSpacing.radiusMd,
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: AppSpacing.radiusSm,
            child: Image.file(
              File(AppPaths.resolveAttachment(attachment.path)),
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 52,
                height: 52,
                color: scheme.surfaceContainerHigh,
                child: Icon(
                  Icons.broken_image_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: TextFormField(
              initialValue: attachment.caption,
              style: AppTypography.bodySmall.copyWith(color: scheme.onSurface),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.reportLabelHint,
                isDense: true,
                border: InputBorder.none,
              ),
              onChanged: onCaption,
            ),
          ),
          // Reorder
          Column(
            children: [
              _IconBtn(
                icon: Icons.keyboard_arrow_up_rounded,
                onTap: isFirst ? null : onUp,
              ),
              _IconBtn(
                icon: Icons.keyboard_arrow_down_rounded,
                onTap: isLast ? null : onDown,
              ),
            ],
          ),
          _IconBtn(
            icon: Icons.delete_outline_rounded,
            color: scheme.error,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, this.color, required this.onTap});
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final disabled = onTap == null;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(
          icon,
          size: 20,
          color: disabled
              ? scheme.outlineVariant
              : (color ?? scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _AddReportButton extends StatelessWidget {
  const _AddReportButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final blue = isDark ? _kBlue300 : _kBlue600;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: AppSpacing.radiusMd,
          border: Border.all(
            color: scheme.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_rounded, color: blue, size: 20),
            const SizedBox(width: AppSpacing.s),
            Text(
              AppLocalizations.of(context)!.addReport,
              style: AppTypography.titleSmall.copyWith(color: blue),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenderDropdown extends StatelessWidget {
  const _GenderDropdown({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context)!;
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      dropdownColor: scheme.surface,
      style: AppTypography.bodyMedium.copyWith(color: scheme.onSurface),
      decoration: InputDecoration(
        hintText: t.select,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.radiusMd,
          borderSide: BorderSide(color: scheme.outline, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.radiusMd,
          borderSide: const BorderSide(color: _kBlue600, width: 2),
        ),
        filled: false,
      ),
      items: [
        DropdownMenuItem(value: 'male', child: Text(t.male)),
        DropdownMenuItem(value: 'female', child: Text(t.female)),
        DropdownMenuItem(value: 'other', child: Text(t.other)),
      ],
    );
  }
}

class _GradientCta extends StatelessWidget {
  const _GradientCta({
    required this.label,
    this.trailingIcon,
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final IconData? trailingIcon;
  final bool enabled;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [_kBlue600, _kTeal500],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: enabled ? null : scheme.surfaceContainerHigh,
          borderRadius: AppSpacing.radiusMd,
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: _kBlue600.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        style: AppTypography.titleSmall.copyWith(
                          color: enabled
                              ? Colors.white
                              : scheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: AppSpacing.s),
                      Icon(
                        trailingIcon,
                        size: 20,
                        color: enabled ? Colors.white : scheme.onSurfaceVariant,
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
