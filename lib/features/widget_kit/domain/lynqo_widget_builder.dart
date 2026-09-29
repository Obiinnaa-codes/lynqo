import 'package:flutter/material.dart';

import '../sizing/lynqo_widget_size.dart';
import '../widgets/battery_widget.dart';
import '../widgets/connected_devices_widget.dart';
import '../widgets/connection_widget.dart';
import '../widgets/data_usage_widget.dart';
import '../widgets/network_speed_widget.dart';
import '../widgets/router_overview_widget.dart';
import '../widgets/signal_widget.dart';
import 'lynqo_router_widget_snapshot.dart';
import 'lynqo_widget_type.dart';

abstract final class LynqoWidgetBuilder {
  static Widget build({
    required LynqoWidgetType type,
    required LynqoWidgetSize size,
    required LynqoRouterWidgetSnapshot snapshot,
  }) {
    switch (type) {
      case LynqoWidgetType.battery:
        return BatteryWidget(size: size, data: snapshot.battery);
      case LynqoWidgetType.dataUsage:
        return DataUsageWidget(size: size, data: snapshot.dataUsage);
      case LynqoWidgetType.signal:
        return SignalWidget(size: size, data: snapshot.signal);
      case LynqoWidgetType.connection:
        return ConnectionWidget(size: size, data: snapshot.connection);
      case LynqoWidgetType.devices:
        return ConnectedDevicesWidget(size: size, data: snapshot.devices);
      case LynqoWidgetType.speed:
        return NetworkSpeedWidget(size: size, data: snapshot.networkSpeed);
      case LynqoWidgetType.routerOverview:
        return RouterOverviewWidget(data: snapshot.routerOverview);
    }
  }
}
