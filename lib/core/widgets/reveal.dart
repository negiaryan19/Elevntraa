import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Entrance animation: content rises from below while sharpening from a
/// blur into focus. Pass a unique [Key] (e.g. ValueKey(routeLocation)) when
/// you need it to replay on navigation.
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.durationMs = 520,
  });

  final Widget child;
  final int delayMs;
  final int durationMs;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.durationMs),
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) {
        final v = _t.value;
        final dy = (1 - v) * 44;
        final blur = (1 - v) * 9;
        Widget result = child!;
        if (blur > 0.2) {
          result = ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: result,
          );
        }
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, dy), child: result),
        );
      },
    );
  }
}
