import 'package:flutter/material.dart';

import '../domain/models/widget_view_models.dart';
import '../primitives/lynqo_widget_device_orb.dart';
import '../primitives/lynqo_widget_divider.dart';
import '../primitives/lynqo_widget_header.dart';
import '../primitives/lynqo_widget_surface.dart';
import '../primitives/lynqo_widget_typography.dart';
import '../sizing/lynqo_widget_size.dart';
import '../theme/lynqo_widget_theme.dart';

class ConnectedDevicesWidget extends StatelessWidget {
  const ConnectedDevicesWidget({
    super.key,
    required this.size,
    required this.data,
  });

  final LynqoWidgetSize size;
  final ConnectedDevicesWidgetData data;

  @override
  Widget build(BuildContext context) {
    final countLabel = data.count == null ? '—' : '${data.count}';

    return LynqoWidgetSurface(
      size: size,
      child: switch (size) {
        LynqoWidgetSize.small => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LynqoWidgetPrimaryValue(
              text: countLabel,
              size: LynqoWidgetSize.small,
            ),
            const Spacer(),
            const LynqoWidgetCaption(text: 'devices'),
          ],
        ),
        LynqoWidgetSize.medium => _MediumDevices(data: data, countLabel: countLabel),
        LynqoWidgetSize.large => _LargeDevices(data: data, countLabel: countLabel),
      },
    );
  }
}

class _MediumDevices extends StatelessWidget {
  const _MediumDevices({required this.data, required this.countLabel});

  final ConnectedDevicesWidgetData data;
  final String countLabel;

  @override
  Widget build(BuildContext context) {
    final theme = LynqoWidgetTheme.of(context);
    final orbs = _orbLabels(data);

    if (theme.isDark) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LynqoWidgetPrimaryValue(
                text: countLabel,
                size: LynqoWidgetSize.medium,
              ),
              const LynqoWidgetCaption(text: 'devices'),
            ],
          ),
          const Spacer(),
          for (var i = 0; i < 4; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            LynqoWidgetDeviceOrb(
              label: i < orbs.length ? orbs[i] : null,
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LynqoWidgetHeader(
          category: 'Connected devices',
          headline: countLabel,
          description: 'devices connected',
          size: LynqoWidgetSize.medium,
        ),
      ],
    );
  }

  List<String> _orbLabels(ConnectedDevicesWidgetData data) {
    return data.devices.map((d) => d.name).toList();
  }
}

class _LargeDevices extends StatelessWidget {
  const _LargeDevices({required this.data, required this.countLabel});

  final ConnectedDevicesWidgetData data;
  final String countLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LynqoWidgetHeader(
          category: 'Connected devices',
          headline: countLabel,
          description: 'devices connected',
          size: LynqoWidgetSize.large,
        ),
        const SizedBox(height: 16),
        for (final device in data.devices.take(5)) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
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
    );
  }
}
