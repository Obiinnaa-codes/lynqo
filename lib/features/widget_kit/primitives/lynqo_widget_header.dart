import 'package:flutter/material.dart';

import '../sizing/lynqo_widget_size.dart';
import 'lynqo_widget_typography.dart';

class LynqoWidgetHeader extends StatelessWidget {
  const LynqoWidgetHeader({
    super.key,
    required this.category,
    required this.headline,
    this.description,
    this.size = LynqoWidgetSize.medium,
  });

  final String category;
  final String headline;
  final String? description;
  final LynqoWidgetSize size;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LynqoWidgetTitle(text: category, size: size),
        const SizedBox(height: 4),
        LynqoWidgetPrimaryValue(text: headline, size: size),
        if (description != null) ...[
          const SizedBox(height: 4),
          LynqoWidgetSecondaryText(text: description!),
        ],
      ],
    );
  }
}
