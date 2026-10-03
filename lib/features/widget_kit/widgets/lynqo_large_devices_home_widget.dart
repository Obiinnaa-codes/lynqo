import 'package:flutter/material.dart';

import '../domain/lynqo_router_widget_snapshot.dart';
import '../domain/models/widget_view_models.dart';
import '../primitives/lynqo_glass_container.dart';
import '../primitives/lynqo_widget_divider.dart';
import '../theme/lynqo_widget_theme.dart';

/// Large-only connected devices layout (iOS `LynqoMiFiDevicesWidget` parity).
class LynqoLargeDevicesHomeWidget extends StatelessWidget {
  const LynqoLargeDevicesHomeWidget({
    super.key,
    required this.snapshot,
    this.width = 364,
    this.height = 382,
  });

  final LynqoRouterWidgetSnapshot snapshot;
  final double width;
  final double height;

  static const int _maxVisibleRows = 6;

  bool get _isSynced => snapshot.updatedAt.millisecondsSinceEpoch != 0;

  @override
  Widget build(BuildContext context) {
    final theme = LynqoWidgetTheme.of(context);
    final devices = snapshot.devices;
    final rows = devices.devices;
    final visible = rows.take(_maxVisibleRows).toList();
    final overflow = rows.length - visible.length;

    return LynqoGlassContainer(
      width: width,
      height: height,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            routerName: snapshot.routerOverview.routerName,
            deviceCount: devices.count,
            isSynced: _isSynced,
          ),
          const SizedBox(height: 12),
          if (!_isSynced)
            Text(
              'Open Lynqo on the MiFi network to sync devices.',
              style: theme.homeMetricLabelStyle(),
            )
          else if (visible.isEmpty)
            Text(
              'No devices connected',
              style: theme.homeMetricLabelStyle(),
            )
          else ...[
            for (var i = 0; i < visible.length; i++) ...[
              if (i > 0) const LynqoWidgetDivider(),
              _DeviceRow(device: visible[i]),
            ],
            if (overflow > 0) ...[
              const LynqoWidgetDivider(),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+$overflow more',
                  style: theme.homeMetricLabelStyle(),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.routerName,
    required this.deviceCount,
    required this.isSynced,
  });

  final String routerName;
  final int? deviceCount;
  final bool isSynced;

  @override
  Widget build(BuildContext context) {
    final theme = LynqoWidgetTheme.of(context);
    final countLabel = !isSynced || deviceCount == null
        ? '—'
        : deviceCount == 1
            ? '1 device'
            : '$deviceCount devices';

    return Row(
      children: [
        Icon(Icons.wifi, size: 18, color: theme.secondaryText),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            routerName,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: theme.primaryText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          countLabel,
          style: theme.homeMetricLabelStyle().copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({required this.device});

  final ConnectedDeviceSummary device;

  @override
  Widget build(BuildContext context) {
    final theme = LynqoWidgetTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(Icons.smartphone_outlined, size: 16, color: theme.secondaryText),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              device.name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: theme.primaryText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (device.subtitle != null && device.subtitle!.isNotEmpty)
            Text(
              device.subtitle!,
              style: theme.homeMetricLabelStyle(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
