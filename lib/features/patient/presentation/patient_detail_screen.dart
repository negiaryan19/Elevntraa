import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_paths.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/db/database_provider.dart';
import '../../../data/repositories/patient_repository.dart';
import '../../../data/repositories/visit_repository.dart';
import '../../../domain/models/medical_insight.dart';
import '../../../domain/models/patient.dart';
import '../../../domain/models/report_attachment.dart';
import '../../../domain/models/visit.dart';
import '../../../core/errors/failure_text.dart';
import '../../../l10n/app_localizations.dart';
import '../../prescription/data/prescription_pdf_service.dart';
import '../../settings/data/doctor_profile_repository.dart';
import 'edit_patient_sheet.dart';
import 'view_prescription_screen.dart';

const _kBlue600 = Color(0xFF2563EB);
const _kTeal500 = Color(0xFF14B8A6);

/// Per-patient timeline. Lists every consultation for the patient with the
/// clinical summary (symptoms, diagnosis, medicines, follow-up) and a button
/// to open the real prescription PDF for that visit.
class PatientDetailScreen extends ConsumerStatefulWidget {
  const PatientDetailScreen({super.key, required this.patientId});

  final String patientId;

  @override
  ConsumerState<PatientDetailScreen> createState() =>
      _PatientDetailScreenState();
}

class _PatientDetailScreenState extends ConsumerState<PatientDetailScreen> {
  PatientProfile? _patient;
  List<VisitRecord> _visits = [];
  bool _loading = true;
  String? _busyVisitId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final patient = await ref
        .read(patientRepositoryProvider)
        .byId(widget.patientId);
    final visits = await ref
        .read(visitRepositoryProvider)
        .forPatient(widget.patientId);
    if (mounted) {
      setState(() {
        _patient = patient;
        _visits = visits;
        _loading = false;
      });
    }
  }

  /// Edits the patient's own details. Visits are left alone: the sheet saves
  /// the patient row only, and the header is refreshed from what it returns.
  Future<void> _editPatient() async {
    final patient = _patient;
    if (patient == null) return;
    final saved = await EditPatientSheet.show(context, patient);
    if (saved != null && mounted) setState(() => _patient = saved);
  }

  Future<void> _openPdf(VisitRecord visit) async {
    if (_busyVisitId != null) return;
    setState(() => _busyVisitId = visit.id);
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ViewPrescriptionScreen(visit: visit, patient: _patient),
        ),
      );
    } finally {
      if (mounted) setState(() => _busyVisitId = null);
    }
  }

  Future<void> _sharePdf(VisitRecord visit) async {
    if (_busyVisitId != null) return;
    setState(() => _busyVisitId = visit.id);
    try {
      final signature = await ref
          .read(doctorProfileProvider.notifier)
          .signatureBytes();
      await ref
          .read(prescriptionPdfServiceProvider)
          .shareAsFile(
            visit: visit,
            patient: _patient,
            doctor: ref.read(doctorProfileValueProvider),
            signaturePng: signature,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.couldNotSharePrescription}: '
              '${failureText(AppLocalizations.of(context)!, e)}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busyVisitId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0.5,
        title: Text(
          _patient?.name ?? t.patientFallback,
          style: AppTypography.titleMedium.copyWith(color: scheme.onSurface),
        ),
        actions: [
          if (_patient != null)
            IconButton(
              key: const Key('edit_patient_button'),
              tooltip: t.editPatientDetails,
              icon: const Icon(Icons.edit_rounded),
              onPressed: _editPatient,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _patient == null
          ? EmptyState(title: t.patientNotFound, icon: Icons.person_off_rounded)
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                children: [
                  _PatientHeader(
                    patient: _patient!,
                    visitCount: _visits.length,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _StartConsultationButton(
                    onTap: () => context.push(
                      '${AppRoute.intakeForm.path}?patientId=${widget.patientId}',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    t.consultationHistory,
                    style: AppTypography.titleMedium.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  if (_visits.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xl),
                      child: EmptyState(
                        title: t.noConsultationsYet,
                        message: t.visitsWillAppearHere,
                        icon: Icons.timeline_rounded,
                      ),
                    )
                  else
                    for (final v in _visits) ...[
                      _VisitCard(
                        visit: v,
                        attachmentsDir: ref.watch(attachmentsDirProvider),
                        busy: _busyVisitId == v.id,
                        onView: () => _openPdf(v),
                        onShare: () => _sharePdf(v),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                ],
              ),
            ),
    );
  }
}

// ── Start new consultation CTA ────────────────────────────────────────────────

class _StartConsultationButton extends StatelessWidget {
  const _StartConsultationButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_kBlue600, _kTeal500]),
          borderRadius: AppSpacing.radiusLg,
          boxShadow: const [
            BoxShadow(
              color: Color(0x4D2563EB),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mic_rounded, color: Colors.white, size: 20),
            const SizedBox(width: AppSpacing.s),
            Text(
              AppLocalizations.of(context)!.startNewConsultationCta,
              style: AppTypography.titleSmall.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Patient header ──────────────────────────────────────────────────────────

class _PatientHeader extends StatelessWidget {
  const _PatientHeader({required this.patient, required this.visitCount});
  final PatientProfile patient;
  final int visitCount;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final ageSex = [
      if (patient.age != null) '${patient.age} ${t.years}',
      _sexLabel(t, patient.sex),
    ].where((s) => s != '—').join(' • ');

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kBlue600, _kTeal500],
        ),
        borderRadius: AppSpacing.radiusXl,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: _kBlue600, size: 30),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  style: AppTypography.headlineMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
                if (ageSex.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    ageSex,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
                if (patient.whatsappNumber != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_rounded,
                        size: 12,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '+91 ${patient.whatsappNumber}',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$visitCount ${visitCount == 1 ? t.consultationOne : t.consultationMany}',
                  style: AppTypography.labelSmall.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _sexLabel(AppLocalizations t, Sex? sex) {
    switch (sex) {
      case Sex.male:
        return t.male;
      case Sex.female:
        return t.female;
      case Sex.other:
        return t.other;
      case null:
        return '—';
    }
  }
}

// ── Visit card ──────────────────────────────────────────────────────────────

class _VisitCard extends StatelessWidget {
  const _VisitCard({
    required this.visit,
    required this.attachmentsDir,
    required this.busy,
    required this.onView,
    required this.onShare,
  });

  final VisitRecord visit;

  /// The signed-in doctor's report folder; null when nobody is signed in.
  final String? attachmentsDir;
  final bool busy;
  final VoidCallback onView;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = AppLocalizations.of(context)!;
    final insight = visit.insight ?? MedicalInsight.empty;
    final meds = insight.medications;
    final signedGreen = isDark
        ? const Color(0xFF4ADE80)
        : const Color(0xFF16A34A);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppSpacing.radiusXl,
        border: Border.all(color: scheme.outline),
        boxShadow: isDark ? AppColors.cardShadowDark : AppColors.cardShadow,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date + signed status
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 14, color: _kBlue600),
              const SizedBox(width: AppSpacing.xs),
              // Expanded, not Text + Spacer: a long date beside the Signed
              // chip overflowed the row on narrow phones.
              Expanded(
                child: Text(
                  _formatDateTime(visit.createdAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (visit.signed)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0D3D2E)
                        : const Color(0xFFF0FDF4),
                    borderRadius: AppSpacing.radiusSm,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 12,
                        color: signedGreen,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        t.signed,
                        style: AppTypography.labelSmall.copyWith(
                          color: signedGreen,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          if (insight.consultationSummary.trim().isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.s),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: AppSpacing.radiusMd,
              ),
              child: Text(
                insight.consultationSummary,
                style: AppTypography.bodySmall.copyWith(
                  color: scheme.onPrimaryContainer,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s),
          ] else ...[
            if (insight.diagnosis.trim().isNotEmpty)
              _line(context, t.diagnosisLabel, insight.diagnosis),
            if (insight.symptoms.isNotEmpty)
              _line(context, t.symptomsLabel, insight.symptoms.join(', ')),
          ],
          // Medicines
          const SizedBox(height: AppSpacing.s),
          Text(
            t.medicinesLabel,
            style: AppTypography.titleSmall.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (meds.isEmpty)
            Text(
              t.noMedicinesRecorded,
              style: AppTypography.bodySmall.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          else
            for (final m in meds)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.medication_rounded,
                        size: 14,
                        color: _kTeal500,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        _medLine(m.name, m.dosage, m.frequency, m.duration),
                        style: AppTypography.bodySmall.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          if (insight.followUpDays != null && insight.followUpDays! > 0) ...[
            const SizedBox(height: AppSpacing.s),
            _line(
              context,
              t.followUpLabel,
              insight.followUpDays == 1
                  ? t.afterDaysOne
                  : t.afterDaysMany(insight.followUpDays!),
            ),
          ],
          _ReportsStrip(
            attachments: visit.attachments,
            attachmentsDir: attachmentsDir,
          ),
          const SizedBox(height: AppSpacing.md),
          // Actions
          Row(
            children: [
              Expanded(
                child: _PdfButton(
                  label: busy ? t.opening : t.viewPrescription,
                  icon: Icons.picture_as_pdf_rounded,
                  filled: true,
                  onTap: busy ? null : onView,
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              _PdfButton(
                label: t.share,
                icon: Icons.share_rounded,
                filled: false,
                onTap: busy ? null : onShare,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(BuildContext context, String label, String value) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
      child: RichText(
        text: TextSpan(
          style: AppTypography.bodySmall.copyWith(color: color),
          children: [
            TextSpan(
              text: '$label: ',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  static String _medLine(String name, String dosage, String freq, String dur) {
    return [
      name,
      dosage,
      freq,
      dur,
    ].where((s) => s.trim().isNotEmpty).join(' · ');
  }

  static String _formatDateTime(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} • $time';
  }
}

// ── Reports attached to a visit ─────────────────────────────────────────────

/// The report photos attached to a visit (roadmap item 17). They were printed
/// in the prescription PDF but invisible in the history, so checking last
/// month's blood report meant opening that visit's PDF and paging to the end.
///
/// A photo whose file is gone (restored backup without it, cleared storage) is
/// left out, as the PDF does; with none left the strip takes no space.
class _ReportsStrip extends StatelessWidget {
  const _ReportsStrip({
    required this.attachments,
    required this.attachmentsDir,
  });

  final List<ReportAttachment> attachments;
  final String? attachmentsDir;

  @override
  Widget build(BuildContext context) {
    final dir = attachmentsDir;
    final reports = <({File file, String caption})>[];
    for (var i = 0; i < attachments.length; i++) {
      final a = attachments[i];
      final file = File(
        dir == null
            ? a.path
            : AppPaths.resolveAttachment(a.path, attachmentsDir: dir),
      );
      if (!file.existsSync()) continue;
      final t = AppLocalizations.of(context)!;
      reports.add((
        file: file,
        caption: a.caption.trim().isEmpty
            ? t.pdfReportCaption(i + 1)
            : a.caption.trim(),
      ));
    }
    if (reports.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.pdfPreviousReports,
            style: AppTypography.labelSmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: reports.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s),
              itemBuilder: (context, i) {
                final r = reports[i];
                return Semantics(
                  button: true,
                  label: r.caption,
                  child: GestureDetector(
                    key: Key('report_thumb_$i'),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            _ReportViewer(file: r.file, caption: r.caption),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: AppSpacing.radiusMd,
                      child: Image.file(
                        r.file,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        // Decode at thumbnail size: a phone photo is several
                        // thousand pixels wide and the list may hold many.
                        cacheWidth: 216,
                        errorBuilder: (_, _, _) => Container(
                          width: 72,
                          height: 72,
                          color: scheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// One report, full screen, with pinch to zoom.
class _ReportViewer extends StatelessWidget {
  const _ReportViewer({required this.file, required this.caption});

  final File file;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(caption, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Center(
        child: InteractiveViewer(
          maxScale: 6,
          child: Image.file(
            file,
            errorBuilder: (_, _, _) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white54,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }
}

class _PdfButton extends StatelessWidget {
  const _PdfButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: disabled ? 0.6 : 1,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            gradient: filled
                ? const LinearGradient(colors: [_kBlue600, _kTeal500])
                : null,
            color: filled ? null : Theme.of(context).colorScheme.surface,
            borderRadius: AppSpacing.radiusLg,
            border: filled
                ? null
                : Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: 1.5,
                  ),
          ),
          child: Row(
            // min + a loose Flexible label: legal both when the button is
            // Expanded (bounded, the label may ellipsize) and when it sizes
            // itself to its content (unbounded, the label takes what it needs).
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: filled
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.s),
              // Two buttons share the row, so each label has about 90 dp on
              // a 360 dp phone: "Share on WhatsApp" and its translations did
              // not fit and were clipped mid-letter.
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSmall.copyWith(
                    color: filled
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
