import 'package:flutter/material.dart';

import '../theme/lynqo_widget_theme.dart';

class LynqoWidgetBatteryPill extends StatelessWidget {
  const LynqoWidgetBatteryPill({
    super.key,
    required this.progress,
    this.width = 28,
    this.height = 14,
  });

  final double progress;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = LynqoWidgetTheme.of(context);
    final clamped = progress.clamp(0.0, 1.0);

    return CustomPaint(
      size: Size(width, height),
      painter: _BatteryPillPainter(
        progress: clamped,
        fillColor: theme.accentRing,
        outlineColor: theme.primaryText.withValues(alpha: 0.5),
      ),
    );
  }
}

class _BatteryPillPainter extends CustomPainter {
  _BatteryPillPainter({
    required this.progress,
    required this.fillColor,
    required this.outlineColor,
  });

  final double progress;
  final Color fillColor;
  final Color outlineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width - 3, size.height),
      Radius.circular(size.height / 3),
    );
    final outline = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(body, outline);

    final fillWidth = (size.width - 6) * progress;
    if (fillWidth > 0) {
      final fill = RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 2, fillWidth, size.height - 4),
        Radius.circular(size.height / 4),
      );
      canvas.drawRRect(fill, Paint()..color = fillColor);
    }

    final cap = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width - 2, size.height * 0.3, 2, size.height * 0.4),
      const Radius.circular(1),
    );
    canvas.drawRRect(cap, Paint()..color = outlineColor);
  }

  @override
  bool shouldRepaint(covariant _BatteryPillPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
