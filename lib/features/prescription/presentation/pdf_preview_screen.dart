import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_paths.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/repositories/patient_repository.dart';
import '../../../data/repositories/visit_repository.dart';
import '../../../domain/models/medication.dart';
import '../../../domain/models/patient.dart';
import '../../../domain/models/report_attachment.dart';
import '../../../domain/models/visit.dart';
import '../../settings/data/doctor_profile_repository.dart';
import '../data/prescription_pdf_service.dart';

const _kBlue600 = Color(0xFF2563EB);
const _kTeal500 = Color(0xFF14B8A6);
const _kTeal600 = Color(0xFF0D9488);

class PdfPreviewScreen extends ConsumerStatefulWidget {
  const PdfPreviewScreen({super.key, required this.visitId});

  final String visitId;

  @override
  ConsumerState<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends ConsumerState<PdfPreviewScreen> {
  VisitRecord? _visit;
  PatientProfile? _patient;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final v = await ref.read(visitRepositoryProvider).byId(widget.visitId);
    final p = v == null
        ? null
        : await ref.read(patientRepositoryProvider).byId(v.patientId);
    if (mounted) {
      setState(() {
        _visit = v;
        _patient = p;
        _loading = false;
      });
    }
  }

  bool _busy = false;

  /// Generates the real PDF and opens the OS share sheet with it attached, so
  /// the doctor sends the patient a proper document (pick WhatsApp from the
  /// sheet) — not a plain-text message.
  Future<void> _shareWhatsApp() => _runPdfAction((svc) => svc.shareAsFile(
        visit: _visit!,
        patient: _patient,
        doctor: ref.read(doctorProfileControllerProvider),
      ));

  Future<void> _downloadPdf() => _runPdfAction((svc) => svc.shareAsFile(
        visit: _visit!,
        patient: _patient,
        doctor: ref.read(doctorProfileControllerProvider),
      ));

  Future<void> _printPdf() => _runPdfAction((svc) => svc.printOrPreview(
        visit: _visit!,
        patient: _patient,
        doctor: ref.read(doctorProfileControllerProvider),
      ));

  Future<void> _runPdfAction(
      Future<void> Function(PrescriptionPdfService svc) action) async {
    if (_visit == null || _busy) return;
    setState(() => _busy = true);
    try {
      await action(ref.read(prescriptionPdfServiceProvider));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not generate PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_visit == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Prescription')),
        body: const EmptyState(
            title: 'Visit not found', icon: Icons.search_off_rounded),
      );
    }

    final insight = _visit!.insight;
    final meds = insight?.medications ?? [];
    final adviceList = (insight?.advice ?? const <String>[])
        .where((s) => s.trim().isNotEmpty)
        .toList();
    final instructionsList = (insight?.instructions ?? const <String>[])
        .where((s) => s.trim().isNotEmpty)
        .toList();
    final hasAdviceContent =
        adviceList.isNotEmpty || instructionsList.isNotEmpty;
    final doctor = ref.watch(doctorProfileControllerProvider);
    final today = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final dateStr =
        '${today.day.toString().padLeft(2, '0')} ${months[today.month - 1]} ${today.year}';

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
                          Text('Prescription Ready',
                              style: AppTypography.headlineMedium),
                          Text('Review and share with patient',
                              style: AppTypography.bodySmall),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => context.go('/'),
                      icon: const Icon(Icons.home_rounded, size: 18),
                      label: const Text('Home'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _StepProgressBar(activeStep: 3),
              ),
              const SizedBox(height: AppSpacing.md),
              // Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl,
                  ),
                  children: [
                    // Success banner
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF0FDF4), Color(0xFFECFDF5)],
                        ),
                        borderRadius: AppSpacing.radiusXl,
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF16A34A), size: 32),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Prescription Generated!',
                                    style: AppTypography.titleSmall.copyWith(
                                        color: const Color(0xFF14532D))),
                                const SizedBox(height: AppSpacing.xxs),
                                Text(
                                  'Your prescription is ready to share.',
                                  style: AppTypography.bodySmall.copyWith(
                                      color: const Color(0xFF166534)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Prescription card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppSpacing.radiusXl,
                        border: Border.all(
                            color: const Color(0xFFD1D5DB), width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 24,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // PDF header gradient
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_kBlue600, _kTeal500],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(doctor.clinicName,
                                          style: AppTypography.headlineLarge
                                              .copyWith(color: Colors.white)),
                                      Text(doctor.clinicAddress,
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                                  color: Colors.white70)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.s),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(doctor.name,
                                          textAlign: TextAlign.end,
                                          style: AppTypography.titleSmall
                                              .copyWith(color: Colors.white)),
                                      Text(doctor.qualifications,
                                          textAlign: TextAlign.end,
                                          style: AppTypography.bodySmall
                                              .copyWith(color: Colors.white70)),
                                      Text('Reg. No: ${doctor.regNo}',
                                          textAlign: TextAlign.end,
                                          style: AppTypography.bodySmall
                                              .copyWith(color: Colors.white70)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // PDF body
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text('Date: $dateStr',
                                      style: AppTypography.bodySmall),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                // Patient details
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9FAFB),
                                    borderRadius: AppSpacing.radiusMd,
                                    border: Border.all(
                                        color: const Color(0xFFE5E7EB),
                                        width: 2),
                                  ),
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Patient Details',
                                          style: AppTypography.titleMedium),
                                      const SizedBox(height: AppSpacing.md),
                                      if (_patient != null)
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _PdfField(
                                                  label: 'Name',
                                                  value: _patient!.name),
                                            ),
                                            Expanded(
                                              child: _PdfField(
                                                label: 'Age',
                                                value: _patient!.age != null
                                                    ? '${_patient!.age} years'
                                                    : '—',
                                              ),
                                            ),
                                            Expanded(
                                              child: _PdfField(
                                                label: 'Gender',
                                                value: _genderLabel(
                                                    _patient!.sex),
                                              ),
                                            ),
                                            Expanded(
                                              child: _PdfField(
                                                label: 'Contact',
                                                value: _patient!.whatsappNumber !=
                                                        null
                                                    ? '+91 ${_patient!.whatsappNumber}'
                                                    : '—',
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                if (insight?.symptoms.isNotEmpty ?? false) ...[
                                  Text('Symptoms',
                                      style: AppTypography.titleMedium),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(insight!.symptoms.join(', '),
                                      style: AppTypography.bodyMedium),
                                  const SizedBox(height: AppSpacing.lg),
                                ],
                                if (insight?.diagnosis.isNotEmpty ?? false) ...[
                                  Text('Diagnosis',
                                      style: AppTypography.titleMedium),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(insight!.diagnosis,
                                      style: AppTypography.bodyMedium),
                                  const SizedBox(height: AppSpacing.lg),
                                ],
                                // Rx symbol
                                Row(
                                  children: [
                                    Text(
                                      '℞',
                                      style: TextStyle(
                                        fontSize: 40,
                                        color: _kBlue600,
                                        fontFamily: 'serif',
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.m),
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              _kBlue600,
                                              Colors.transparent
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                Text('Prescribed Medicines',
                                    style: AppTypography.titleMedium),
                                const SizedBox(height: AppSpacing.md),
                                // Medicines table
                                if (meds.isEmpty)
                                  Text('No medicines prescribed.',
                                      style: AppTypography.bodySmall)
                                else
                                  _MedicineTable(meds: meds),
                                const SizedBox(height: AppSpacing.lg),
                                // Additional instructions
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFBEB),
                                    borderRadius: AppSpacing.radiusMd,
                                    border: Border.all(
                                        color: const Color(0xFFFDE68A)),
                                  ),
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Advice & Instructions',
                                          style: AppTypography.titleSmall),
                                      const SizedBox(height: AppSpacing.s),
                                      if (adviceList.isNotEmpty) ...[
                                        Text('Advice',
                                            style: AppTypography.labelMedium),
                                        for (final a in adviceList)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: AppSpacing.xxs),
                                            child: Text('• $a',
                                                style:
                                                    AppTypography.bodySmall),
                                          ),
                                        const SizedBox(height: AppSpacing.xs),
                                      ],
                                      if (instructionsList.isNotEmpty) ...[
                                        Text('Instructions',
                                            style: AppTypography.labelMedium),
                                        for (final ins in instructionsList)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: AppSpacing.xxs),
                                            child: Text('• $ins',
                                                style:
                                                    AppTypography.bodySmall),
                                          ),
                                      ],
                                      if (!hasAdviceContent)
                                        for (final instr in [
                                          'Take medicines after meals',
                                          'Drink plenty of fluids and rest',
                                        ])
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: AppSpacing.xxs),
                                            child: Text('• $instr',
                                                style:
                                                    AppTypography.bodySmall),
                                          ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                // Signature
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        doctor.name,
                                        style: AppTypography.headlineMedium
                                            .copyWith(
                                          color: _kBlue600,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(doctor.qualifications,
                                          style: AppTypography.bodySmall),
                                      Text('Reg. No: ${doctor.regNo}',
                                          style: AppTypography.bodySmall),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                const Divider(),
                                const SizedBox(height: AppSpacing.s),
                                Text(
                                  'This is a computer-generated prescription\n'
                                  'Generated by MediScribe AI | Secure • Private • HIPAA Compliant',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_visit!.attachments.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _PreviousReportsPreview(
                          attachments: _visit!.attachments),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    // Action buttons
                    _GradientCta(
                      label: _busy ? 'Preparing PDF…' : 'Share on WhatsApp',
                      icon: Icons.share_rounded,
                      colors: [const Color(0xFF16A34A), const Color(0xFF10B981)],
                      shadowColor: const Color(0x4D16A34A),
                      onTap: _busy ? null : _shareWhatsApp,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _OutlineCta(
                            label: 'Download PDF',
                            icon: Icons.download_rounded,
                            onTap: _busy ? null : _downloadPdf,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _OutlineCta(
                            label: 'Print',
                            icon: Icons.print_rounded,
                            onTap: _busy ? null : _printPdf,
                          ),
                        ),
                      ],
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

  static String _genderLabel(Sex? sex) {
    if (sex == Sex.male) return 'Male';
    if (sex == Sex.female) return 'Female';
    if (sex == Sex.other) return 'Other';
    return '—';
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
                        ? const LinearGradient(colors: [_kBlue600, _kTeal500])
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
                color: i == activeStep ? _kTeal600 : i < activeStep ? _kTeal600 : const Color(0xFF9CA3AF),
                fontWeight: i == activeStep ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PdfField extends StatelessWidget {
  const _PdfField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.bodySmall),
        Text(value,
            style: AppTypography.titleSmall,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _MedicineTable extends StatelessWidget {
  const _MedicineTable({required this.meds});
  final List<Medication> meds;

  @override
  Widget build(BuildContext context) {
    const headers = ['#', 'Medicine', 'Dosage', 'Frequency', 'Duration'];
    final widths = [0.05, 0.25, 0.15, 0.30, 0.25];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD1D5DB)),
        borderRadius: AppSpacing.radiusMd,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header row
          Container(
            color: const Color(0xFFF3F4F6),
            child: _TableRow(
              cells: headers,
              widths: widths,
              isHeader: true,
            ),
          ),
          for (var i = 0; i < meds.length; i++) ...[
            const Divider(height: 1),
            _TableRow(
              cells: [
                '${i + 1}',
                meds[i].name,
                meds[i].dosage,
                meds[i].frequency,
                meds[i].duration,
              ],
              widths: widths,
              isHeader: false,
            ),
          ],
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.cells,
    required this.widths,
    required this.isHeader,
  });
  final List<String> cells;
  final List<double> widths;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Row(
        children: [
          for (var i = 0; i < cells.length; i++) ...[
            if (i > 0)
              Container(width: 1, height: 40, color: const Color(0xFFD1D5DB)),
            SizedBox(
              width: constraints.maxWidth * widths[i],
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  cells[i],
                  style: isHeader
                      ? AppTypography.labelSmall
                      : AppTypography.bodySmall.copyWith(
                          color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ],
      );
    });
  }
}

class _PreviousReportsPreview extends StatelessWidget {
  const _PreviousReportsPreview({required this.attachments});
  final List<ReportAttachment> attachments;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.radiusXl,
        border: Border.all(color: const Color(0xFFD1D5DB), width: 2),
        boxShadow: AppColors.cardShadow,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.attach_file_rounded, color: _kBlue600, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Text('Previous Reports (${attachments.length})',
                  style: AppTypography.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('Attached to the prescription PDF as additional pages.',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < attachments.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${i + 1}. ${attachments[i].caption.trim().isEmpty ? 'Report ${i + 1}' : attachments[i].caption.trim()}',
                    style: AppTypography.labelMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ClipRRect(
                    borderRadius: AppSpacing.radiusMd,
                    child: Image.file(
                      File(AppPaths.resolveAttachment(attachments[i].path)),
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        height: 120,
                        color: const Color(0xFFF3F4F6),
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_rounded,
                            color: Color(0xFF9CA3AF)),
                      ),
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

class _GradientCta extends StatelessWidget {
  const _GradientCta({
    required this.label,
    required this.icon,
    required this.colors,
    required this.shadowColor,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final List<Color> colors;
  final Color shadowColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: AppSpacing.radiusLg,
          boxShadow: [
            BoxShadow(color: shadowColor, blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: AppSpacing.m),
            Text(label, style: AppTypography.titleSmall.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _OutlineCta extends StatelessWidget {
  const _OutlineCta({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
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
