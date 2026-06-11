import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/patient.dart';
import 'intake_controller.dart';

const _kBlue600 = Color(0xFF2563EB);
const _kTeal500 = Color(0xFF14B8A6);

class IntakeScreen extends ConsumerStatefulWidget {
  const IntakeScreen({super.key});

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

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _whatsappCtrl.dispose();
    super.dispose();
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
      final result = await ref.read(intakeControllerProvider).submit(
            name: _nameCtrl.text,
            age: int.tryParse(_ageCtrl.text.trim()),
            sex: _sex,
            whatsappNumber: _whatsappCtrl.text,
          );
      if (!mounted) return;
      context.go(AppRoute.recording.build(params: {'visitId': result.visitId}));
    } catch (e) {
      setState(() {
        _submitting = false;
        _error = 'Could not save patient: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
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
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s,
                    AppSpacing.md,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.canPop()
                            ? context.pop()
                            : context.go('/'),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Patient Details',
                              style: AppTypography.headlineMedium),
                          Text('Enter basic patient information',
                              style: AppTypography.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: _StepProgressBar(activeStep: 0),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Form card
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFFF3F4F6)),
                      ),
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name
                          _FieldLabel(
                            icon: Icons.person_outline_rounded,
                            label: 'Patient Name',
                          ),
                          const SizedBox(height: AppSpacing.s),
                          _IntakeTextField(
                            controller: _nameCtrl,
                            hint: "Enter patient's full name",
                            textInputAction: TextInputAction.next,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Name is required'
                                    : null,
                          ),
                          const SizedBox(height: AppSpacing.lg),
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
                                      label: 'Age',
                                    ),
                                    const SizedBox(height: AppSpacing.s),
                                    _IntakeTextField(
                                      controller: _ageCtrl,
                                      hint: 'Age',
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
                                      label: 'Gender',
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
                          const SizedBox(height: AppSpacing.lg),
                          // WhatsApp
                          _FieldLabel(
                            icon: Icons.phone_outlined,
                            label: 'WhatsApp Number',
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
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: AppSpacing.radiusMd,
                                  border: Border.all(
                                    color: const Color(0xFFD1D5DB),
                                    width: 2,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text('+91',
                                    style: AppTypography.titleSmall),
                              ),
                              const SizedBox(width: AppSpacing.s),
                              Expanded(
                                child: _IntakeTextField(
                                  controller: _whatsappCtrl,
                                  hint: '10-digit mobile number',
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
                            'Prescription will be shared on this number',
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.textMuted),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          // Consent
                          GestureDetector(
                            onTap: () =>
                                setState(() => _consent = !_consent),
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 150),
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
                                          : const Color(0xFFD1D5DB),
                                      width: 2,
                                    ),
                                  ),
                                  child: _consent
                                      ? const Icon(Icons.check,
                                          size: 14, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: AppSpacing.s),
                                Expanded(
                                  child: Text(
                                    'Patient has consented to be recorded (DPDP Act)',
                                    style: AppTypography.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          if (_error != null) ...[
                            Text(
                              _error!,
                              style: AppTypography.bodySmall
                                  .copyWith(color: AppColors.error),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          // Submit button
                          _GradientCta(
                            label: 'Continue to Recording',
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
                        ? const LinearGradient(
                            colors: [_kBlue600, _kTeal500])
                        : null,
                    color: i <= activeStep ? null : const Color(0xFFE5E7EB),
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
                    ? _kBlue600
                    : i < activeStep
                        ? const Color(0xFF0D9488)
                        : const Color(0xFF9CA3AF),
                fontWeight: i == activeStep
                    ? FontWeight.w600
                    : FontWeight.w400,
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
    return Row(
      children: [
        Icon(icon, size: 16, color: _kBlue600),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.labelMedium
              .copyWith(color: const Color(0xFF374151)),
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

  static final _enabledBorder = OutlineInputBorder(
    borderRadius: AppSpacing.radiusMd,
    borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 2),
  );
  static final _focusedBorder = OutlineInputBorder(
    borderRadius: AppSpacing.radiusMd,
    borderSide: const BorderSide(color: _kBlue600, width: 2),
  );
  static final _errorBorder = OutlineInputBorder(
    borderRadius: AppSpacing.radiusMd,
    borderSide: BorderSide(color: AppColors.error, width: 2),
  );

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      validator: validator,
      style: AppTypography.bodyMedium,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        enabledBorder: _enabledBorder,
        focusedBorder: _focusedBorder,
        errorBorder: _errorBorder,
        focusedErrorBorder: _errorBorder,
        filled: false,
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
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      style: AppTypography.bodyMedium,
      decoration: InputDecoration(
        hintText: 'Select',
        hintStyle:
            AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.radiusMd,
          borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.radiusMd,
          borderSide: const BorderSide(color: _kBlue600, width: 2),
        ),
        filled: false,
      ),
      items: const [
        DropdownMenuItem(value: 'male', child: Text('Male')),
        DropdownMenuItem(value: 'female', child: Text('Female')),
        DropdownMenuItem(value: 'other', child: Text('Other')),
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
          color: enabled ? null : const Color(0xFFE5E7EB),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: AppTypography.titleSmall.copyWith(
                        color: enabled
                            ? Colors.white
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: AppSpacing.s),
                      Icon(
                        trailingIcon,
                        size: 20,
                        color: enabled
                            ? Colors.white
                            : const Color(0xFF9CA3AF),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
