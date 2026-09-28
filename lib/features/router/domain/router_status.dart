class RouterStatus {
  const RouterStatus({
    this.batteryPercent,
    this.isCharging,
    this.batteryStatusLabel,
    this.signalStrength,
    this.networkType,
    this.connectionState,
    this.dataUsageBytes,
    this.dataLimitBytes,
    this.dataRemainingBytes,
    this.dataUsagePercent,
    this.billingDaysRemaining,
    this.planTitle,
    this.dataUsedSummary,
    this.dataLimitSummary,
    this.uploadSpeedBps,
    this.downloadSpeedBps,
    this.connectedDeviceCount,
  });

  final int? batteryPercent;
  final bool? isCharging;
  final String? batteryStatusLabel;
  final int? signalStrength;
  final String? networkType;
  final String? connectionState;
  final int? dataUsageBytes;
  final int? dataLimitBytes;
  final int? dataRemainingBytes;
  final int? dataUsagePercent;
  final int? billingDaysRemaining;
  final String? planTitle;
  final String? dataUsedSummary;
  final String? dataLimitSummary;
  final int? uploadSpeedBps;
  final int? downloadSpeedBps;
  final int? connectedDeviceCount;
}
