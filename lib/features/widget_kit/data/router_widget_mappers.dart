import '../../router/domain/router_connected_client.dart';
import '../../router/domain/router_status.dart';
import '../domain/lynqo_router_widget_snapshot.dart';
import '../domain/models/widget_view_models.dart';
import 'signal_presentation.dart';

abstract final class RouterWidgetMappers {
  static LynqoRouterWidgetSnapshot fromRouterStatus(
    RouterStatus status, {
    required String routerHost,
    NetworkSpeedWidgetData? networkSpeed,
    DateTime? updatedAt,
  }) {
    final battery = _battery(status);
    final dataUsage = _dataUsage(status);
    final signal = _signal(status);
    final connection = _connection(status, routerHost: routerHost);
    final devices = _devices(status);
    final speed = networkSpeed ?? _networkSpeed(status);
    final routerName = status.wifiSsid ?? routerHost;

    final overview = RouterOverviewWidgetData(
      routerName: routerName,
      battery: battery,
      signal: signal,
      dataUsage: dataUsage,
      connection: connection,
      devices: devices,
    );

    return LynqoRouterWidgetSnapshot(
      updatedAt: updatedAt ?? DateTime.now(),
      battery: battery,
      dataUsage: dataUsage,
      signal: signal,
      connection: connection,
      devices: devices,
      networkSpeed: speed,
      routerOverview: overview,
    );
  }

  static BatteryWidgetData _battery(RouterStatus status) {
    return BatteryWidgetData(
      percent: status.batteryPercent,
      isCharging: status.isCharging,
      statusLabel: status.batteryStatusLabel,
      temperatureC: status.batteryTemperatureC,
    );
  }

  static DataUsageWidgetData _dataUsage(RouterStatus status) {
    String? billingResetLabel;
    if (status.nextBillingDateLabel != null) {
      billingResetLabel = 'Resets ${status.nextBillingDateLabel}';
    } else if (status.billingDaysRemaining != null) {
      billingResetLabel = '${status.billingDaysRemaining} days left in cycle';
    }

    String? comparisonCaption;
    if (status.dataValidState != null && status.planTitle != null) {
      comparisonCaption = '${status.planTitle} · ${status.dataValidState}';
    } else if (status.planTitle != null) {
      comparisonCaption = status.planTitle;
    }

    return DataUsageWidgetData(
      usedSummary: status.dataUsedSummary,
      remainingSummary: status.dataRemainingSummary == null
          ? null
          : '${status.dataRemainingSummary} remaining',
      limitSummary: status.dataLimitSummary,
      usagePercent: status.dataUsagePercent,
      comparisonCaption: comparisonCaption,
      billingResetLabel: billingResetLabel,
    );
  }

  static SignalWidgetData _signal(RouterStatus status) {
    return SignalWidgetData(
      strengthPercent: SignalPresentation.strengthPercentFromBars(
        status.signalStrength,
      ),
      qualityLabel: SignalPresentation.qualityLabelFromBars(
        status.signalStrength,
      ),
      networkType: status.networkType,
      carrierName: status.carrierName,
    );
  }

  static ConnectionWidgetData _connection(
    RouterStatus status, {
    required String routerHost,
  }) {
    final headline = _connectionHeadline(status);
    final online = status.powerState ?? status.connectionState;

    return ConnectionWidgetData(
      headline: headline,
      hostLabel: routerHost,
      statusLabel: online,
      wifiSsid: status.wifiSsid,
    );
  }

  static String? _connectionHeadline(RouterStatus status) {
    final cellular = status.connectionState;
    if (cellular != null && cellular.isNotEmpty) {
      if (cellular.toLowerCase() == 'connected') {
        return 'Connected';
      }
      return cellular;
    }
    if (status.powerState?.toLowerCase() == 'online') {
      return 'Connected';
    }
    return status.powerState;
  }

  static ConnectedDevicesWidgetData _devices(RouterStatus status) {
    final clients = status.wifiConnectedClients;
    return ConnectedDevicesWidgetData(
      count: status.connectedDeviceCount,
      devices: clients.map(_deviceSummary).toList(),
    );
  }

  static ConnectedDeviceSummary _deviceSummary(RouterConnectedClient client) {
    final subtitle = client.bandLabel ?? client.networkLabel ?? client.ssid;
    return ConnectedDeviceSummary(
      name: client.displayName,
      subtitle: subtitle,
    );
  }

  static NetworkSpeedWidgetData _networkSpeed(RouterStatus status) {
    return NetworkSpeedWidgetData(
      downloadMbps: formatMbps(status.downloadSpeedBps),
      uploadMbps: formatMbps(status.uploadSpeedBps),
    );
  }

  static String? formatMbps(int? bitsPerSecond) {
    if (bitsPerSecond == null) {
      return null;
    }
    final mbps = bitsPerSecond / 1000000;
    if (mbps >= 100) {
      return '${mbps.round()} Mbps';
    }
    if (mbps >= 10) {
      return '${mbps.toStringAsFixed(0)} Mbps';
    }
    return '${mbps.toStringAsFixed(1)} Mbps';
  }
}
