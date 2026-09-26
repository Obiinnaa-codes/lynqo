class RouterStatus {
  const RouterStatus({
    this.batteryPercent,
    this.isCharging,
    this.signalStrength,
    this.networkType,
    this.connectionState,
    this.dataUsageBytes,
    this.dataRemainingBytes,
    this.uploadSpeedBps,
    this.downloadSpeedBps,
    this.connectedDeviceCount,
  });

  final int? batteryPercent;
  final bool? isCharging;
  final int? signalStrength;
  final String? networkType;
  final String? connectionState;
  final int? dataUsageBytes;
  final int? dataRemainingBytes;
  final int? uploadSpeedBps;
  final int? downloadSpeedBps;
  final int? connectedDeviceCount;
}
