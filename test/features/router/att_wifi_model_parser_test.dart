import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lynqo/features/router/data/auth/att_wifi/att_wifi_model_parser.dart';

void main() {
  test('parses admin model fixture into dashboard status', () {
    final body = File('test/fixtures/att_wifi/model_admin.json').readAsStringSync();
    final status = AttWifiModelParser.parse(body);

    expect(status.batteryPercent, 72);
    expect(status.isCharging, isFalse);
    expect(status.powerState, 'Online');
    expect(status.batteryTemperatureC, 31);
    expect(status.signalStrength, 4);
    expect(status.signalRsrp, -95);
    expect(status.networkType, 'LTE');
    expect(status.connectionState, 'Connected');
    expect(status.carrierName, 'AT&T');
    expect(status.accountType, 'Postpaid');
    expect(status.roaming, isFalse);
    expect(status.dataValidState, 'Valid');
    expect(status.wifiSsid, 'MyHotspot');
    expect(status.wifiStatus, 'On');
    expect(status.wifiProfile, 'Dual');
    expect(status.wifiBandLabel, 'Dual band');
    expect(status.wifiBandSnapshots, hasLength(2));
    expect(status.wifiBandSnapshots.first.bandLabel, '2.4 GHz');
    expect(status.wifiBandSnapshots.first.ssid, 'MyHotspot');
    expect(status.wifiBandSnapshots.last.bandLabel, '5 GHz');
    expect(status.wifiBandSnapshots.last.ssid, 'MyHotspot_5G');
    // share enabled: server 2GB + (3.5GB all - 2GB server) = 3.5GB used
    expect(status.dataUsageBytes, 3758096384);
    expect(status.dataUsagePercent, 29);
    expect(status.billingDaysRemaining, 12);
    expect(status.planTitle, 'AT&T Mobile Share');
    expect(status.connectedDeviceCount, 2);
    expect(status.wifiConnectedClients, hasLength(2));
    expect(status.wifiConnectedClients.first.displayName, 'Pixel');
    expect(status.wifiConnectedClients.first.ssid, 'MyHotspot');
    expect(status.wifiConnectedClients.first.bandLabel, '2.4 GHz');
    expect(status.wifiConnectedClients.last.displayName, 'iPad');
    expect(status.wifiConnectedClients.last.ssid, 'MyHotspot_5G');
    expect(status.wifiConnectedClients.last.bandLabel, '5 GHz');
    expect(status.dataUsedSummary, '3.5 GB');
    expect(status.dataLimitSummary, '12 GB');
    expect(status.nextBillingDateLabel, isNull);
    expect(status.unreadSmsCount, 1);
    expect(status.smsMessages, hasLength(1));
    expect(status.smsMessages.first.sender, '+15551212');
    expect(status.smsMessages.first.read, isFalse);
  });

  test('formatDataVolume handles small values', () {
    expect(AttWifiModelParser.formatDataVolume(1024), '1024 B');
  });

  test('uses session rx+tx when billing limit is unavailable', () {
    final body = File('test/fixtures/att_wifi/model_data_unavailable.json')
        .readAsStringSync();
    final status = AttWifiModelParser.parse(body);

    expect(status.dataLimitValid, isFalse);
    expect(status.dataUsageBytes, 79272346);
    expect(status.dataUsedSummary, '75.6 MB');
    expect(status.dataUsagePercent, isNull);
  });
}
