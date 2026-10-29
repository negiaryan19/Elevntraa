import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure_text.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/repositories/patient_repository.dart';
import '../../../domain/models/patient.dart';
import '../../../l10n/app_localizations.dart';

/// Edit a patient's own details (name, age, gender, WhatsApp number) from the
/// patient's page (roadmap item 16).
///
/// These fields could only be changed from the review screen of a
/// consultation, so correcting a mistyped phone number meant starting a new
/// visit. The form takes the same fields, with the same limits, as intake.
/// It saves the patient row only: visits are never touched.
class EditPatientSheet extends ConsumerStatefulWidget {
  const EditPatientSheet({super.key, required this.patient});

  final PatientProfile patient;

  /// Returns the saved patient, or null when the doctor cancelled.
  static Future<PatientProfile?> show(
    BuildContext context,
    PatientProfile patient,
  ) {
    return showModalBottomSheet<PatientProfile>(
      context: context,
      isScrollControlled: true,
      // Root navigator so the barrier also covers the bottom navigation.
      useRootNavigator: true,
      showDragHandle: true,
      builder: (_) => EditPatientSheet(patient: patient),
    );
  }

  @override
  ConsumerState<EditPatientSheet> createState() => _EditPatientSheetState();
}

class _EditPatientSheetState extends ConsumerState<EditPatientSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.patient.name);
  late final _age = TextEditingController(
    text: widget.patient.age?.toString() ?? '',
  );
  late final _whatsapp = TextEditingController(
    text: widget.patient.whatsappNumber ?? '',
  );
  late Sex? _sex = widget.patient.sex;

  bool _saving = false;
  Object? _error;

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _whatsapp.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final whatsapp = _whatsapp.text.trim();
    final updated = widget.patient.copyWith(
      name: _name.text.trim(),
      age: int.tryParse(_age.text.trim()),
      sex: _sex,
      whatsappNumber: whatsapp.isEmpty ? null : whatsapp,
      updatedAt: DateTime.now(),
    );
    try {
      await ref.read(patientRepositoryProvider).upsert(updated);
      if (mounted) Navigator.of(context).pop(updated);
    } catch (e) {
      debugPrint('[patient] edit failed: $e');
      if (!mounted) return;
      // Stay open with what was typed: the doctor can simply try again.
      setState(() {
        _saving = false;
        _error = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final error = _error;
    return Padding(
      // Keep the form above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t.editPatientDetails,
                  style: AppTypography.titleMedium.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('edit_patient_name'),
                  controller: _name,
                  enabled: !_saving,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: t.patientName,
                    hintText: t.patientNameHint,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? t.nameRequired : null,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('edit_patient_age'),
                        controller: _age,
                        enabled: !_saving,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        decoration: InputDecoration(labelText: t.age),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: DropdownButtonFormField<Sex?>(
                        key: const Key('edit_patient_sex'),
                        initialValue: _sex,
                        isExpanded: true,
                        decoration: InputDecoration(labelText: t.gender),
                        items: [
                          const DropdownMenuItem<Sex?>(child: Text('—')),
                          DropdownMenuItem(
                            value: Sex.male,
                            child: Text(t.male),
                          ),
                          DropdownMenuItem(
                            value: Sex.female,
                            child: Text(t.female),
                          ),
                          DropdownMenuItem(
                            value: Sex.other,
                            child: Text(t.other),
                          ),
                        ],
                        onChanged: _saving
                            ? null
                            : (v) => setState(() => _sex = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('edit_patient_whatsapp'),
                  controller: _whatsapp,
                  enabled: !_saving,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    labelText: t.whatsappNumber,
                    hintText: t.mobileHint,
                    prefixText: '+91 ',
                  ),
                  onFieldSubmitted: (_) => _save(),
                ),
                if (error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '${t.couldNotSaveChanges}: ${failureText(t, error)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: scheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text(t.cancel),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: FilledButton(
                        key: const Key('edit_patient_save'),
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(error == null ? t.save : t.profileRetry),
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
