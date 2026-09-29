import 'package:flutter/material.dart';

import '../sizing/lynqo_widget_size.dart';
import 'lynqo_widget_typography.dart';

class LynqoWidgetMetric extends StatelessWidget {
  const LynqoWidgetMetric({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.size = LynqoWidgetSize.small,
  });

  final String label;
  final String value;
  final String? subtitle;
  final LynqoWidgetSize size;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        LynqoWidgetCaption(text: label),
        const SizedBox(height: 4),
        LynqoWidgetPrimaryValue(text: value, size: size),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          LynqoWidgetSecondaryText(text: subtitle!),
        ],
      ],
    );
  }
}
