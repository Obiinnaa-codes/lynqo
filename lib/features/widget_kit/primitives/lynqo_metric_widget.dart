import 'package:flutter/material.dart';

import '../sizing/lynqo_widget_dimensions.dart';
import '../theme/lynqo_widget_theme.dart';

/// Primary line under a home-widget metric ring.
enum LynqoHomeMetricPrimaryRole {
  metricValue,
  actionLabel,
}

/// Centred metric column: ring, primary value, secondary label.
class LynqoMetricWidget extends StatelessWidget {
  const LynqoMetricWidget({
    super.key,
    required this.ring,
    required this.primaryValue,
    required this.secondaryLabel,
    this.primaryRole = LynqoHomeMetricPrimaryRole.metricValue,
    this.ringSpacing = LynqoWidgetDimensions.mediumHomeMetricRingSpacing,
    this.labelSpacing = LynqoWidgetDimensions.mediumHomeMetricLabelSpacing,
  });

  final Widget ring;
  final String primaryValue;
  final String secondaryLabel;
  final LynqoHomeMetricPrimaryRole primaryRole;
  final double ringSpacing;
  final double labelSpacing;

  @override
  Widget build(BuildContext context) {
    final theme = LynqoWidgetTheme.of(context);
    final primaryStyle = switch (primaryRole) {
      LynqoHomeMetricPrimaryRole.metricValue => theme.homeMetricValueStyle(),
      LynqoHomeMetricPrimaryRole.actionLabel => theme.homeActionLabelStyle(),
    };

    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: LynqoWidgetDimensions.mediumHomeRingRowHeight,
            child: Center(child: ring),
          ),
          SizedBox(height: ringSpacing),
          SizedBox(
            height: LynqoWidgetDimensions.mediumHomeMetricPrimaryLineHeight,
            child: Center(
              child: Text(
                primaryValue,
                style: primaryStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (secondaryLabel.isNotEmpty) ...[
            SizedBox(height: labelSpacing),
            SizedBox(
              height: LynqoWidgetDimensions.mediumHomeMetricSecondaryLineHeight,
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
                  secondaryLabel,
                  style: theme.homeMetricLabelStyle(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
