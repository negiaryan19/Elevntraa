import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/theme/app_colors.dart';

/// Scrolling-bars visualiser fed by the real mic amplitude stream.
/// Each amplitude tick (~10/sec) appends one bar; old bars fall off the
/// left edge. Heights interpolate smoothly between ticks so the motion
/// doesn't look stepped.
class LiveWaveform extends StatefulWidget {
  const LiveWaveform({
    super.key,
    required this.amplitudeStream,
    this.barCount = 48,
    this.height = 96,
    this.active = true,
  });

  final Stream<double> amplitudeStream;
  final int barCount;
  final double height;
  final bool active;

  @override
  State<LiveWaveform> createState() => _LiveWaveformState();
}

class _LiveWaveformState extends State<LiveWaveform>
    with SingleTickerProviderStateMixin {
  late final ListQueue<double> _bars = ListQueue.from(
    List<double>.filled(widget.barCount, 0.04),
  );
  late final Ticker _ticker;
  StreamSubscription<double>? _sub;
  double _current = 0.04;
  double _target = 0.04;

  @override
  void initState() {
    super.initState();
    _sub = widget.amplitudeStream.listen(_onAmp);
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didUpdateWidget(covariant LiveWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.amplitudeStream != widget.amplitudeStream) {
      _sub?.cancel();
      _sub = widget.amplitudeStream.listen(_onAmp);
    }
  }

  void _onAmp(double v) {
    // Add a floor so the line never collapses to a flat zero in silence.
    _target = (v * 0.96 + 0.04).clamp(0.04, 1.0);
  }

  // Called once per frame. Smoothly interpolates the head bar toward the
  // latest amplitude target; every ~100ms we push the head into the queue
  // and start a new bar so the visual scrolls left.
  Duration _lastPush = Duration.zero;
  void _onTick(Duration elapsed) {
    _current = _current + (_target - _current) * 0.25;

    if (elapsed - _lastPush >= const Duration(milliseconds: 90)) {
      _bars.removeFirst();
      _bars.addLast(_current);
      _lastPush = elapsed;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: CustomPaint(
        painter: _WavePainter(
          bars: _bars.toList(growable: false),
          active: widget.active,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({required this.bars, required this.active});

  final List<double> bars;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;
    final n = bars.length;
    final slot = size.width / n;
    final barW = slot * 0.55;
    final radius = Radius.circular(barW / 2);

    final baseColor = active ? AppColors.primary : AppColors.outlineStrong;

    for (var i = 0; i < n; i++) {
      final h = (bars[i].clamp(0.04, 1.0)) * size.height;
      final x = slot * i + (slot - barW) / 2;
      final top = (size.height - h) / 2;

      final alpha = (0.35 + 0.65 * (i / (n - 1))).clamp(0.0, 1.0);
      final paint = Paint()..color = baseColor.withValues(alpha: alpha);

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barW, h),
        radius,
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) =>
      old.bars != bars || old.active != active;
}
