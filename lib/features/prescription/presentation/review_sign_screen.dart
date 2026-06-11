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
const _kTeal500 = Color(0xFF14B8A6);
const _kTeal600 = Color(0xFF0D9488);
const _kBlueShadow = Color(0x4D2563EB);

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
    setState(() {
      _visit = updated;
      _saving = false;
    });
  }

  Future<void> _sign() async {
    if (_visit == null) return;
    await _save();
    final signed = _visit!.copyWith(signed: true, signedAt: DateTime.now());
    await ref.read(visitRepositoryProvider).upsert(signed);
    setState(() => _visit = signed);
    if (mounted) {
      context.go(AppRoute.pdf.build(params: {'visitId': widget.visitId}));
    }
  }

  Future<void> _share() async {
    if (_visit == null || _patient == null) return;
    final number =
        (_patient!.whatsappNumber ?? '').replaceAll(RegExp(r'\D'), '');
    final lines = [
      'Prescription for ${_patient!.name}',
      if (_draft.diagnosis.isNotEmpty) 'Diagnosis: ${_draft.diagnosis}',
      if (_draft.medications.isNotEmpty) ...[
        'Medications:',
        ..._draft.medications.map(
          (m) => '• ${[m.name, m.dosage, m.frequency, m.duration].where((s) => s.trim().isNotEmpty).join(' · ')}',
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_visit == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Review')),
        body: const EmptyState(
            title: 'Visit not found', icon: Icons.search_off_rounded),
      );
    }

    final signed = _visit!.signed;

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
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s, AppSpacing.md, AppSpacing.lg, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go('/'),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Color(0xFF374151)),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Review Prescription',
                              style: AppTypography.headlineMedium),
                          Text('Verify and edit transcribed details',
                              style: AppTypography.bodySmall),
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
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _StepProgressBar(activeStep: 2),
              ),
              const SizedBox(height: AppSpacing.md),
              // Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  children: [
                    // Consultation summary card — the concise, human-readable
                    // note. We intentionally do NOT show the raw transcript or
                    // the full field-by-field extraction here; the doctor reviews
                    // the summary plus the prescription essentials below.
                    if (_draft.consultationSummary.trim().isNotEmpty)
                      _SummaryCard(summary: _draft.consultationSummary),
                    if (_draft.consultationSummary.trim().isNotEmpty)
                      const SizedBox(height: AppSpacing.md),
                    // Patient info card
                    if (_patient != null)
                      _InfoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Patient Information',
                                style: AppTypography.titleMedium),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                Expanded(
                                    child: _InfoField(
                                        label: 'Name',
                                        value: _patient!.name)),
                                Expanded(
                                    child: _InfoField(
                                        label: 'Age',
                                        value: _patient!.age != null
                                            ? '${_patient!.age}'
                                            : '—')),
                                Expanded(
                                    child: _InfoField(
                                        label: 'Gender',
                                        value: _patient!.sex?.name ?? '—')),
                                Expanded(
                                    child: _InfoField(
                                        label: 'WhatsApp',
                                        value: _patient!.whatsappNumber !=
                                                null
                                            ? '+91 ${_patient!.whatsappNumber}'
                                            : '—')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: AppSpacing.md),
                    // Diagnosis (kept — it's core to the prescription and prints
                    // on the Rx). Symptoms/tests/notes are folded into the
                    // summary above and are not shown as separate raw fields.
                    _InfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Diagnosis', style: AppTypography.titleSmall),
                          const SizedBox(height: AppSpacing.s),
                          TextField(
                            controller: TextEditingController(
                                text: _draft.diagnosis),
                            style: AppTypography.bodyMedium,
                            maxLines: 3,
                            minLines: 1,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Viral fever',
                              isDense: true,
                            ),
                            onChanged: (v) =>
                                _draft = _draft.copyWith(diagnosis: v),
                            onEditingComplete: _save,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Medicines
                    _InfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.medication_rounded,
                                  color: _kBlue600, size: 20),
                              const SizedBox(width: AppSpacing.xs),
                              Text('Prescribed Medicines',
                                  style: AppTypography.titleMedium),
                              const Spacer(),
                              GestureDetector(
                                onTap: () {
                                  setState(() => _draft = _draft.copyWith(
                                        medications: [
                                          ..._draft.medications,
                                          const Medication(name: ''),
                                        ],
                                      ));
                                  _save();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.m,
                                    vertical: AppSpacing.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: AppSpacing.radiusMd,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.add_rounded,
                                          color: _kBlue600, size: 16),
                                      const SizedBox(width: AppSpacing.xs),
                                      Text('Add',
                                          style: AppTypography.labelSmall
                                              .copyWith(color: _kBlue600)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          if (_draft.medications.isEmpty)
                            Text('No medications recorded.',
                                style: AppTypography.bodySmall),
                          for (var i = 0;
                              i < _draft.medications.length;
                              i++) ...[
                            _MedicineRow(
                              med: _draft.medications[i],
                              onChanged: (m) {
                                final next = [..._draft.medications]..[i] = m;
                                setState(() => _draft =
                                    _draft.copyWith(medications: next));
                                _save();
                              },
                              onDelete: () {
                                final next = [..._draft.medications]
                                  ..removeAt(i);
                                setState(() => _draft =
                                    _draft.copyWith(medications: next));
                                _save();
                              },
                            ),
                            if (i < _draft.medications.length - 1)
                              const Divider(height: AppSpacing.md),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _BulletField(
                      title: 'Advice',
                      icon: Icons.tips_and_updates_rounded,
                      items: _draft.advice,
                      hint: 'General guidance — one per line\n'
                          'e.g. Take adequate rest\nAvoid oily food',
                      onChanged: (v) => _draft = _draft.copyWith(advice: v),
                      onSaved: _save,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _BulletField(
                      title: 'Instructions',
                      icon: Icons.checklist_rounded,
                      items: _draft.instructions,
                      hint: 'Things to follow — one per line\n'
                          'e.g. Take medicine after food\nReturn if fever persists 3 days',
                      onChanged: (v) =>
                          _draft = _draft.copyWith(instructions: v),
                      onSaved: _save,
                    ),
                    if (_draft.followUpDays != null &&
                        _draft.followUpDays! > 0) ...[
                      const SizedBox(height: AppSpacing.md),
                      _InfoCard(
                        child: Row(
                          children: [
                            const Icon(Icons.event_repeat_rounded,
                                color: _kBlue600, size: 20),
                            const SizedBox(width: AppSpacing.s),
                            Text('Follow-up',
                                style: AppTypography.titleSmall),
                            const Spacer(),
                            Text(
                              'After ${_draft.followUpDays} day${_draft.followUpDays == 1 ? '' : 's'}',
                              style: AppTypography.bodyMedium
                                  .copyWith(color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    // CTA
                    _GradientCta(
                      label: signed
                          ? 'Generate Prescription PDF'
                          : 'Sign & Generate PDF',
                      trailingIcon: Icons.arrow_forward_rounded,
                      onTap: _sign,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (!signed && _patient?.whatsappNumber != null)
                      _OutlineButton(
                        label: 'Share on WhatsApp',
                        icon: Icons.share_rounded,
                        onTap: _share,
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'AI extracts only what the doctor said. Review the summary and medicines before signing.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
                    ? _kTeal600
                    : i < activeStep
                        ? _kTeal600
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEFF6FF), Color(0xFFF0FDFA)],
        ),
        borderRadius: AppSpacing.radiusXl,
        border: Border.all(color: const Color(0xFFBFDBFE)),
        boxShadow: AppColors.cardShadow,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.summarize_rounded, color: _kBlue600, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Text('Consultation Summary',
                  style: AppTypography.titleSmall.copyWith(color: _kBlue600)),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            summary,
            style: AppTypography.bodyMedium.copyWith(
              color: const Color(0xFF1E3A5F),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.radiusXl,
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: AppColors.cardShadow,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: child,
    );
  }
}

class _InfoField extends StatelessWidget {
  const _InfoField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.bodySmall),
        const SizedBox(height: AppSpacing.xxs),
        Text(value, style: AppTypography.titleSmall),
      ],
    );
  }
}

/// Editable list of short lines (one item per line). Used for Advice and
/// Instructions. Holds its own controller so the parent rebuilding (e.g. when
/// editing medicines) doesn't reset the cursor.
class _BulletField extends StatefulWidget {
  const _BulletField({
    required this.title,
    required this.icon,
    required this.items,
    required this.hint,
    required this.onChanged,
    required this.onSaved,
  });

  final String title;
  final IconData icon;
  final List<String> items;
  final String hint;
  final ValueChanged<List<String>> onChanged;
  final VoidCallback onSaved;

  @override
  State<_BulletField> createState() => _BulletFieldState();
}

class _BulletFieldState extends State<_BulletField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.items.join('\n'));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<String> _parse(String raw) => raw
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(widget.icon, color: _kBlue600, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Text(widget.title, style: AppTypography.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          TextField(
            controller: _ctrl,
            style: AppTypography.bodyMedium,
            minLines: 2,
            maxLines: 6,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppTypography.bodySmall
                  .copyWith(color: AppColors.textMuted),
              isDense: true,
            ),
            onChanged: (v) => widget.onChanged(_parse(v)),
            onEditingComplete: widget.onSaved,
            onTapOutside: (_) => widget.onSaved(),
          ),
        ],
      ),
    );
  }
}

class _MedicineRow extends StatelessWidget {
  const _MedicineRow({
    required this.med,
    required this.onChanged,
    required this.onDelete,
  });
  final Medication med;
  final ValueChanged<Medication> onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFF3F4F6)),
        borderRadius: AppSpacing.radiusMd,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        initialValue: med.name,
                        style: AppTypography.bodySmall,
                        decoration: const InputDecoration(
                            labelText: 'Medicine', isDense: true),
                        onChanged: (v) => onChanged(med.copyWith(name: v)),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        initialValue: med.dosage,
                        style: AppTypography.bodySmall,
                        decoration: const InputDecoration(
                            labelText: 'Dosage', isDense: true),
                        onChanged: (v) => onChanged(med.copyWith(dosage: v)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: med.frequency,
                        style: AppTypography.bodySmall,
                        decoration: const InputDecoration(
                            labelText: 'Frequency', isDense: true),
                        onChanged: (v) =>
                            onChanged(med.copyWith(frequency: v)),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Expanded(
                      child: TextFormField(
                        initialValue: med.duration,
                        style: AppTypography.bodySmall,
                        decoration: const InputDecoration(
                            labelText: 'Duration', isDense: true),
                        onChanged: (v) =>
                            onChanged(med.copyWith(duration: v)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                color: Color(0xFFDC2626), size: 20),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
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
            BoxShadow(color: _kBlueShadow, blurRadius: 16, offset: Offset(0, 6)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: AppTypography.titleSmall.copyWith(color: Colors.white)),
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
  const _OutlineButton({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppSpacing.radiusLg,
          border: Border.all(color: const Color(0xFFD1D5DB), width: 2),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.s),
            Text(label, style: AppTypography.titleSmall.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
