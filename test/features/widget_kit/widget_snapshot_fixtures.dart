import 'package:lynqo/features/router/domain/router_status.dart';
import 'package:lynqo/features/widget_kit/domain/lynqo_router_widget_snapshot.dart';
import 'package:lynqo/features/widget_kit/domain/models/widget_view_models.dart';

/// Test-only snapshot with representative fields (not used in app UI).
LynqoRouterWidgetSnapshot syncedWidgetSnapshotFixture() {
  const battery = BatteryWidgetData(percent: 94, isCharging: true);
  const dataUsage = DataUsageWidgetData(
    usedSummary: '12.4 GB',
    limitSummary: '50 GB',
    usagePercent: 25,
  );
  return LynqoRouterWidgetSnapshot(
    updatedAt: DateTime.utc(2026, 9, 28, 12),
    battery: battery,
    dataUsage: dataUsage,
    signal: const SignalWidgetData(
      strengthPercent: 82,
      qualityLabel: 'Excellent',
      networkType: '5G',
      carrierName: 'AT&T',
    ),
    connection: const ConnectionWidgetData(
      headline: 'Connected',
      hostLabel: 'attwifimanager',
      statusLabel: 'Online',
      wifiSsid: 'MyHotspot',
    ),
    devices: const ConnectedDevicesWidgetData(count: 3),
    networkSpeed: const NetworkSpeedWidgetData(
      downloadMbps: '142 Mbps',
      uploadMbps: '28 Mbps',
    ),
    routerOverview: const RouterOverviewWidgetData(
      routerName: 'MyHotspot',
      battery: battery,
      dataUsage: dataUsage,
      devices: ConnectedDevicesWidgetData(count: 3),
    ),
  );
}

RouterStatus routerStatusFixture() {
  return const RouterStatus(
    wifiSsid: 'MyHotspot',
    wifiStatus: 'On',
    wifiBandLabel: '5 GHz',
  );
}
