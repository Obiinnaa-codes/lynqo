import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lynqo/features/router/data/auth/att_wifi/att_wifi_model_parser.dart';
import 'package:lynqo/features/widget_kit/data/router_widget_mappers.dart';

void main() {
  test('maps admin model fixture to widget snapshot', () {
    final body =
        File('test/fixtures/att_wifi/model_admin.json').readAsStringSync();
    final status = AttWifiModelParser.parse(body);
    final snapshot = RouterWidgetMappers.fromRouterStatus(
      status,
      routerHost: 'attwifimanager',
    );

    expect(snapshot.battery.percent, 72);
    expect(snapshot.dataUsage.usedSummary, '3.5 GB');
    expect(snapshot.signal.strengthPercent, 80);
    expect(snapshot.signal.qualityLabel, 'Excellent');
    expect(snapshot.signal.carrierName, 'AT&T');
    expect(snapshot.connection.headline, 'Connected');
    expect(snapshot.connection.hostLabel, 'attwifimanager');
    expect(snapshot.devices.count, 2);
    expect(snapshot.devices.devices.first.name, 'Pixel');
    expect(snapshot.routerOverview.routerName, 'MyHotspot');
    expect(snapshot.networkSpeed.downloadMbps, isNull);
  });

  test('maps unavailable plan to session usage snapshot', () {
    final body = File('test/fixtures/att_wifi/model_data_unavailable.json')
        .readAsStringSync();
    final status = AttWifiModelParser.parse(body);
    final snapshot = RouterWidgetMappers.fromRouterStatus(
      status,
      routerHost: 'attwifimanager',
    );

    expect(snapshot.dataUsage.usedSummary, '75.6 MB');
    expect(snapshot.dataUsage.planUnavailable, isTrue);
    expect(snapshot.dataUsage.limitSummary, isNull);
    expect(snapshot.dataUsage.comparisonCaption, isNull);
  });

  test('formatMbps', () {
    expect(RouterWidgetMappers.formatMbps(142000000), '142 Mbps');
    expect(RouterWidgetMappers.formatMbps(null), isNull);
  });
}
