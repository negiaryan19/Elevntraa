import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/repositories/patient_repository.dart';
import '../../../data/repositories/visit_repository.dart';
import '../../../domain/models/medical_insight.dart';
import '../../../domain/models/patient.dart';
import '../../../domain/models/visit.dart';
import '../../prescription/data/prescription_pdf_service.dart';
import '../../settings/data/doctor_profile_repository.dart';

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
    final patient =
        await ref.read(patientRepositoryProvider).byId(widget.patientId);
    final visits =
        await ref.read(visitRepositoryProvider).forPatient(widget.patientId);
    if (mounted) {
      setState(() {
        _patient = patient;
        _visits = visits;
        _loading = false;
      });
    }
  }

  Future<void> _openPdf(VisitRecord visit) async {
    if (_busyVisitId != null) return;
    setState(() => _busyVisitId = visit.id);
    try {
      await ref.read(prescriptionPdfServiceProvider).printOrPreview(
            visit: visit,
            patient: _patient,
            doctor: ref.read(doctorProfileControllerProvider),
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open prescription: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busyVisitId = null);
    }
  }

  Future<void> _sharePdf(VisitRecord visit) async {
    if (_busyVisitId != null) return;
    setState(() => _busyVisitId = visit.id);
    try {
      await ref.read(prescriptionPdfServiceProvider).shareAsFile(
            visit: visit,
            patient: _patient,
            doctor: ref.read(doctorProfileControllerProvider),
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not share prescription: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busyVisitId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
        title: Text(_patient?.name ?? 'Patient',
            style: AppTypography.titleMedium),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _patient == null
              ? const EmptyState(
                  title: 'Patient not found',
                  icon: Icons.person_off_rounded,
                )
              : SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    children: [
                      _PatientHeader(patient: _patient!, visitCount: _visits.length),
                      const SizedBox(height: AppSpacing.md),
                      _StartConsultationButton(
                        onTap: () => context.push(
                          '${AppRoute.intakeForm.path}?patientId=${widget.patientId}',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Consultation History',
                          style: AppTypography.titleMedium),
                      const SizedBox(height: AppSpacing.m),
                      if (_visits.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: AppSpacing.xl),
                          child: EmptyState(
                            title: 'No consultations yet',
                            message:
                                'Records from this patient\'s visits will appear here.',
                            icon: Icons.timeline_rounded,
                          ),
                        )
                      else
                        for (final v in _visits) ...[
                          _VisitCard(
                            visit: v,
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
                color: Color(0x4D2563EB), blurRadius: 14, offset: Offset(0, 6)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mic_rounded, color: Colors.white, size: 20),
            const SizedBox(width: AppSpacing.s),
            Text('Start New Consultation',
                style: AppTypography.titleSmall.copyWith(color: Colors.white)),
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
    final ageSex = [
      if (patient.age != null) '${patient.age} yrs',
      _sexLabel(patient.sex),
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
                Text(patient.name,
                    style: AppTypography.headlineMedium
                        .copyWith(color: Colors.white)),
                if (ageSex.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(ageSex,
                      style: AppTypography.bodySmall
                          .copyWith(color: Colors.white70)),
                ],
                if (patient.whatsappNumber != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Row(
                    children: [
                      const Icon(Icons.phone_rounded,
                          size: 12, color: Colors.white70),
                      const SizedBox(width: AppSpacing.xs),
                      Text('+91 ${patient.whatsappNumber}',
                          style: AppTypography.bodySmall
                              .copyWith(color: Colors.white70)),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                Text(
                    '$visitCount consultation${visitCount == 1 ? '' : 's'}',
                    style: AppTypography.labelSmall
                        .copyWith(color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _sexLabel(Sex? sex) {
    switch (sex) {
      case Sex.male:
        return 'Male';
      case Sex.female:
        return 'Female';
      case Sex.other:
        return 'Other';
      case null:
        return '—';
    }
  }
}

// ── Visit card ──────────────────────────────────────────────────────────────

class _VisitCard extends StatelessWidget {
  const _VisitCard({
    required this.visit,
    required this.busy,
    required this.onView,
    required this.onShare,
  });

  final VisitRecord visit;
  final bool busy;
  final VoidCallback onView;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final insight = visit.insight ?? MedicalInsight.empty;
    final meds = insight.medications;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.radiusXl,
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: AppColors.cardShadow,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date + signed status
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 14, color: _kBlue600),
              const SizedBox(width: AppSpacing.xs),
              Text(_formatDateTime(visit.createdAt),
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
              const Spacer(),
              if (visit.signed)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: AppSpacing.radiusSm,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded,
                          size: 12, color: Color(0xFF16A34A)),
                      const SizedBox(width: AppSpacing.xs),
                      Text('Signed',
                          style: AppTypography.labelSmall
                              .copyWith(color: const Color(0xFF16A34A))),
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
                color: const Color(0xFFEFF6FF),
                borderRadius: AppSpacing.radiusMd,
              ),
              child: Text(
                insight.consultationSummary,
                style: AppTypography.bodySmall.copyWith(
                  color: const Color(0xFF1E3A5F),
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s),
          ] else ...[
            if (insight.diagnosis.trim().isNotEmpty)
              _line('Diagnosis', insight.diagnosis),
            if (insight.symptoms.isNotEmpty)
              _line('Symptoms', insight.symptoms.join(', ')),
          ],
          // Medicines
          const SizedBox(height: AppSpacing.s),
          Text('Medicines', style: AppTypography.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          if (meds.isEmpty)
            Text('No medicines recorded.',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textMuted))
          else
            for (final m in meds)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.medication_rounded,
                          size: 14, color: _kTeal500),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        _medLine(m.name, m.dosage, m.frequency, m.duration),
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
          if (insight.followUpDays != null && insight.followUpDays! > 0) ...[
            const SizedBox(height: AppSpacing.s),
            _line('Follow-up',
                'After ${insight.followUpDays} day${insight.followUpDays == 1 ? '' : 's'}'),
          ],
          const SizedBox(height: AppSpacing.md),
          // Actions
          Row(
            children: [
              Expanded(
                child: _PdfButton(
                  label: busy ? 'Opening…' : 'View Prescription',
                  icon: Icons.picture_as_pdf_rounded,
                  filled: true,
                  onTap: busy ? null : onView,
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              _PdfButton(
                label: 'Share',
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

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
      child: RichText(
        text: TextSpan(
          style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
          children: [
            TextSpan(
                text: '$label: ',
                style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  static String _medLine(String name, String dosage, String freq, String dur) {
    return [name, dosage, freq, dur]
        .where((s) => s.trim().isNotEmpty)
        .join(' · ');
  }

  static String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} • $time';
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
          padding: EdgeInsets.symmetric(
              horizontal: filled ? AppSpacing.md : AppSpacing.md),
          decoration: BoxDecoration(
            gradient: filled
                ? const LinearGradient(colors: [_kBlue600, _kTeal500])
                : null,
            color: filled ? null : Colors.white,
            borderRadius: AppSpacing.radiusLg,
            border: filled
                ? null
                : Border.all(color: const Color(0xFFD1D5DB), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: filled ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: AppSpacing.s),
              Text(label,
                  style: AppTypography.titleSmall.copyWith(
                      color:
                          filled ? Colors.white : AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
