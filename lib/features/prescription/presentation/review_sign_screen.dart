import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/repositories/patient_repository.dart';
import '../../../data/repositories/visit_repository.dart';
import '../../../domain/models/medical_insight.dart';
import '../../../domain/models/medication.dart';
import '../../../domain/models/patient.dart';
import '../../../domain/models/visit.dart';

const _kBlue600 = Color(0xFF2563EB);
const _kBlue300 = Color(0xFF6B8FFF);
const _kTeal500 = Color(0xFF14B8A6);
const _kTeal600 = Color(0xFF0D9488);
const _kBlueShadow = Color(0x4D2563EB);

/// Accent blue that stays legible in both themes.
Color _accent(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? _kBlue300 : _kBlue600;

class ReviewSignScreen extends ConsumerStatefulWidget {
  const ReviewSignScreen({super.key, required this.visitId});

  final String visitId;

  @override
  ConsumerState<ReviewSignScreen> createState() => _ReviewSignScreenState();
}

class _ReviewSignScreenState extends ConsumerState<ReviewSignScreen> {
  VisitRecord? _visit;
  PatientProfile? _patient;
  MedicalInsight _draft = MedicalInsight.empty;
  bool _loading = true;
  bool _saving = false;
  int? _autofocusMedIndex;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final visits = ref.read(visitRepositoryProvider);
    final patients = ref.read(patientRepositoryProvider);
    final v = await visits.byId(widget.visitId);
    final p = v == null ? null : await patients.byId(v.patientId);
    setState(() {
      _visit = v;
      _patient = p;
      _draft = v?.insight ?? MedicalInsight.empty;
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_visit == null) return;
    setState(() => _saving = true);
    final updated = _visit!.copyWith(insight: _draft);
    await ref.read(visitRepositoryProvider).upsert(updated);
    if (!mounted) return;
    setState(() {
      _visit = updated;
      _saving = false;
    });
  }

  Future<void> _savePatient(PatientProfile updated) async {
    setState(() => _patient = updated);
    await ref
        .read(patientRepositoryProvider)
        .upsert(updated.copyWith(updatedAt: DateTime.now()));
  }

  // ── Medicine helpers ───────────────────────────────────────────────────────

  void _setMedicationsSilently(List<Medication> meds) {
    // Update the draft without a rebuild — the field controllers already hold
    // the text, so we avoid resetting cursors on every keystroke and only
    // persist when the field loses focus.
    _draft = _draft.copyWith(medications: meds);
  }

  void _replaceMedicine(int i, Medication m) {
    final next = [..._draft.medications]..[i] = m;
    _setMedicationsSilently(next);
  }

  void _commitMedicine(int i, Medication m) {
    final next = [..._draft.medications]..[i] = m;
    setState(() => _draft = _draft.copyWith(medications: next));
    _save();
  }

  void _deleteMedicine(int i) {
    final next = [..._draft.medications]..removeAt(i);
    setState(() => _draft = _draft.copyWith(medications: next));
    _save();
  }

  void _addMedicine() {
    setState(() {
      _draft = _draft.copyWith(
        medications: [
          ..._draft.medications,
          const Medication(name: ''),
        ],
      );
      _autofocusMedIndex = _draft.medications.length - 1;
    });
    _save();
  }

  Future<void> _sign() async {
    if (_visit == null) return;
    await _save();
    final signed = _visit!.copyWith(signed: true, signedAt: DateTime.now());
    await ref.read(visitRepositoryProvider).upsert(signed);
    if (!mounted) return;
    setState(() => _visit = signed);
    context.go(AppRoute.pdf.build(params: {'visitId': widget.visitId}));
  }

  Future<void> _share() async {
    if (_visit == null || _patient == null) return;
    final number = (_patient!.whatsappNumber ?? '').replaceAll(
      RegExp(r'\D'),
      '',
    );
    final lines = [
      'Prescription for ${_patient!.name}',
      if (_draft.diagnosis.isNotEmpty) 'Diagnosis: ${_draft.diagnosis}',
      if (_draft.medications.isNotEmpty) ...[
        'Medications:',
        ..._draft.medications.map(
          (m) =>
              '• ${[m.name, m.dosage, m.frequency, m.duration, m.timing].where((s) => s.trim().isNotEmpty).join(' · ')}',
        ),
      ],
    ];
    final encoded = Uri.encodeComponent(lines.join('\n'));
    final url = number.isEmpty
        ? 'https://wa.me/?text=$encoded'
        : 'https://wa.me/$number?text=$encoded';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_visit == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Review')),
        body: const EmptyState(
          title: 'Visit not found',
          icon: Icons.search_off_rounded,
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final signed = _visit!.signed;
    final gap = AppSpacing.adaptive(context, AppSpacing.md);

    return Scaffold(
      backgroundColor: Colors.transparent,
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
          child: Column(
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
                            'Review Prescription',
                            style: AppTypography.headlineMedium.copyWith(
                              color: scheme.onSurface,
                            ),
                          ),
                          Text(
                            'Verify and edit transcribed details',
                            style: AppTypography.bodySmall.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_saving)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.adaptive(context, AppSpacing.lg)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _StepProgressBar(activeStep: 2),
              ),
              SizedBox(height: gap),
              // Scrolling content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  children: [
                    _SummaryCard(
                      summary: _draft.consultationSummary,
                      onSave: (v) {
                        setState(
                          () =>
                              _draft = _draft.copyWith(consultationSummary: v),
                        );
                        _save();
                      },
                    ),
                    SizedBox(height: gap),
                    if (_patient != null) ...[
                      _PatientCard(patient: _patient!, onSave: _savePatient),
                      SizedBox(height: gap),
                    ],
                    _DiagnosisCard(
                      diagnosis: _draft.diagnosis,
                      icdCode: _draft.icdCode,
                      icdDescription: _draft.icdDescription,
                      icdConfidence: _draft.icdConfidence,
                      onSaveDiagnosis: (v) {
                        setState(() => _draft = _draft.copyWith(diagnosis: v));
                        _save();
                      },
                      onRemoveIcd: () {
                        setState(
                          () => _draft = _draft.copyWith(
                            icdCode: null,
                            icdDescription: null,
                            icdConfidence: null,
                          ),
                        );
                        _save();
                      },
                      onEditIcd: (newCode, newDesc) {
                        setState(
                          () => _draft = _draft.copyWith(
                            icdCode: newCode,
                            icdDescription: newDesc,
                            icdConfidence: null,
                          ),
                        );
                        _save();
                      },
                    ),
                    SizedBox(height: gap),
                    _medicinesCard(),
                    SizedBox(height: gap),
                    _EditableBullets(
                      title: 'Advice',
                      icon: Icons.tips_and_updates_rounded,
                      items: _draft.advice,
                      placeholder: 'No advice yet — tap ✏️ to add',
                      hint:
                          'General guidance — one per line\n'
                          'e.g. Take adequate rest\nAvoid oily food',
                      onSave: (v) {
                        setState(() => _draft = _draft.copyWith(advice: v));
                        _save();
                      },
                    ),
                    SizedBox(height: gap),
                    _EditableBullets(
                      title: 'Instructions',
                      icon: Icons.checklist_rounded,
                      items: _draft.instructions,
                      placeholder: 'No instructions yet — tap ✏️ to add',
                      hint:
                          'Clinical directives — one per line\n'
                          'e.g. Take medication after meals\n'
                          'Review after 3 days if symptoms persist',
                      onSave: (v) {
                        setState(
                          () => _draft = _draft.copyWith(instructions: v),
                        );
                        _save();
                      },
                    ),
                    SizedBox(height: gap),
                    _FollowUpCard(
                      days: _draft.followUpDays,
                      onChanged: (d) {
                        setState(
                          () => _draft = _draft.copyWith(followUpDays: d),
                        );
                        _save();
                      },
                    ),
                  ],
                ),
              ),
              // Sticky bottom bar
              _BottomBar(
                signed: signed,
                showShare: !signed && _patient?.whatsappNumber != null,
                onSign: _sign,
                onShare: _share,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section builders ────────────────────────────────────────────────────────

  Widget _medicinesCard() {
    final scheme = Theme.of(context).colorScheme;
    return _InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medication_rounded, color: _accent(context), size: 20),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Prescribed Medicines',
                style: AppTypography.titleMedium.copyWith(
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (_draft.medications.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s),
              child: Text(
                'No medications recorded yet.',
                style: AppTypography.bodySmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          for (var i = 0; i < _draft.medications.length; i++) ...[
            _MedicineRow(
              med: _draft.medications[i],
              autofocus: i == _autofocusMedIndex,
              onChanged: (m) => _replaceMedicine(i, m),
              onCommit: (m) => _commitMedicine(i, m),
              onDelete: () => _deleteMedicine(i),
            ),
            const SizedBox(height: AppSpacing.s),
          ],
          _OutlineButton(
            label: 'Add Medicine',
            icon: Icons.add_rounded,
            onTap: _addMedicine,
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _StepProgressBar extends StatelessWidget {
  const _StepProgressBar({required this.activeStep});

  final int activeStep;
  static const _steps = ['Details', 'Recording', 'Review', 'Share'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
            _steps.length,
            (i) => Text(
              _steps[i],
              style: AppTypography.labelSmall.copyWith(
                color: i == activeStep
                    ? _kTeal600
                    : i < activeStep
                    ? _kTeal600
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

/// Card surface used by most sections. 16px internal padding for consistency.
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppSpacing.radiusXl,
        border: Border.all(color: scheme.outline),
        boxShadow: isDark ? AppColors.cardShadowDark : AppColors.cardShadow,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: child,
    );
  }
}

/// A small grey label above an (editable) value.
class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        child,
      ],
    );
  }
}

/// Pencil-triggered inline editor. Display mode shows plain text (not tappable).
/// Edit mode is entered externally via [GlobalKey<_InlineEditableState>].
/// Tapping ✓ saves; ✗ reverts; tapping outside saves.
class _InlineEditable extends StatefulWidget {
  const _InlineEditable({
    super.key,
    required this.value,
    required this.onSave,
    this.style,
    this.placeholder = 'Tap pencil to add',
    this.maxLines = 1,
    this.hint = '',
  });

  final String value;
  final ValueChanged<String> onSave;
  final TextStyle? style;
  final String placeholder;
  final int maxLines;
  final String hint;

  @override
  State<_InlineEditable> createState() => _InlineEditableState();
}

class _InlineEditableState extends State<_InlineEditable> {
  late final TextEditingController _ctrl;
  final FocusNode _focus = FocusNode();
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _InlineEditable old) {
    super.didUpdateWidget(old);
    if (!_editing && widget.value != _ctrl.text) _ctrl.text = widget.value;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startEdit() {
    setState(() {
      _ctrl.text = widget.value;
      _editing = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
      _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
    });
  }

  void _commit() {
    if (!_editing) return;
    widget.onSave(_ctrl.text.trim());
    setState(() => _editing = false);
  }

  void _cancel() {
    setState(() {
      _ctrl.text = widget.value;
      _editing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style =
        widget.style ??
        AppTypography.bodyMedium.copyWith(color: scheme.onSurface);
    if (!_editing) {
      final isEmpty = widget.value.trim().isEmpty;
      // Display mode: plain text, not tappable. Edit via pencil icon only.
      return Text(
        isEmpty ? widget.placeholder : widget.value,
        style: isEmpty
            ? style.copyWith(
                color: scheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              )
            : style,
      );
    }
    return TapRegion(
      onTapOutside: (_) => _commit(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _ctrl,
            focusNode: _focus,
            style: style,
            keyboardType: widget.maxLines > 1
                ? TextInputType.multiline
                : TextInputType.text,
            maxLines: widget.maxLines,
            minLines: 1,
            textInputAction: widget.maxLines > 1
                ? TextInputAction.newline
                : TextInputAction.done,
            decoration: InputDecoration(
              isDense: true,
              hintText: widget.hint.isEmpty ? null : widget.hint,
              hintStyle: AppTypography.bodySmall.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: _inputBorder(scheme.outline),
              enabledBorder: _inputBorder(scheme.outline),
              focusedBorder: _inputBorder(_accent(context)),
            ),
            onSubmitted: (_) => _commit(),
          ),
          const SizedBox(height: AppSpacing.xs),
          _EditActions(onSave: _commit, onCancel: _cancel),
        ],
      ),
    );
  }
}

/// Inline ✓ Save / ✗ Cancel buttons shown beneath an editing field.
class _EditActions extends StatelessWidget {
  const _EditActions({required this.onSave, required this.onCancel});
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _btn(
          Icons.check_rounded,
          _kTeal600,
          isDark ? const Color(0xFF0D3D2E) : const Color(0xFFE6FBF6),
          onSave,
          'Save',
        ),
        const SizedBox(width: AppSpacing.s),
        _btn(
          Icons.close_rounded,
          scheme.onSurfaceVariant,
          scheme.surfaceContainerHigh,
          onCancel,
          'Cancel',
        ),
      ],
    );
  }

  Widget _btn(
    IconData icon,
    Color fg,
    Color bg,
    VoidCallback onTap,
    String tooltip,
  ) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: bg,
        borderRadius: AppSpacing.radiusMd,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.radiusMd,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Icon(icon, size: 18, color: fg),
          ),
        ),
      ),
    );
  }
}

/// Consultation summary card. The pencil icon (top-right) is the ONLY way to
/// enter edit mode — tapping the summary text does nothing.
class _SummaryCard extends StatefulWidget {
  const _SummaryCard({required this.summary, required this.onSave});
  final String summary;
  final ValueChanged<String> onSave;

  @override
  State<_SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<_SummaryCard> {
  final _editKey = GlobalKey<_InlineEditableState>();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _accent(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF13162A), Color(0xFF0D1525)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEFF6FF), Color(0xFFF0FDFA)],
              ),
        borderRadius: AppSpacing.radiusXl,
        border: Border.all(
          color: isDark ? const Color(0xFF2A3354) : const Color(0xFFBFDBFE),
        ),
        boxShadow: isDark ? AppColors.cardShadowDark : AppColors.cardShadow,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.summarize_rounded, color: accent, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Consultation Summary',
                  style: AppTypography.titleSmall.copyWith(color: accent),
                ),
              ),
              GestureDetector(
                onTap: () => _editKey.currentState?._startEdit(),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.edit_rounded,
                    color: scheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          _InlineEditable(
            key: _editKey,
            value: widget.summary,
            onSave: widget.onSave,
            maxLines: 5,
            placeholder: 'Tap ✏️ to add a consultation summary',
            hint: 'Summarise what the patient came in for and the plan',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? scheme.onSurface : const Color(0xFF1E3A5F),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Patient information card. One pencil icon (top-right) enters edit mode for
/// ALL four fields simultaneously. ✓ saves all; ✗ reverts all.
class _PatientCard extends StatefulWidget {
  const _PatientCard({required this.patient, required this.onSave});
  final PatientProfile patient;
  final ValueChanged<PatientProfile> onSave;

  @override
  State<_PatientCard> createState() => _PatientCardState();
}

class _PatientCardState extends State<_PatientCard> {
  late TextEditingController _name;
  late TextEditingController _age;
  late TextEditingController _whatsapp;
  Sex? _sex;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.patient.name);
    _age = TextEditingController(text: widget.patient.age?.toString() ?? '');
    _whatsapp = TextEditingController(
      text: widget.patient.whatsappNumber ?? '',
    );
    _sex = widget.patient.sex;
  }

  @override
  void didUpdateWidget(covariant _PatientCard old) {
    super.didUpdateWidget(old);
    if (!_editing) {
      _name.text = widget.patient.name;
      _age.text = widget.patient.age?.toString() ?? '';
      _whatsapp.text = widget.patient.whatsappNumber ?? '';
      _sex = widget.patient.sex;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _whatsapp.dispose();
    super.dispose();
  }

  void _startEdit() {
    setState(() {
      _name.text = widget.patient.name;
      _age.text = widget.patient.age?.toString() ?? '';
      _whatsapp.text = widget.patient.whatsappNumber ?? '';
      _sex = widget.patient.sex;
      _editing = true;
    });
  }

  void _commit() {
    final rawWhatsapp = _whatsapp.text.trim();
    widget.onSave(
      widget.patient.copyWith(
        name: _name.text.trim(),
        age: int.tryParse(_age.text.trim()),
        sex: _sex,
        whatsappNumber: rawWhatsapp.isEmpty ? null : rawWhatsapp,
      ),
    );
    setState(() => _editing = false);
  }

  void _cancel() {
    setState(() {
      _name.text = widget.patient.name;
      _age.text = widget.patient.age?.toString() ?? '';
      _whatsapp.text = widget.patient.whatsappNumber ?? '';
      _sex = widget.patient.sex;
      _editing = false;
    });
  }

  String _sexLabel(Sex? s) => switch (s) {
    Sex.male => 'Male',
    Sex.female => 'Female',
    Sex.other => 'Other',
    null => '—',
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final titleStyle = AppTypography.titleSmall.copyWith(
      color: scheme.onSurface,
    );
    return _InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Patient Information',
                style: AppTypography.titleMedium.copyWith(
                  color: scheme.onSurface,
                ),
              ),
              const Spacer(),
              if (_editing)
                _EditActions(onSave: _commit, onCancel: _cancel)
              else
                GestureDetector(
                  onTap: _startEdit,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.edit_rounded,
                      color: scheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _LabeledField(
                  label: 'Name',
                  child: _editing
                      ? TextField(
                          controller: _name,
                          style: titleStyle,
                          keyboardType: TextInputType.name,
                          decoration: _fieldDeco(context, 'Patient name'),
                        )
                      : Text(
                          _name.text.isEmpty ? '—' : _name.text,
                          style: titleStyle,
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _LabeledField(
                  label: 'Age',
                  child: _editing
                      ? TextField(
                          controller: _age,
                          style: titleStyle,
                          keyboardType: TextInputType.number,
                          decoration: _fieldDeco(context, 'Years'),
                        )
                      : Text(
                          _age.text.isEmpty ? '—' : _age.text,
                          style: titleStyle,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _LabeledField(
                  label: 'Gender',
                  child: _editing
                      ? _GenderField(
                          value: _sex,
                          onChanged: (s) => setState(() => _sex = s),
                        )
                      : Text(_sexLabel(_sex), style: titleStyle),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _LabeledField(
                  label: 'WhatsApp',
                  child: _editing
                      ? TextField(
                          controller: _whatsapp,
                          style: titleStyle,
                          keyboardType: TextInputType.phone,
                          decoration: _fieldDeco(context, 'Mobile number'),
                        )
                      : Text(
                          _whatsapp.text.isEmpty
                              ? '—'
                              : '+91 ${_whatsapp.text}',
                          style: titleStyle,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDeco(BuildContext context, String hint) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: AppTypography.bodySmall.copyWith(
        color: scheme.onSurfaceVariant,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: _inputBorder(scheme.outline),
      enabledBorder: _inputBorder(scheme.outline),
      focusedBorder: _inputBorder(_accent(context)),
    );
  }
}

/// Diagnosis card with pencil-only edit trigger. The ICD-10 chip is always
/// visible regardless of edit state.
class _DiagnosisCard extends StatefulWidget {
  const _DiagnosisCard({
    required this.diagnosis,
    required this.icdCode,
    required this.icdDescription,
    required this.icdConfidence,
    required this.onSaveDiagnosis,
    required this.onRemoveIcd,
    required this.onEditIcd,
  });

  final String diagnosis;
  final String? icdCode;
  final String? icdDescription;
  final String? icdConfidence;
  final ValueChanged<String> onSaveDiagnosis;
  final VoidCallback onRemoveIcd;
  final void Function(String code, String? description) onEditIcd;

  @override
  State<_DiagnosisCard> createState() => _DiagnosisCardState();
}

class _DiagnosisCardState extends State<_DiagnosisCard> {
  late TextEditingController _ctrl;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.diagnosis);
  }

  @override
  void didUpdateWidget(covariant _DiagnosisCard old) {
    super.didUpdateWidget(old);
    if (!_editing && widget.diagnosis != _ctrl.text) {
      _ctrl.text = widget.diagnosis;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _startEdit() {
    setState(() {
      _ctrl.text = widget.diagnosis;
      _editing = true;
    });
  }

  void _commit() {
    widget.onSaveDiagnosis(_ctrl.text.trim());
    setState(() => _editing = false);
  }

  void _cancel() {
    setState(() {
      _ctrl.text = widget.diagnosis;
      _editing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Diagnosis',
                style: AppTypography.titleSmall.copyWith(
                  color: scheme.onSurface,
                ),
              ),
              const Spacer(),
              if (_editing)
                _EditActions(onSave: _commit, onCancel: _cancel)
              else
                GestureDetector(
                  onTap: _startEdit,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.edit_rounded,
                      color: scheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          if (_editing)
            TapRegion(
              onTapOutside: (_) => _commit(),
              child: TextField(
                controller: _ctrl,
                style: AppTypography.bodyMedium.copyWith(
                  color: scheme.onSurface,
                ),
                maxLines: 3,
                minLines: 1,
                autofocus: true,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'e.g. Viral fever',
                  hintStyle: AppTypography.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: _inputBorder(scheme.outline),
                  enabledBorder: _inputBorder(scheme.outline),
                  focusedBorder: _inputBorder(_accent(context)),
                ),
              ),
            )
          else if (widget.diagnosis.trim().isEmpty)
            Text(
              'No diagnosis — tap ✏️ to add',
              style: AppTypography.bodyMedium.copyWith(
                color: scheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Text(
              widget.diagnosis,
              style: AppTypography.bodyMedium.copyWith(color: scheme.onSurface),
            ),
          if (widget.icdCode != null) ...[
            const SizedBox(height: AppSpacing.s),
            _IcdChip(
              code: widget.icdCode!,
              description: widget.icdDescription,
              confidence: widget.icdConfidence,
              onRemove: widget.onRemoveIcd,
              onEdit: widget.onEditIcd,
            ),
          ],
        ],
      ),
    );
  }
}

/// Inline gender dropdown (Male / Female / Other).
class _GenderField extends StatelessWidget {
  const _GenderField({required this.value, required this.onChanged});
  final Sex? value;
  final ValueChanged<Sex?> onChanged;

  String _label(Sex s) => switch (s) {
    Sex.male => 'Male',
    Sex.female => 'Female',
    Sex.other => 'Other',
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DropdownButtonHideUnderline(
      child: DropdownButton<Sex>(
        value: value,
        isDense: true,
        isExpanded: true,
        icon: Icon(
          Icons.arrow_drop_down_rounded,
          color: scheme.onSurfaceVariant,
        ),
        hint: Text(
          'Tap to set',
          style: AppTypography.titleSmall.copyWith(
            color: scheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
        style: AppTypography.titleSmall.copyWith(color: scheme.onSurface),
        items: [
          for (final s in Sex.values)
            DropdownMenuItem(value: s, child: Text(_label(s))),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

/// Editable list of short lines (Advice / Instructions). The pencil icon
/// (top-right) is the ONLY way to enter edit mode — tapping the bullet text
/// does nothing.
class _EditableBullets extends StatefulWidget {
  const _EditableBullets({
    required this.title,
    required this.icon,
    required this.items,
    required this.hint,
    required this.placeholder,
    required this.onSave,
  });

  final String title;
  final IconData icon;
  final List<String> items;
  final String hint;
  final String placeholder;
  final ValueChanged<List<String>> onSave;

  @override
  State<_EditableBullets> createState() => _EditableBulletsState();
}

class _EditableBulletsState extends State<_EditableBullets> {
  late final TextEditingController _ctrl;
  final FocusNode _focus = FocusNode();
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.items.join('\n'));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<String> _parse(String raw) =>
      raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

  void _startEdit() {
    setState(() {
      _ctrl.text = widget.items.join('\n');
      _editing = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _commit() {
    if (!_editing) return;
    widget.onSave(_parse(_ctrl.text));
    setState(() => _editing = false);
  }

  void _cancel() => setState(() => _editing = false);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(widget.icon, color: _accent(context), size: 20),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  widget.title,
                  style: AppTypography.titleMedium.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ),
              if (!_editing)
                GestureDetector(
                  onTap: _startEdit,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.edit_rounded,
                      color: scheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          if (_editing)
            TapRegion(
              onTapOutside: (_) => _commit(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    style: AppTypography.bodyMedium.copyWith(
                      color: scheme.onSurface,
                    ),
                    minLines: 3,
                    maxLines: 8,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: widget.hint,
                      hintStyle: AppTypography.bodySmall.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: _inputBorder(scheme.outline),
                      enabledBorder: _inputBorder(scheme.outline),
                      focusedBorder: _inputBorder(_accent(context)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _EditActions(onSave: _commit, onCancel: _cancel),
                ],
              ),
            )
          else if (widget.items.isEmpty)
            Text(
              widget.placeholder,
              style: AppTypography.bodyMedium.copyWith(
                color: scheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in widget.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                    child: Text(
                      '•  $item',
                      style: AppTypography.bodyMedium.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Follow-up card. The toggle enables/disables follow-up and is always
/// interactive. The pencil icon next to the day count is the only way to
/// edit the number of days.
class _FollowUpCard extends StatefulWidget {
  const _FollowUpCard({required this.days, required this.onChanged});
  final int? days;
  final ValueChanged<int?> onChanged;

  @override
  State<_FollowUpCard> createState() => _FollowUpCardState();
}

class _FollowUpCardState extends State<_FollowUpCard> {
  late final TextEditingController _ctrl;
  final FocusNode _focus = FocusNode();
  bool _editing = false;

  bool get _enabled => widget.days != null && widget.days! > 0;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: (widget.days ?? 3).toString());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _toggle(bool on) {
    if (on) {
      final n = int.tryParse(_ctrl.text.trim());
      widget.onChanged(n != null && n > 0 ? n : 3);
    } else {
      setState(() => _editing = false);
      widget.onChanged(null);
    }
  }

  void _startEdit() {
    setState(() {
      _ctrl.text = (widget.days ?? 3).toString();
      _editing = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
      _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
    });
  }

  void _commit() {
    final n = int.tryParse(_ctrl.text.trim());
    widget.onChanged(n != null && n > 0 ? n : null);
    setState(() => _editing = false);
  }

  void _cancel() => setState(() => _editing = false);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.event_repeat_rounded,
                color: _accent(context),
                size: 20,
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                'Follow-up',
                style: AppTypography.titleMedium.copyWith(
                  color: scheme.onSurface,
                ),
              ),
              const Spacer(),
              Switch.adaptive(
                value: _enabled,
                activeTrackColor: _kTeal500,
                onChanged: _toggle,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (!_enabled)
            Text(
              'No follow-up set',
              style: AppTypography.bodyMedium.copyWith(
                color: scheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            )
          else if (_editing)
            TapRegion(
              onTapOutside: (_) => _commit(),
              child: Row(
                children: [
                  SizedBox(
                    width: 88,
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focus,
                      keyboardType: TextInputType.number,
                      style: AppTypography.bodyMedium.copyWith(
                        color: scheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        suffixText: 'days',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: _inputBorder(scheme.outline),
                        enabledBorder: _inputBorder(scheme.outline),
                        focusedBorder: _inputBorder(_accent(context)),
                      ),
                      onSubmitted: (_) => _commit(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  _EditActions(onSave: _commit, onCancel: _cancel),
                ],
              ),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'After ${widget.days} day${widget.days == 1 ? '' : 's'}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                GestureDetector(
                  onTap: _startEdit,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.edit_rounded,
                      color: scheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// One editable medicine card. Always editable (no pencil pattern).
class _MedicineRow extends StatefulWidget {
  const _MedicineRow({
    required this.med,
    required this.onChanged,
    required this.onCommit,
    required this.onDelete,
    this.autofocus = false,
  });

  final Medication med;

  /// Silent draft update on every keystroke (no rebuild).
  final ValueChanged<Medication> onChanged;

  /// Persist on focus loss / editing complete.
  final ValueChanged<Medication> onCommit;
  final VoidCallback onDelete;
  final bool autofocus;

  @override
  State<_MedicineRow> createState() => _MedicineRowState();
}

class _MedicineRowState extends State<_MedicineRow> {
  late final TextEditingController _name;
  late final TextEditingController _dosage;
  late final TextEditingController _freq;
  late final TextEditingController _duration;

  static const _timings = [
    'Before food',
    'After food',
    'With food',
    'Empty stomach',
    'Before bed',
    'As directed',
  ];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.med.name);
    _dosage = TextEditingController(text: widget.med.dosage);
    _freq = TextEditingController(text: widget.med.frequency);
    _duration = TextEditingController(text: widget.med.duration);
  }

  @override
  void didUpdateWidget(covariant _MedicineRow old) {
    super.didUpdateWidget(old);
    _sync(_name, widget.med.name);
    _sync(_dosage, widget.med.dosage);
    _sync(_freq, widget.med.frequency);
    _sync(_duration, widget.med.duration);
  }

  void _sync(TextEditingController c, String v) {
    if (c.text != v) c.text = v;
  }

  @override
  void dispose() {
    _name.dispose();
    _dosage.dispose();
    _freq.dispose();
    _duration.dispose();
    super.dispose();
  }

  Medication get _med => widget.med;

  TextStyle get _labelStyle => AppTypography.labelSmall.copyWith(
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outline),
        borderRadius: AppSpacing.radiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Medicine name (full width) + × delete
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _field(
                  'Medicine',
                  _name,
                  (v) => widget.onChanged(_med.copyWith(name: v)),
                  () => widget.onCommit(_med.copyWith(name: _name.text)),
                  autofocus: widget.autofocus,
                  hint: 'e.g. Paracetamol',
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                onPressed: widget.onDelete,
                tooltip: 'Remove medicine',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFFDC2626),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          // Row 2: Dosage (50%) + Duration (50%)
          Row(
            children: [
              Expanded(
                child: _field(
                  'Dosage',
                  _dosage,
                  (v) => widget.onChanged(_med.copyWith(dosage: v)),
                  () => widget.onCommit(_med.copyWith(dosage: _dosage.text)),
                  hint: '650 mg',
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: _field(
                  'Duration',
                  _duration,
                  (v) => widget.onChanged(_med.copyWith(duration: v)),
                  () =>
                      widget.onCommit(_med.copyWith(duration: _duration.text)),
                  hint: '5 days',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          // Row 3: Frequency (full width)
          _field(
            'Frequency',
            _freq,
            (v) => widget.onChanged(_med.copyWith(frequency: v)),
            () => widget.onCommit(_med.copyWith(frequency: _freq.text)),
            hint: 'Three times a day',
          ),
          const SizedBox(height: AppSpacing.s),
          // Row 4: Meal-timing chips
          Text('Timing', style: _labelStyle),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.xs,
            children: [
              for (final t in _timings)
                _TimingChip(
                  label: t,
                  selected: _med.timing == t,
                  onTap: () => widget.onCommit(
                    _med.copyWith(timing: _med.timing == t ? '' : t),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    ValueChanged<String> onChanged,
    VoidCallback onCommit, {
    bool autofocus = false,
    String hint = '',
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle),
        const SizedBox(height: AppSpacing.xxs),
        TextField(
          controller: controller,
          autofocus: autofocus,
          style: AppTypography.bodyMedium.copyWith(color: scheme.onSurface),
          onChanged: onChanged,
          onEditingComplete: onCommit,
          onTapOutside: (_) => onCommit(),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: AppTypography.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            border: _inputBorder(scheme.outline),
            enabledBorder: _inputBorder(scheme.outline),
            focusedBorder: _inputBorder(_accent(context)),
          ),
        ),
      ],
    );
  }
}

/// Selectable meal-timing chip (teal when selected).
class _TimingChip extends StatelessWidget {
  const _TimingChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _kTeal500 : scheme.surface,
          borderRadius: AppSpacing.radiusPill,
          border: Border.all(color: selected ? _kTeal500 : scheme.outline),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: selected ? Colors.white : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Sticky bottom action bar. The disclaimer sits above the buttons.
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.signed,
    required this.showShare,
    required this.onSign,
    required this.onShare,
  });

  final bool signed;
  final bool showShare;
  final VoidCallback onSign;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, -2),
            blurRadius: 12,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.s,
        AppSpacing.lg,
        AppSpacing.s,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'AI extracts only what the doctor said. Review the summary and '
            'medicines before signing.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          _GradientCta(
            label: signed ? 'Generate Prescription PDF' : 'Sign & Generate PDF',
            trailingIcon: Icons.arrow_forward_rounded,
            onTap: onSign,
          ),
          if (showShare) ...[
            const SizedBox(height: AppSpacing.s),
            _OutlineButton(
              label: 'Share on WhatsApp',
              icon: Icons.share_rounded,
              onTap: onShare,
            ),
          ],
        ],
      ),
    );
  }
}

class _GradientCta extends StatelessWidget {
  const _GradientCta({
    required this.label,
    this.trailingIcon,
    required this.onTap,
  });
  final String label;
  final IconData? trailingIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kBlue600, _kTeal500],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: AppSpacing.radiusLg,
          boxShadow: const [
            BoxShadow(
              color: _kBlueShadow,
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                style: AppTypography.titleSmall.copyWith(color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: AppSpacing.s),
              Icon(trailingIcon, color: Colors.white, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: AppSpacing.radiusLg,
          border: Border.all(color: scheme.outline, width: 2),
          boxShadow: Theme.of(context).brightness == Brightness.dark
              ? AppColors.cardShadowDark
              : AppColors.cardShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: scheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.s),
            Flexible(
              child: Text(
                label,
                style: AppTypography.titleSmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
  borderRadius: AppSpacing.radiusMd,
  borderSide: BorderSide(color: color),
);

const _kAmber400 = Color(0xFFFBBF24);
const _kAmber50 = Color(0xFFFFFBEB);

/// Small ICD-10 annotation chip shown below the diagnosis field.
class _IcdChip extends StatelessWidget {
  const _IcdChip({
    required this.code,
    required this.description,
    required this.confidence,
    required this.onRemove,
    required this.onEdit,
  });

  final String code;
  final String? description;
  final String? confidence;
  final VoidCallback onRemove;
  final void Function(String code, String? description) onEdit;

  bool get _isMedium => confidence == 'medium';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = description != null && description!.isNotEmpty
        ? 'ICD-10: $code - $description'
        : 'ICD-10: $code';

    final bgColor = _isMedium
        ? (isDark ? const Color(0xFF2A1A0A) : _kAmber50)
        : scheme.surfaceContainerHigh;
    final borderColor = _isMedium ? _kAmber400 : scheme.outline;
    final textColor = _isMedium
        ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E))
        : scheme.onSurfaceVariant;

    return GestureDetector(
      onTap: () => _showEditSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isMedium) ...[
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.help_outline_rounded,
                  size: 13,
                  color: _kAmber400,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 12, color: textColor, height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.close_rounded,
                  size: 15,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _IcdEditSheet(
        initialCode: code,
        initialDescription: description,
        isMediumConfidence: _isMedium,
        onSave: onEdit,
      ),
    );
  }
}

/// Bottom sheet for viewing / editing an ICD-10 code.
class _IcdEditSheet extends StatefulWidget {
  const _IcdEditSheet({
    required this.initialCode,
    required this.initialDescription,
    required this.isMediumConfidence,
    required this.onSave,
  });

  final String initialCode;
  final String? initialDescription;
  final bool isMediumConfidence;
  final void Function(String code, String? description) onSave;

  @override
  State<_IcdEditSheet> createState() => _IcdEditSheetState();
}

class _IcdEditSheetState extends State<_IcdEditSheet> {
  late final TextEditingController _codeCtrl;
  late final TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _codeCtrl = TextEditingController(text: widget.initialCode);
    _descCtrl = TextEditingController(text: widget.initialDescription ?? '');
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ICD-10 Code',
            style: AppTypography.titleMedium.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: 16),
          if (widget.isMediumConfidence) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A1A0A) : _kAmber50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _kAmber400),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.help_outline_rounded,
                    size: 16,
                    color: _kAmber400,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI suggestion - please verify this code before relying '
                      'on it.',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? const Color(0xFFFBBF24)
                            : const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _codeCtrl,
            decoration: const InputDecoration(
              labelText: 'Code (e.g. B34.9)',
              isDense: true,
            ),
            style: AppTypography.bodyMedium.copyWith(color: scheme.onSurface),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(
              labelText: 'Description',
              isDense: true,
            ),
            style: AppTypography.bodyMedium.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: 16),
          Text(
            'This code was suggested by AI based on the diagnosis text. '
            'Please verify accuracy before clinical or billing use.',
            style: AppTypography.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final code = _codeCtrl.text.trim();
                final desc = _descCtrl.text.trim();
                if (code.isNotEmpty) {
                  widget.onSave(code, desc.isEmpty ? null : desc);
                }
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
