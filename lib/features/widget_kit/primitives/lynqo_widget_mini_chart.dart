import 'package:flutter/material.dart';

import '../theme/lynqo_widget_theme.dart';

class LynqoWidgetMiniChart extends StatelessWidget {
  const LynqoWidgetMiniChart({
    super.key,
    required this.values,
    this.startLabel,
    this.endLabel,
    this.height = 72,
  });

  final List<double> values;
  final String? startLabel;
  final String? endLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = LynqoWidgetTheme.of(context);
    if (values.isEmpty) {
      return const SizedBox.shrink();
    }

    final max = values.reduce((a, b) => a > b ? a : b);
    final average = values.reduce((a, b) => a + b) / values.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          child: CustomPaint(
            painter: _MiniBarChartPainter(
              values: values,
              max: max <= 0 ? 1 : max,
              average: average,
              inactiveColor: theme.chartBarInactive,
              highlightColor: theme.accentHighlight,
              averageColor: theme.accentHighlight.withValues(alpha: 0.8),
            ),
            child: const SizedBox.expand(),
          ),
        ),
        if (startLabel != null || endLabel != null) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(startLabel ?? '', style: theme.captionStyle(fontSize: 11)),
              Text(endLabel ?? '', style: theme.captionStyle(fontSize: 11)),
            ],
          ),
        ],
      ],
    );
  }
}

class _MiniBarChartPainter extends CustomPainter {
  _MiniBarChartPainter({
    required this.values,
    required this.max,
    required this.average,
    required this.inactiveColor,
    required this.highlightColor,
    required this.averageColor,
  });

  final List<double> values;
  final double max;
  final double average;
  final Color inactiveColor;
  final Color highlightColor;
  final Color averageColor;

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / (values.length * 1.8);
    final gap = barWidth * 0.8;
    var x = gap;

    final avgY = size.height - (average / max) * size.height * 0.85;
    final dash = Paint()
      ..color = averageColor
      ..strokeWidth = 1;
    for (var i = 0.0; i < size.width; i += 4) {
      canvas.drawLine(Offset(i, avgY), Offset(i + 2, avgY), dash);
    }

    for (var i = 0; i < values.length; i++) {
      final h = (values[i] / max) * size.height * 0.85;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - h, barWidth, h),
        const Radius.circular(3),
      );
      final paint = Paint()
        ..color = i == values.length - 1 ? highlightColor : inactiveColor;
      canvas.drawRRect(rect, paint);
      x += barWidth + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _MiniBarChartPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}
