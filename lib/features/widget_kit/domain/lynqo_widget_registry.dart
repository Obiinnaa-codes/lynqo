import 'package:flutter/material.dart';

import '../sizing/lynqo_widget_size.dart';
import 'lynqo_widget_type.dart';

class LynqoWidgetDefinition {
  const LynqoWidgetDefinition({
    required this.type,
    required this.id,
    required this.displayName,
    required this.description,
    required this.icon,
    required this.supportedSizes,
  });

  final LynqoWidgetType type;
  final String id;
  final String displayName;
  final String description;
  final IconData icon;
  final List<LynqoWidgetSize> supportedSizes;
}

abstract final class LynqoWidgetRegistry {
  static List<LynqoWidgetDefinition> get all => [
    LynqoWidgetDefinition(
      type: LynqoWidgetType.battery,
      id: 'battery',
      displayName: 'Battery',
      description: 'MiFi battery level and charging state',
      icon: Icons.battery_std_outlined,
      supportedSizes: LynqoWidgetSize.values,
    ),
    LynqoWidgetDefinition(
      type: LynqoWidgetType.dataUsage,
      id: 'data_usage',
      displayName: 'Data usage',
      description: 'Plan usage and remaining allowance',
      icon: Icons.data_usage,
      supportedSizes: LynqoWidgetSize.values,
    ),
    LynqoWidgetDefinition(
      type: LynqoWidgetType.signal,
      id: 'signal',
      displayName: 'Signal',
      description: 'Cellular signal and network type',
      icon: Icons.signal_cellular_alt,
      supportedSizes: LynqoWidgetSize.values,
    ),
    LynqoWidgetDefinition(
      type: LynqoWidgetType.connection,
      id: 'connection',
      displayName: 'Connection',
      description: 'Router connection status',
      icon: Icons.lan_outlined,
      supportedSizes: LynqoWidgetSize.values,
    ),
    LynqoWidgetDefinition(
      type: LynqoWidgetType.devices,
      id: 'devices',
      displayName: 'Connected devices',
      description: 'Clients on the MiFi',
      icon: Icons.devices_other_outlined,
      supportedSizes: LynqoWidgetSize.values,
    ),
    LynqoWidgetDefinition(
      type: LynqoWidgetType.speed,
      id: 'speed',
      displayName: 'Network speed',
      description: 'Download and upload throughput',
      icon: Icons.speed,
      supportedSizes: LynqoWidgetSize.values,
    ),
    LynqoWidgetDefinition(
      type: LynqoWidgetType.routerOverview,
      id: 'router_overview',
      displayName: 'Router overview',
      description: 'Combined MiFi status',
      icon: Icons.dashboard_customize_outlined,
      supportedSizes: [LynqoWidgetSize.large],
    ),
  ];

  static LynqoWidgetDefinition? byType(LynqoWidgetType type) {
    for (final def in all) {
      if (def.type == type) {
        return def;
      }
    }
    return null;
  }
}
