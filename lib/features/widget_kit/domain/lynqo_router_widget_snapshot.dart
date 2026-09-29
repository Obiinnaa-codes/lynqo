import 'models/widget_view_models.dart';

/// All widget view data for one router poll — suitable for dashboard and future WidgetKit JSON.
class LynqoRouterWidgetSnapshot {
  const LynqoRouterWidgetSnapshot({
    required this.updatedAt,
    required this.battery,
    required this.dataUsage,
    required this.signal,
    required this.connection,
    required this.devices,
    required this.networkSpeed,
    required this.routerOverview,
  });

  final DateTime updatedAt;

  final BatteryWidgetData battery;
  final DataUsageWidgetData dataUsage;
  final SignalWidgetData signal;
  final ConnectionWidgetData connection;
  final ConnectedDevicesWidgetData devices;
  final NetworkSpeedWidgetData networkSpeed;
  final RouterOverviewWidgetData routerOverview;
}
