import 'package:flutter/material.dart';

import '../domain/models/widget_view_models.dart';
import '../primitives/lynqo_widget_header.dart';
import '../primitives/lynqo_widget_icon.dart';
import '../primitives/lynqo_widget_ring.dart';
import '../primitives/lynqo_widget_surface.dart';
import '../primitives/lynqo_widget_typography.dart';
import '../sizing/lynqo_widget_dimensions.dart';
import '../sizing/lynqo_widget_size.dart';
import '../theme/lynqo_widget_theme.dart';
import '../theme/lynqo_widget_colors.dart';

class BatteryWidget extends StatelessWidget {
  const BatteryWidget({
    super.key,
    required this.size,
    required this.data,
  });

  final LynqoWidgetSize size;
  final BatteryWidgetData data;

  @override
  Widget build(BuildContext context) {
    final theme = LynqoWidgetTheme.of(context);
    final progress = data.progress ?? 0;
    final percentLabel =
        data.percent == null ? '—' : '${data.percent}%';
    final ringColor =
        data.percent == 100 ? LynqoWidgetColors.accentGreen : null;

    return LynqoWidgetSurface(
      size: size,
      child: switch (size) {
        LynqoWidgetSize.small => _SmallLayout(
          theme: theme,
          progress: progress,
          percentLabel: percentLabel,
          progressColor: ringColor,
        ),
        LynqoWidgetSize.medium => _MediumLayout(
          theme: theme,
          progress: progress,
          percentLabel: percentLabel,
          progressColor: ringColor,
          data: data,
        ),
        LynqoWidgetSize.large => _LargeLayout(
          progress: progress,
          percentLabel: percentLabel,
          data: data,
        ),
      },
    );
  }
}

class _SmallLayout extends StatelessWidget {
  const _SmallLayout({
    required this.theme,
    required this.progress,
    required this.percentLabel,
    this.progressColor,
  });

  final LynqoWidgetTheme theme;
  final double progress;
  final String percentLabel;
  final Color? progressColor;

  @override
  Widget build(BuildContext context) {
    final ring = LynqoWidgetDimensions.ringDiameter(LynqoWidgetSize.small);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LynqoWidgetRing(
          progress: progress,
          diameter: ring,
          progressColor: progressColor,
          center: LynqoWidgetIcon(
            icon: Icons.battery_std_outlined,
            size: 22,
          ),
        ),
        const Spacer(),
        Text(
          percentLabel,
          style: LynqoWidgetTheme.of(context).homeSmallBatteryPercentStyle(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _MediumLayout extends StatelessWidget {
  const _MediumLayout({
    required this.theme,
    required this.progress,
    required this.percentLabel,
    this.progressColor,
    required this.data,
  });

  final LynqoWidgetTheme theme;
  final double progress;
  final String percentLabel;
  final Color? progressColor;
  final BatteryWidgetData data;

  @override
  Widget build(BuildContext context) {
    final ring = LynqoWidgetDimensions.ringDiameter(LynqoWidgetSize.medium);
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LynqoWidgetRing(
              progress: progress,
              diameter: ring,
              progressColor: progressColor,
              center: LynqoWidgetIcon(
                icon: Icons.battery_std_outlined,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            LynqoWidgetPrimaryValue(
              text: percentLabel,
              size: LynqoWidgetSize.medium,
            ),
            if (data.statusLabel != null) ...[
              const SizedBox(height: 4),
              LynqoWidgetSecondaryText(text: data.statusLabel!),
            ],
            if (data.timeRemainingLabel != null)
              LynqoWidgetCaption(text: data.timeRemainingLabel!),
          ],
        ),
        const Spacer(),
      ],
    );
  }
}

class _LargeLayout extends StatelessWidget {
  const _LargeLayout({
    required this.progress,
    required this.percentLabel,
    required this.data,
  });

  final double progress;
  final String percentLabel;
  final BatteryWidgetData data;

  @override
  Widget build(BuildContext context) {
    final ring = LynqoWidgetDimensions.ringDiameter(LynqoWidgetSize.large);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LynqoWidgetHeader(
          category: 'Battery',
          headline: percentLabel,
          description: data.statusLabel,
          size: LynqoWidgetSize.large,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            LynqoWidgetRing(
              progress: progress,
              diameter: ring,
              center: LynqoWidgetIcon(
                icon: data.isCharging == true
                    ? Icons.battery_charging_full
                    : Icons.battery_std_outlined,
                size: 28,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data.isCharging == true)
                    const LynqoWidgetSecondaryText(text: 'Charging'),
                  if (data.temperatureC != null)
                    LynqoWidgetCaption(
                      text: '${data.temperatureC}°C',
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
