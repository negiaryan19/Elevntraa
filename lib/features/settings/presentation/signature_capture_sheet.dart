import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';

const _kBlue600 = Color(0xFF2563EB);
const _kTeal500 = Color(0xFF14B8A6);

/// Export size of a drawn signature: a 3:1 box the PDF fits into ~170x55 pt.
const _kExportWidth = 900;
const _kExportHeight = 300;
const _kExportMargin = 24.0;

/// Bottom sheet that captures the doctor's signature either by drawing it
/// (finger, stylus or mouse) or by uploading a PNG/JPEG. Resolves with PNG
/// bytes (uploads are re-encoded to PNG so the stored file, the bucket
/// content-type and the PDF embed all agree) or null when dismissed.
class SignatureCaptureSheet extends StatefulWidget {
  const SignatureCaptureSheet({super.key});

  static Future<Uint8List?> show(BuildContext context) {
    return showModalBottomSheet<Uint8List>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Root navigator so the barrier covers the bottom nav too (same reason
      // as the profile sheet).
      useRootNavigator: true,
      builder: (_) => const SignatureCaptureSheet(),
    );
  }

  @override
  State<SignatureCaptureSheet> createState() => _SignatureCaptureSheetState();
}

enum _Mode { draw, upload }

class _SignatureCaptureSheetState extends State<SignatureCaptureSheet> {
  _Mode _mode = _Mode.draw;
  late final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
    strokeCap: StrokeCap.round,
    strokeJoin: StrokeJoin.round,
    onDrawStart: _clearError,
  );
  Uint8List? _uploaded;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_error != null && mounted) setState(() => _error = null);
  }

  void _clear() {
    setState(() {
      _error = null;
      if (_mode == _Mode.draw) {
        _controller.clear();
      } else {
        _uploaded = null;
      }
    });
  }

  bool get _canUse => switch (_mode) {
    _Mode.draw => true,
    _Mode.upload => _uploaded != null,
  };

  Future<void> _use() async {
    if (_busy) return;
    final t = AppLocalizations.of(context)!;
    if (_mode == _Mode.draw && _controller.isEmpty) {
      setState(() => _error = t.signatureEmptyError);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    Uint8List? bytes;
    try {
      bytes = _mode == _Mode.draw ? await _exportDrawing() : _uploaded;
    } catch (_) {
      bytes = null;
    }
    if (!mounted) return;
    if (bytes == null || bytes.isEmpty) {
      setState(() {
        _busy = false;
        _error = _mode == _Mode.draw
            ? t.signatureEmptyError
            : t.signatureLoadFailed;
      });
      return;
    }
    Navigator.of(context).pop(bytes);
  }

  /// Renders the strokes into a fixed 900x300 transparent PNG, scaled so the
  /// signature fills the box (with a margin) regardless of how large the
  /// doctor drew it on screen. Rendering from the points — rather than
  /// `toPngBytes(width, height)`, which pastes the on-screen pixels
  /// unscaled into the box — keeps a small signature crisp when printed.
  Future<Uint8List?> _exportDrawing() async {
    final points = _controller.points;
    if (points.isEmpty) return null;
    final strokes = _controller.pointsToStrokes(1);
    final pen = _controller.penStrokeWidth;

    var minX = double.infinity, minY = double.infinity;
    var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final p in points) {
      minX = math.min(minX, p.offset.dx);
      minY = math.min(minY, p.offset.dy);
      maxX = math.max(maxX, p.offset.dx);
      maxY = math.max(maxY, p.offset.dy);
    }
    final bw = math.max(maxX - minX + pen, 1.0);
    final bh = math.max(maxY - minY + pen, 1.0);
    final scale = math
        .min(
          (_kExportWidth - 2 * _kExportMargin) / bw,
          (_kExportHeight - 2 * _kExportMargin) / bh,
        )
        .clamp(0.25, 4.0);
    final dx = (_kExportWidth - bw * scale) / 2 - (minX - pen / 2) * scale;
    final dy = (_kExportHeight - bh * scale) / 2 - (minY - pen / 2) * scale;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..translate(dx, dy)
      ..scale(scale, scale);
    final paint = Paint()
      ..color = _controller.penColor
      ..strokeWidth = pen
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;
    final dot = Paint()
      ..color = _controller.penColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    for (final stroke in strokes) {
      if (stroke.length > 1) {
        final path = Path()
          ..moveTo(stroke.first.offset.dx, stroke.first.offset.dy);
        for (final p in stroke.skip(1)) {
          path.lineTo(p.offset.dx, p.offset.dy);
        }
        canvas.drawPath(path, paint);
      } else {
        canvas.drawCircle(stroke.first.offset, pen / 2, dot);
      }
    }
    final image = await recorder.endRecording().toImage(
      _kExportWidth,
      _kExportHeight,
    );
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  Future<void> _pickImage() async {
    if (_busy) return;
    final t = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 92,
      );
      if (picked == null) return;
      final raw = await picked.readAsBytes();
      if (!_isPngOrJpeg(raw)) {
        if (mounted) setState(() => _error = t.signatureUnsupportedFormat);
        return;
      }
      final png = await _toPng(raw);
      if (!mounted) return;
      setState(() => _uploaded = png);
    } catch (_) {
      if (mounted) setState(() => _error = t.signatureLoadFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static bool _isPngOrJpeg(Uint8List b) {
    if (b.length < 4) return false;
    final png = b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47;
    final jpeg = b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF;
    return png || jpeg;
  }

  /// Decodes with the platform codec and re-encodes as PNG (a JPEG passes
  /// through unchanged in content, only the container changes).
  static Future<Uint8List> _toPng(Uint8List raw) async {
    final codec = await ui.instantiateImageCodec(raw);
    final frame = await codec.getNextFrame();
    try {
      final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('PNG encode failed');
      return data.buffer.asUint8List();
    } finally {
      frame.image.dispose();
      codec.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context)!;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                t.signatureTitle,
                style: AppTypography.headlineMedium.copyWith(
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                t.signatureSubtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<_Mode>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: _Mode.draw,
                      icon: const Icon(Icons.draw_rounded, size: 18),
                      label: Text(t.signatureDraw),
                    ),
                    ButtonSegment(
                      value: _Mode.upload,
                      icon: const Icon(Icons.upload_rounded, size: 18),
                      label: Text(t.signatureUpload),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: _busy
                      ? null
                      : (s) => setState(() {
                          _mode = s.first;
                          _error = null;
                        }),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_mode == _Mode.draw)
                _DrawPad(controller: _controller, hint: t.signatureHint)
              else
                _UploadPad(
                  bytes: _uploaded,
                  busy: _busy,
                  hint: t.signatureUploadHint,
                  chooseLabel: _uploaded == null
                      ? t.signatureChooseImage
                      : t.signatureChangeImage,
                  onChoose: _pickImage,
                ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.s),
                Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 16,
                      color: scheme.error,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        _error!,
                        style: AppTypography.bodySmall.copyWith(
                          color: scheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _clear,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(t.signatureClear),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: _GradientButton(
                      label: t.signatureUse,
                      busy: _busy,
                      onTap: _busy || !_canUse ? null : _use,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// White "paper" the doctor signs on, with a baseline and a hint beneath it.
class _DrawPad extends StatelessWidget {
  const _DrawPad({required this.controller, required this.hint});
  final SignatureController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const height = 200.0;
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: scheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Baseline + hint sit under the canvas so they never intercept
          // pointer events.
          IgnorePointer(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  const Spacer(),
                  Container(height: 1, color: const Color(0xFFCBD5E1)),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    hint,
                    textAlign: TextAlign.center,
                    style: AppTypography.labelSmall.copyWith(
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                ],
              ),
            ),
          ),
          Signature(
            controller: controller,
            height: height,
            backgroundColor: Colors.transparent,
          ),
        ],
      ),
    );
  }
}

class _UploadPad extends StatelessWidget {
  const _UploadPad({
    required this.bytes,
    required this.busy,
    required this.hint,
    required this.chooseLabel,
    required this.onChoose,
  });
  final Uint8List? bytes;
  final bool busy;
  final String hint;
  final String chooseLabel;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: bytes == null ? scheme.surfaceContainerLow : Colors.white,
            borderRadius: AppSpacing.radiusLg,
            border: Border.all(color: scheme.outline),
          ),
          clipBehavior: Clip.antiAlias,
          child: bytes == null
              ? Center(
                  child: busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.image_outlined,
                          size: 36,
                          color: scheme.onSurfaceVariant,
                        ),
                )
              : Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Image.memory(
                    bytes!,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.s),
        Text(
          hint,
          style: AppTypography.bodySmall.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: busy ? null : onChoose,
            icon: const Icon(Icons.photo_library_outlined, size: 18),
            label: Text(chooseLabel),
          ),
        ),
      ],
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.busy,
    required this.onTap,
  });
  final String label;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_kBlue600, _kTeal500]),
            borderRadius: AppSpacing.radiusMd,
            boxShadow: enabled
                ? const [
                    BoxShadow(
                      color: Color(0x4D2563EB),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              else
                const Icon(Icons.check_rounded, color: Colors.white, size: 20),
              const SizedBox(width: AppSpacing.s),
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
      ),
    );
  }
}
