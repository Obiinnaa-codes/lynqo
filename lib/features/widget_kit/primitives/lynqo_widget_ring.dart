import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/lynqo_widget_theme.dart';

class LynqoWidgetRing extends StatelessWidget {
  const LynqoWidgetRing({
    super.key,
    required this.progress,
    required this.diameter,
    this.strokeWidth = 5,
    this.progressColor,
    this.center,
    this.fullCircle = false,
  });

  /// 0.0 – 1.0
  final double progress;
  final double diameter;
  final double strokeWidth;
  final Color? progressColor;
  final Widget? center;

  /// When true, draws a closed 360° ring (no arc gap). Battery/data use the default arc.
  final bool fullCircle;

  @override
  Widget build(BuildContext context) {
    final theme = LynqoWidgetTheme.of(context);
    final clamped = progress.clamp(0.0, 1.0);

    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(diameter, diameter),
            painter: _RingPainter(
              progress: clamped,
              color: progressColor ?? theme.accentRing,
              trackColor: theme.isDark
                  ? theme.chartBarInactive
                  : theme.chartBarInactive,
              strokeWidth: strokeWidth,
              fullCircle: fullCircle,
            ),
          ),
          ?center,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
    required this.fullCircle,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;
  final bool fullCircle;

  static const double _arcGapFraction = 0.94;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final start = -math.pi / 2;
    final arcFraction = fullCircle ? 1.0 : _arcGapFraction;
    final sweepMax = math.pi * 2 * arcFraction;
    final sweep = sweepMax * progress;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect.deflate(strokeWidth), start, sweepMax, false, track);
    if (progress > 0) {
      canvas.drawArc(rect.deflate(strokeWidth), start, sweep, false, arc);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.fullCircle != fullCircle;
  }
}
