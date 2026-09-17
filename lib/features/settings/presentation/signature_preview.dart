import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../data/doctor_profile_repository.dart';

/// Shows the signed-in doctor's current signature image (as it will print on
/// the prescription) or a dashed "No signature yet" placeholder.
///
/// Reads the PNG from disk through the profile controller and re-reads it
/// whenever `signatureUpdatedAt` changes, so a freshly drawn or uploaded
/// signature appears immediately. The card is always white: a signature is
/// black ink on paper and must look the same in dark mode as on the PDF.
class SignaturePreview extends ConsumerWidget {
  const SignaturePreview({super.key, this.height = 120});

  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(doctorProfileValueProvider);
    final scheme = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context)!;

    if (!profile.hasSignature) {
      return _Placeholder(height: height, label: t.signatureNone);
    }

    final key = ValueKey(
      '${profile.signatureFileName}|${profile.signatureUpdatedAt?.toIso8601String()}',
    );
    return FutureBuilder<Uint8List?>(
      key: key,
      future: ref.read(doctorProfileProvider.notifier).signatureBytes(),
      builder: (context, snap) {
        final bytes = snap.data;
        if (snap.connectionState != ConnectionState.done) {
          return _Frame(
            height: height,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        if (bytes == null || bytes.isEmpty) {
          return _Placeholder(height: height, label: t.signatureNone);
        }
        return _Frame(
          height: height,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Image.memory(
              bytes,
              key: key,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => Center(
                child: Text(
                  t.signatureNone,
                  style: AppTypography.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.height, required this.child});
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: scheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.height, required this.label});
  final double height;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _DashedBorderPainter(color: scheme.outlineVariant, radius: 16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.draw_rounded,
                size: 26,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.7, 0.7, size.width - 1.4, size.height - 1.4),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rect);
    const dash = 6.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
