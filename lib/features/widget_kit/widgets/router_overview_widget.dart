import 'package:flutter/material.dart';

import '../domain/models/widget_view_models.dart';
import '../primitives/lynqo_widget_battery_pill.dart';
import '../primitives/lynqo_widget_divider.dart';
import '../primitives/lynqo_widget_icon.dart';
import '../primitives/lynqo_widget_metric.dart';
import '../primitives/lynqo_widget_surface.dart';
import '../primitives/lynqo_widget_typography.dart';
import '../sizing/lynqo_widget_size.dart';

class RouterOverviewWidget extends StatelessWidget {
  const RouterOverviewWidget({
    super.key,
    required this.data,
  });

  final RouterOverviewWidgetData data;

  @override
  Widget build(BuildContext context) {
    final battery = data.battery;
    final batteryPercent = battery?.percent;
    final batteryProgress = battery?.progress ?? 0;

    return LynqoWidgetSurface(
      size: LynqoWidgetSize.large,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Row(
            children: [
              const LynqoWidgetIcon(icon: Icons.router_outlined, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: LynqoWidgetSecondaryText(text: data.routerName),
              ),
              if (batteryPercent != null) ...[
                LynqoWidgetCaption(text: '$batteryPercent%'),
                const SizedBox(width: 6),
                LynqoWidgetBatteryPill(progress: batteryProgress),
              ],
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: LynqoWidgetMetric(
                  label: 'Battery',
                  value: batteryPercent == null ? '—' : '$batteryPercent%',
                  subtitle: battery?.statusLabel,
                  size: LynqoWidgetSize.small,
                ),
              ),
              Expanded(
                child: LynqoWidgetMetric(
                  label: 'Signal',
                  value: data.signal?.strengthPercent == null
                      ? '—'
                      : '${data.signal!.strengthPercent}%',
                  subtitle: data.signal?.qualityLabel,
                  size: LynqoWidgetSize.small,
                ),
              ),
              Expanded(
                child: LynqoWidgetMetric(
                  label: 'Data',
                  value: data.dataUsage?.usedSummary ?? '—',
                  subtitle: data.dataUsage?.remainingSummary,
                  size: LynqoWidgetSize.small,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const LynqoWidgetDivider(),
          const SizedBox(height: 8),
          LynqoWidgetCaption(text: data.connection?.headline ?? 'Connection'),
          if (data.connection?.statusLabel != null)
            LynqoWidgetSecondaryText(text: data.connection!.statusLabel!),
          if (data.devices != null && data.devices!.devices.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final device in data.devices!.devices.take(3)) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: LynqoWidgetSecondaryText(text: device.name),
                    ),
                    if (device.subtitle != null)
                      LynqoWidgetCaption(text: device.subtitle!),
                  ],
                ),
              ),
              const LynqoWidgetDivider(),
            ],
          ],
        ],
        ),
      ),
    );
  }
}
