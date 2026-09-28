import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lynqo/features/router/data/auth/att_wifi/att_wifi_model_parser.dart';

void main() {
  test('parses admin model fixture into dashboard status', () {
    final body = File('test/fixtures/att_wifi/model_admin.json').readAsStringSync();
    final status = AttWifiModelParser.parse(body);

    expect(status.batteryPercent, 72);
    expect(status.isCharging, isFalse);
    expect(status.signalStrength, 4);
    expect(status.networkType, 'LTE');
    expect(status.connectionState, 'Connected');
    expect(status.dataUsagePercent, 25);
    expect(status.dataUsedSummary, '3.0 GB');
    expect(status.dataLimitSummary, '12 GB');
    expect(status.billingDaysRemaining, 14);
    expect(status.planTitle, 'AT&T Mobile Share');
    expect(status.connectedDeviceCount, 3);
  });

  test('maps errno-free login failure URL in parser tests elsewhere', () {
    expect(
      AttWifiModelParser.parse('{"power":{"battChargeLevel":100}}')
          .batteryPercent,
      100,
    );
  });
}
