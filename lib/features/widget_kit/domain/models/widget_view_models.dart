class BatteryWidgetData {
  const BatteryWidgetData({
    this.percent,
    this.isCharging,
    this.statusLabel,
    this.temperatureC,
    this.timeRemainingLabel,
  });

  final int? percent;
  final bool? isCharging;
  final String? statusLabel;
  final int? temperatureC;
  final String? timeRemainingLabel;

  double? get progress =>
      percent == null ? null : (percent!.clamp(0, 100) / 100);
}

class DataUsageWidgetData {
  const DataUsageWidgetData({
    this.usedSummary,
    this.remainingSummary,
    this.limitSummary,
    this.usagePercent,
    this.planUnavailable = false,
    this.comparisonCaption,
    this.billingResetLabel,
    this.historyValues,
    this.chartStartLabel,
    this.chartEndLabel,
  });

  final String? usedSummary;
  final String? remainingSummary;
  final String? limitSummary;
  final int? usagePercent;
  final bool planUnavailable;
  final String? comparisonCaption;
  final String? billingResetLabel;
  final List<double>? historyValues;
  final String? chartStartLabel;
  final String? chartEndLabel;

  double? get progress =>
      usagePercent == null ? null : (usagePercent!.clamp(0, 100) / 100);
}

class SignalWidgetData {
  const SignalWidgetData({
    this.strengthPercent,
    this.qualityLabel,
    this.networkType,
    this.carrierName,
  });

  final int? strengthPercent;
  final String? qualityLabel;
  final String? networkType;
  final String? carrierName;

  double? get progress =>
      strengthPercent == null ? null : (strengthPercent!.clamp(0, 100) / 100);
}

class ConnectionWidgetData {
  const ConnectionWidgetData({
    this.headline,
    this.hostLabel,
    this.statusLabel,
    this.wifiSsid,
  });

  final String? headline;
  final String? hostLabel;
  final String? statusLabel;
  final String? wifiSsid;
}

class ConnectedDeviceSummary {
  const ConnectedDeviceSummary({required this.name, this.subtitle});

  final String name;
  final String? subtitle;
}

class ConnectedDevicesWidgetData {
  const ConnectedDevicesWidgetData({
    this.count,
    this.devices = const [],
  });

  final int? count;
  final List<ConnectedDeviceSummary> devices;
}

class NetworkSpeedWidgetData {
  const NetworkSpeedWidgetData({
    this.downloadMbps,
    this.uploadMbps,
  });

  final String? downloadMbps;
  final String? uploadMbps;
}

class RouterOverviewWidgetData {
  const RouterOverviewWidgetData({
    required this.routerName,
    this.battery,
    this.signal,
    this.dataUsage,
    this.connection,
    this.devices,
  });

  final String routerName;
  final BatteryWidgetData? battery;
  final SignalWidgetData? signal;
  final DataUsageWidgetData? dataUsage;
  final ConnectionWidgetData? connection;
  final ConnectedDevicesWidgetData? devices;
}
