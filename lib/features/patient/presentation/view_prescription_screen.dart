import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/patient.dart';
import '../../../domain/models/visit.dart';
import '../../../l10n/app_localizations.dart';
import '../../prescription/data/prescription_pdf_service.dart';
import '../../settings/data/doctor_profile_repository.dart';

class ViewPrescriptionScreen extends ConsumerStatefulWidget {
  const ViewPrescriptionScreen({
    super.key,
    required this.visit,
    required this.patient,
  });

  final VisitRecord visit;
  final PatientProfile? patient;

  @override
  ConsumerState<ViewPrescriptionScreen> createState() =>
      _ViewPrescriptionScreenState();
}

class _ViewPrescriptionScreenState
    extends ConsumerState<ViewPrescriptionScreen> {
  Uint8List? _pdfBytes;
  List<Uint8List> _pageImages = [];
  bool _busy = false;
  bool _hasError = false;

  final TransformationController _transformationController =
      TransformationController();
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onTransformChanged);
    _generate();
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if ((scale - _currentScale).abs() > 0.01) {
      setState(() => _currentScale = scale);
    }
  }

  Future<void> _generate() async {
    try {
      final svc = ref.read(prescriptionPdfServiceProvider);
      final doctor = ref.read(doctorProfileControllerProvider);
      final bytes = await svc.build(
        visit: widget.visit,
        patient: widget.patient,
        doctor: doctor,
      );
      if (!mounted) return;
      setState(() => _pdfBytes = bytes);
      await _rasterize(bytes);
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  Future<void> _rasterize(Uint8List bytes) async {
    final images = <Uint8List>[];
    await for (final page in Printing.raster(bytes, dpi: 200)) {
      images.add(await page.toPng());
    }
    if (mounted) setState(() => _pageImages = images);
  }

  Future<void> _share() async {
    if (_pdfBytes == null || _busy) return;
    setState(() => _busy = true);
    try {
      final svc = ref.read(prescriptionPdfServiceProvider);
      await Printing.sharePdf(
        bytes: _pdfBytes!,
        filename: svc.fileName(widget.patient, widget.visit),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.couldNotSharePdf}: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context)!;
    final dt = widget.visit.createdAt;
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
    final dateLabel = '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    final title =
        '${widget.patient?.name ?? t.prescriptionFallback} · $dateLabel';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0.5,
        title: Text(
          title,
          style: AppTypography.titleMedium.copyWith(color: scheme.onSurface),
        ),
        actions: [
          if (widget.patient != null)
            IconButton(
              tooltip: t.newConsultationTooltip,
              icon: const Icon(Icons.add_rounded),
              onPressed: () => context.push(
                '${AppRoute.intakeForm.path}?patientId=${widget.patient!.id}',
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildPreview(context)),
            _ShareBar(busy: _busy, onShare: _share),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 40, color: scheme.error),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.couldNotGeneratePrescription,
              style: AppTypography.bodyMedium.copyWith(color: scheme.onSurface),
            ),
          ],
        ),
      );
    }
    if (_pageImages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context)!.generatingPrescription),
          ],
        ),
      );
    }
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 1.0,
      maxScale: 5.0,
      boundaryMargin: EdgeInsets.zero,
      constrained: false,
      panEnabled: _currentScale > 1.01,
      scaleEnabled: true,
      child: Container(
        // Surround follows the theme; the page itself stays white below.
        color: isDark ? const Color(0xFF13162A) : Colors.grey.shade200,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (int i = 0; i < _pageImages.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Image.memory(
                  _pageImages[i],
                  fit: BoxFit.contain,
                  width: MediaQuery.of(context).size.width - 32,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Bottom share bar ──────────────────────────────────────────────────────────

class _ShareBar extends StatelessWidget {
  const _ShareBar({required this.busy, required this.onShare});
  final bool busy;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context)!;
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
          _GradientBtn(
            label: busy ? t.preparingPdf : t.shareOnWhatsapp,
            icon: Icons.share_rounded,
            colors: const [Color(0xFF16A34A), Color(0xFF10B981)],
            shadowColor: const Color(0x4D16A34A),
            onTap: busy ? null : onShare,
          ),
          const SizedBox(height: AppSpacing.s),
          _OutlineBtn(
            label: t.shareViaOtherApps,
            icon: Icons.ios_share_rounded,
            onTap: busy ? null : onShare,
          ),
        ],
      ),
    );
  }
}

class _GradientBtn extends StatelessWidget {
  const _GradientBtn({
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
            BoxShadow(
              color: shadowColor,
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: AppSpacing.m),
            Flexible(
              child: Text(
                label,
                style: AppTypography.titleSmall.copyWith(color: Colors.white),
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

class _OutlineBtn extends StatelessWidget {
  const _OutlineBtn({
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
