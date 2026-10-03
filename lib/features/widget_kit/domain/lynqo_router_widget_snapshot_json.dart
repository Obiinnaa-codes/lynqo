import 'lynqo_router_widget_snapshot.dart';

/// JSON-friendly export for future native WidgetKit (Stage J).
extension LynqoRouterWidgetSnapshotJson on LynqoRouterWidgetSnapshot {
  Map<String, Object?> toJson() {
    return {
      'schemaVersion': 1,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'battery': {
        'percent': battery.percent,
        'isCharging': battery.isCharging,
        'statusLabel': battery.statusLabel,
        'temperatureC': battery.temperatureC,
      },
      'dataUsage': {
        'usedSummary': dataUsage.usedSummary,
        'remainingSummary': dataUsage.remainingSummary,
        'limitSummary': dataUsage.limitSummary,
        'usagePercent': dataUsage.usagePercent,
        'planUnavailable': dataUsage.planUnavailable,
      },
      'signal': {
        'strengthPercent': signal.strengthPercent,
        'qualityLabel': signal.qualityLabel,
        'networkType': signal.networkType,
        'carrierName': signal.carrierName,
      },
      'connection': {
        'headline': connection.headline,
        'hostLabel': connection.hostLabel,
        'statusLabel': connection.statusLabel,
        'wifiSsid': connection.wifiSsid,
      },
      'devices': {
        'count': devices.count,
        'names': devices.devices.map((d) => d.name).toList(),
        'items': devices.devices
            .map(
              (d) => {
                'name': d.name,
                if (d.subtitle != null && d.subtitle!.isNotEmpty)
                  'subtitle': d.subtitle,
              },
            )
            .toList(),
      },
      'networkSpeed': {
        'downloadMbps': networkSpeed.downloadMbps,
        'uploadMbps': networkSpeed.uploadMbps,
      },
      'routerName': routerOverview.routerName,
    };
  }
}
