import 'package:flutter/material.dart';

import '../domain/lynqo_router_widget_snapshot.dart';
import '../presentation/lynqo_medium_mifi_presentation.dart';
import '../primitives/lynqo_glass_container.dart';
import '../primitives/lynqo_metric_ring.dart';
import '../primitives/lynqo_metric_widget.dart';
import '../primitives/lynqo_restart_action.dart';
import '../primitives/lynqo_widget_icon.dart';
import '../sizing/lynqo_widget_dimensions.dart';

/// iOS systemMedium home widget layout (Flutter parity + preview).
class LynqoMediumMiFiWidget extends StatelessWidget {
  const LynqoMediumMiFiWidget({
    super.key,
    required this.snapshot,
    this.onRestartTap,
    this.isRestartLoading = false,
    this.width = 364,
    this.height = 170,
  });

  final LynqoRouterWidgetSnapshot snapshot;
  final VoidCallback? onRestartTap;
  final bool isRestartLoading;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final ringSize = LynqoWidgetDimensions.mediumHomeRingDiameter;
    final iconSize = ringSize * 0.38;
    final ringSpacing = LynqoWidgetDimensions.mediumHomeMetricRingSpacing;
    final columnGap = LynqoWidgetDimensions.mediumHomeColumnSpacing;
    final battery = snapshot.battery;
    final batteryProgress =
        LynqoMediumMiFiPresentation.batteryProgress(snapshot) ?? 0;
    final dataProgress =
        LynqoMediumMiFiPresentation.dataProgress(snapshot) ?? 0;

    return LynqoGlassContainer(
      width: width,
      height: height,
      padding: LynqoWidgetDimensions.mediumHomeContentPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _metricColumn(
                LynqoMetricWidget(
                  ringSpacing: ringSpacing,
                  ring: LynqoMetricRing(
                    diameter: ringSize,
                    progress: batteryProgress,
                    fullCircle: true,
                    progressColor:
                        LynqoMediumMiFiPresentation.batteryProgressColor(
                      snapshot,
                    ),
                    center: LynqoWidgetIcon(
                      icon: LynqoMediumMiFiPresentation.batteryIcon(battery),
                      size: iconSize,
                      muted: true,
                    ),
                  ),
                  primaryValue:
                      LynqoMediumMiFiPresentation.batteryPrimary(snapshot),
                  secondaryLabel: '',
                ),
              ),
              SizedBox(width: columnGap),
              _metricColumn(
                LynqoMetricWidget(
                  ringSpacing: ringSpacing,
                  ring: LynqoMetricRing(
                    diameter: ringSize,
                    progress: dataProgress,
                    fullCircle: true,
                    center: LynqoWidgetIcon(
                      icon: Icons.swap_vert,
                      size: iconSize,
                      muted: true,
                    ),
                  ),
                  primaryValue:
                      LynqoMediumMiFiPresentation.dataPrimary(snapshot),
                  secondaryLabel:
                      LynqoMediumMiFiPresentation.dataSecondary(snapshot),
                ),
              ),
              SizedBox(width: columnGap),
              _metricColumn(
                LynqoMetricWidget(
                  ringSpacing: ringSpacing,
                  ring: LynqoMetricRing(
                    diameter: ringSize,
                    progress:
                        LynqoWidgetDimensions.mediumHomeTrackOnlyRingProgress,
                    fullCircle: true,
                    center: LynqoWidgetIcon(
                      icon: Icons.devices_outlined,
                      size: iconSize,
                      muted: true,
                    ),
                  ),
                  primaryValue:
                      LynqoMediumMiFiPresentation.devicesPrimary(snapshot),
                  secondaryLabel: '',
                ),
              ),
              SizedBox(width: columnGap),
              _metricColumn(
                LynqoRestartAction(
                  ringDiameter: ringSize,
                  onTap: onRestartTap,
                  isLoading: isRestartLoading,
                  ringSpacing: ringSpacing,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _metricColumn(Widget child) {
    return Expanded(child: child);
  }
}
