import 'package:flutter/material.dart';

import '../theme/lynqo_widget_theme.dart';

class LynqoWidgetBadge extends StatelessWidget {
  const LynqoWidgetBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = LynqoWidgetTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.chartBarInactive,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.captionStyle(fontSize: 11),
      ),
    );
  }
}
