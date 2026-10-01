import 'package:flutter/material.dart';

import '../sizing/lynqo_widget_size.dart';
import '../theme/lynqo_widget_theme.dart';
/// Centred metric column: ring, primary value, secondary label.
class LynqoMetricWidget extends StatelessWidget {
  const LynqoMetricWidget({
    super.key,
    required this.ring,
    required this.primaryValue,
    required this.secondaryLabel,
    this.primaryFontSize = 16,
    this.ringSpacing = 8,
    this.labelSpacing = 2,
  });

  final Widget ring;
  final String primaryValue;
  final String secondaryLabel;
  final double primaryFontSize;
  final double ringSpacing;
  final double labelSpacing;

  @override
  Widget build(BuildContext context) {
    final theme = LynqoWidgetTheme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ring,
        SizedBox(height: ringSpacing),
        Text(
          primaryValue,
          style: theme.primaryValueStyle(LynqoWidgetSize.medium).copyWith(
            fontSize: primaryFontSize,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: labelSpacing),
        Text(
          secondaryLabel,
          style: theme.captionStyle(fontSize: 12),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
