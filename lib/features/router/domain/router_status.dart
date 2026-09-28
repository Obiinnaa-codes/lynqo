import 'router_connected_client.dart';
import 'router_sms_message.dart';
import 'router_wifi_band_snapshot.dart';

class RouterStatus {
  const RouterStatus({
    this.batteryPercent,
    this.isCharging,
    this.batteryStatusLabel,
    this.powerState,
    this.batteryTemperatureC,
    this.signalStrength,
    this.signalRsrp,
    this.networkType,
    this.connectionState,
    this.carrierName,
    this.accountType,
    this.roaming,
    this.dataUsageBytes,
    this.dataLimitBytes,
    this.dataRemainingBytes,
    this.dataUsagePercent,
    this.billingDaysRemaining,
    this.planTitle,
    this.dataUsedSummary,
    this.dataLimitSummary,
    this.dataRemainingSummary,
    this.nextBillingDateLabel,
    this.dataValidState,
    this.wifiSsid,
    this.wifiStatus,
    this.wifiProfile,
    this.wifiBandLabel,
    this.wifiBandSnapshots = const [],
    this.uploadSpeedBps,
    this.downloadSpeedBps,
    this.connectedDeviceCount,
    this.wifiConnectedClients = const [],
    this.smsMessages = const [],
    this.unreadSmsCount,
  });

  final int? batteryPercent;
  final bool? isCharging;
  final String? batteryStatusLabel;
  final String? powerState;
  final int? batteryTemperatureC;
  final int? signalStrength;
  final int? signalRsrp;
  final String? networkType;
  final String? connectionState;
  final String? carrierName;
  final String? accountType;
  final bool? roaming;
  final int? dataUsageBytes;
  final int? dataLimitBytes;
  final int? dataRemainingBytes;
  final int? dataUsagePercent;
  final int? billingDaysRemaining;
  final String? planTitle;
  final String? dataUsedSummary;
  final String? dataLimitSummary;
  final String? dataRemainingSummary;
  final String? nextBillingDateLabel;
  final String? dataValidState;
  final String? wifiSsid;
  final String? wifiStatus;
  final String? wifiProfile;
  final String? wifiBandLabel;
  final List<RouterWifiBandSnapshot> wifiBandSnapshots;
  final int? uploadSpeedBps;
  final int? downloadSpeedBps;
  final int? connectedDeviceCount;
  final List<RouterConnectedClient> wifiConnectedClients;
  final List<RouterSmsMessage> smsMessages;
  final int? unreadSmsCount;
}
