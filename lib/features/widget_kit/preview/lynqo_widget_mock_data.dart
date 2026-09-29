import '../domain/lynqo_router_widget_snapshot.dart';
import '../domain/models/widget_view_models.dart';

abstract final class LynqoWidgetMockData {
  static BatteryWidgetData battery = const BatteryWidgetData(
    percent: 94,
    isCharging: true,
    statusLabel: 'Charging',
    temperatureC: 31,
  );

  static DataUsageWidgetData dataUsage = DataUsageWidgetData(
    usedSummary: '24.6 GB',
    remainingSummary: '12.4 GB remaining',
    limitSummary: '37 GB',
    usagePercent: 66,
    comparisonCaption: 'Usage is within your monthly plan.',
    billingResetLabel: 'Resets 17 Oct',
    historyValues: [0.4, 0.55, 0.5, 0.62, 0.58, 0.7, 0.66],
    chartStartLabel: '10 Jun',
    chartEndLabel: '17 Jun',
  );

  static SignalWidgetData signal = const SignalWidgetData(
    strengthPercent: 82,
    qualityLabel: 'Excellent',
    networkType: '5G',
    carrierName: 'AT&T',
  );

  static ConnectionWidgetData connection = const ConnectionWidgetData(
    headline: 'Connected',
    hostLabel: 'attwifimanager',
    statusLabel: 'Online',
    wifiSsid: 'MyHotspot',
  );

  static ConnectedDevicesWidgetData devices = const ConnectedDevicesWidgetData(
    count: 4,
    devices: [
      ConnectedDeviceSummary(name: 'Pixel', subtitle: '2.4 GHz'),
      ConnectedDeviceSummary(name: 'iPad', subtitle: '5 GHz'),
      ConnectedDeviceSummary(name: 'MacBook', subtitle: '5 GHz'),
    ],
  );

  static NetworkSpeedWidgetData networkSpeed = const NetworkSpeedWidgetData(
    downloadMbps: '142 Mbps',
    uploadMbps: '28 Mbps',
  );

  static RouterOverviewWidgetData routerOverview = RouterOverviewWidgetData(
    routerName: 'MyHotspot',
    battery: battery,
    signal: signal,
    dataUsage: dataUsage,
    connection: connection,
    devices: devices,
  );

  static LynqoRouterWidgetSnapshot snapshot = LynqoRouterWidgetSnapshot(
    updatedAt: DateTime.utc(2026, 9, 28, 12),
    battery: battery,
    dataUsage: dataUsage,
    signal: signal,
    connection: connection,
    devices: devices,
    networkSpeed: networkSpeed,
    routerOverview: routerOverview,
  );
}
