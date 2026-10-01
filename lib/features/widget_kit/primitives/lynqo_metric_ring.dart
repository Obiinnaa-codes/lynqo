import 'package:flutter/material.dart';

import '../sizing/lynqo_widget_dimensions.dart';
import '../sizing/lynqo_widget_size.dart';
import 'lynqo_widget_ring.dart';

/// Thin ring defaults for medium home-widget metric columns.
class LynqoMetricRing extends StatelessWidget {
  const LynqoMetricRing({
    super.key,
    required this.progress,
    this.diameter,
    this.strokeWidth = 4,
    this.progressColor,
    this.center,
  });

  final double? progress;
  final double? diameter;
  final double strokeWidth;
  final Color? progressColor;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    final resolvedDiameter =
        diameter ?? LynqoWidgetDimensions.ringDiameter(LynqoWidgetSize.medium);
    final resolvedProgress = progress ?? 0;

    return LynqoWidgetRing(
      progress: resolvedProgress,
      diameter: resolvedDiameter,
      strokeWidth: strokeWidth,
      progressColor: progressColor,
      center: center,
    );
  }
}
