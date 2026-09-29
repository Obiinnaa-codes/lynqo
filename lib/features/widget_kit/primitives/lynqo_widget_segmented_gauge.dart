import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/lynqo_widget_theme.dart';

class LynqoWidgetSegmentedGauge extends StatelessWidget {
  const LynqoWidgetSegmentedGauge({
    super.key,
    required this.progress,
    required this.diameter,
    this.center,
    this.segmentCount = 24,
  });

  final double progress;
  final double diameter;
  final Widget? center;
  final int segmentCount;

  @override
  Widget build(BuildContext context) {
    final theme = LynqoWidgetTheme.of(context);
    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(diameter, diameter),
            painter: _SegmentedGaugePainter(
              progress: progress.clamp(0.0, 1.0),
              activeColor: theme.accentRing,
              inactiveColor: theme.chartBarInactive,
              highlightColor: theme.accentHighlight,
              segmentCount: segmentCount,
            ),
          ),
          if (center != null) center!,
        ],
      ),
    );
  }
}

class _SegmentedGaugePainter extends CustomPainter {
  _SegmentedGaugePainter({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
    required this.highlightColor,
    required this.segmentCount,
  });

  final double progress;
  final Color activeColor;
  final Color inactiveColor;
  final Color highlightColor;
  final int segmentCount;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 4;
    const startAngle = math.pi * 0.75;
    const sweep = math.pi * 1.5;
    final activeSegments = (segmentCount * progress).round();

    for (var i = 0; i < segmentCount; i++) {
      final t = i / (segmentCount - 1);
      final angle = startAngle + sweep * t;
      final isActive = i < activeSegments;
      final paint = Paint()
        ..color = isActive
            ? Color.lerp(activeColor, highlightColor, t) ?? activeColor
            : inactiveColor
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;

      final inner = center + Offset(math.cos(angle), math.sin(angle)) * (radius - 8);
      final outer = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawLine(inner, outer, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentedGaugePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
