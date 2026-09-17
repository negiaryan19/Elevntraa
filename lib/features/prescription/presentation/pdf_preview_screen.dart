import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/repositories/patient_repository.dart';
import '../../../data/repositories/visit_repository.dart';
import '../../../domain/models/visit.dart';
import '../../../core/errors/failure_text.dart';
import '../../../l10n/app_localizations.dart';
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
  bool _loading = true;
  bool _busy = false;
  Uint8List? _pdfBytes;
  String? _pdfFileName;
  List<Uint8List> _pageImages = [];

  final TransformationController _transformationController =
      TransformationController();
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onTransformChanged);
    _load();
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

  Future<void> _load() async {
    final v = await ref.read(visitRepositoryProvider).byId(widget.visitId);
    final p = v == null
        ? null
        : await ref.read(patientRepositoryProvider).byId(v.patientId);
    if (!mounted) return;

    Uint8List? bytes;
    String? fname;
    if (v != null) {
      try {
        final svc = ref.read(prescriptionPdfServiceProvider);
        final doctor = ref.read(doctorProfileValueProvider);
        final signature = await ref
            .read(doctorProfileProvider.notifier)
            .signatureBytes();
        if (!mounted) return;
        bytes = await svc.build(
          visit: v,
          patient: p,
          doctor: doctor,
          signaturePng: signature,
          awaitingSignatureLabel: AppLocalizations.of(
            context,
          )!.pdfAwaitingSignature,
        );
        fname = svc.fileName(p, v);
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _visit = v;
        _pdfBytes = bytes;
        _pdfFileName = fname;
        _loading = false;
      });
    }

    // Use the local bytes, not the field: if the screen was unmounted while
    // the PDF was building, the field was never set and `_pdfBytes!` throws.
    if (bytes != null && mounted) await _rasterizePages(bytes);
  }

  Future<void> _rasterizePages(Uint8List bytes) async {
    final images = <Uint8List>[];
    await for (final page in Printing.raster(bytes, dpi: 200)) {
      if (!mounted) return;
      final png = await page.toPng();
      images.add(png);
    }
    if (mounted) setState(() => _pageImages = images);
  }

  Future<void> _share() async {
    if (_pdfBytes == null || _busy) return;
    setState(() => _busy = true);
    try {
      await Printing.sharePdf(
        bytes: _pdfBytes!,
        filename: _pdfFileName ?? 'Prescription.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.couldNotSharePdf}: '
              '${failureText(AppLocalizations.of(context)!, e)}',
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
    final t = AppLocalizations.of(context)!;
    if (_loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(t.generatingPdfLong),
            ],
          ),
        ),
      );
    }
    if (_visit == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t.prescriptionFallback)),
        body: EmptyState(
          title: t.visitNotFound,
          icon: Icons.search_off_rounded,
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                            t.prescriptionReady,
                            style: AppTypography.headlineMedium.copyWith(
                              color: scheme.onSurface,
                            ),
                          ),
                          Text(
                            t.reviewAndShare,
                            style: AppTypography.bodySmall.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => context.go('/'),
                      icon: const Icon(Icons.home_rounded, size: 18),
                      label: Text(t.navHome),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _StepProgressBar(activeStep: 3),
              ),
              const SizedBox(height: AppSpacing.s),
              // PDF preview — shows the exact PDF that will be shared.
              // The page itself stays white (it is printable paper); only the
              // surrounding area follows the theme.
              Expanded(
                child: _pdfBytes == null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 40,
                              color: scheme.error,
                            ),
                            const SizedBox(height: 12),
                            Text(t.couldNotGeneratePdf),
                          ],
                        ),
                      )
                    : _pageImages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 12),
                            Text(t.generatingPrescription),
                          ],
                        ),
                      )
                    : InteractiveViewer(
                        transformationController: _transformationController,
                        minScale: 1.0,
                        maxScale: 5.0,
                        boundaryMargin: EdgeInsets.zero,
                        constrained: false,
                        panEnabled: _currentScale > 1.01,
                        scaleEnabled: true,
                        child: Container(
                          color: isDark
                              ? const Color(0xFF13162A)
                              : Colors.grey.shade200,
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
                                        color: Colors.black.withValues(
                                          alpha: 0.15,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Image.memory(
                                    _pageImages[i],
                                    fit: BoxFit.contain,
                                    width:
                                        MediaQuery.of(context).size.width - 32,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
              ),
              // Sticky share bar
              _ShareBar(busy: _busy, onShare: _share),
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
                color: i <= activeStep ? _kTeal600 : scheme.onSurfaceVariant,
                fontWeight: i == activeStep ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

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
          _GradientCta(
            label: busy ? t.preparingPdf : t.shareOnWhatsapp,
            icon: Icons.share_rounded,
            colors: [const Color(0xFF16A34A), const Color(0xFF10B981)],
            shadowColor: const Color(0x4D16A34A),
            onTap: busy ? null : onShare,
          ),
          const SizedBox(height: AppSpacing.s),
          _OutlineCta(
            label: t.shareViaOtherApps,
            icon: Icons.ios_share_rounded,
            onTap: busy ? null : onShare,
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

class _OutlineCta extends StatelessWidget {
  const _OutlineCta({
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
