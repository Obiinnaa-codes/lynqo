import 'package:flutter/material.dart';

import '../sizing/lynqo_widget_dimensions.dart';
import '../theme/lynqo_widget_theme.dart';
import 'lynqo_metric_ring.dart';
import 'lynqo_metric_widget.dart';
import 'lynqo_widget_icon.dart';

/// Restart column for medium home widget (in-app preview / semantics).
class LynqoRestartAction extends StatelessWidget {
  const LynqoRestartAction({
    super.key,
    this.onTap,
    this.isLoading = false,
    this.ringDiameter,
    this.ringSpacing = LynqoWidgetDimensions.mediumHomeMetricRingSpacing,
  });

  final VoidCallback? onTap;
  final bool isLoading;
  final double? ringDiameter;
  final double ringSpacing;

  @override
  Widget build(BuildContext context) {
    final theme = LynqoWidgetTheme.of(context);
    final resolvedDiameter =
        ringDiameter ?? LynqoWidgetDimensions.mediumHomeRingDiameter;
    final iconSize = resolvedDiameter * 0.38;

    return Semantics(
      button: true,
      label: 'Restart MiFi',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: LynqoMetricWidget(
            ringSpacing: ringSpacing,
            ring: LynqoMetricRing(
              diameter: resolvedDiameter,
              progress: LynqoWidgetDimensions.mediumHomeTrackOnlyRingProgress,
              fullCircle: true,
              center: isLoading
                  ? SizedBox(
                      width: iconSize,
                      height: iconSize,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.accentRing,
                      ),
                    )
                  : LynqoWidgetIcon(
                      icon: Icons.power_settings_new,
                      size: iconSize,
                      muted: true,
                    ),
            ),
            primaryValue: 'Restart',
            secondaryLabel: '',
          ),
        ),
      ),
    );
  }
}
