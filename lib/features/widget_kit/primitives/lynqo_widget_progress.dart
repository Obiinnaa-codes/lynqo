import 'package:flutter/material.dart';

import '../theme/lynqo_widget_theme.dart';

class LynqoWidgetProgress extends StatelessWidget {
  const LynqoWidgetProgress({
    super.key,
    required this.progress,
    this.height = 6,
  });

  final double progress;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = LynqoWidgetTheme.of(context);
    final clamped = progress.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Container(color: theme.chartBarInactive),
            FractionallySizedBox(
              widthFactor: clamped,
              child: Container(color: theme.accentHighlight),
            ),
          ],
        ),
      ),
    );
  }
}
