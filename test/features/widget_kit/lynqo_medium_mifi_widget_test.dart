import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lynqo/features/widget_kit/domain/lynqo_router_widget_snapshot.dart';
import 'package:lynqo/features/widget_kit/domain/models/widget_view_models.dart';
import 'package:lynqo/features/widget_kit/presentation/lynqo_medium_mifi_presentation.dart';
import 'package:lynqo/features/widget_kit/theme/lynqo_widget_colors.dart';
import 'package:lynqo/features/widget_kit/theme/lynqo_widget_theme.dart';
import 'package:lynqo/features/widget_kit/widgets/lynqo_medium_mifi_widget.dart';

void main() {
  LynqoRouterWidgetSnapshot synced({
    int? batteryPercent,
    String? usedSummary,
    String? limitSummary,
    int? usagePercent,
    int? deviceCount,
  }) {
    return LynqoRouterWidgetSnapshot(
      updatedAt: DateTime.utc(2026, 1, 1),
      battery: BatteryWidgetData(percent: batteryPercent),
      dataUsage: DataUsageWidgetData(
        usedSummary: usedSummary,
        limitSummary: limitSummary,
        usagePercent: usagePercent,
      ),
      signal: const SignalWidgetData(),
      connection: const ConnectionWidgetData(),
      devices: ConnectedDevicesWidgetData(count: deviceCount),
      networkSpeed: const NetworkSpeedWidgetData(),
      routerOverview: RouterOverviewWidgetData(
        routerName: 'MiFi',
        battery: BatteryWidgetData(percent: batteryPercent),
        dataUsage: DataUsageWidgetData(
          usedSummary: usedSummary,
          limitSummary: limitSummary,
          usagePercent: usagePercent,
        ),
        devices: ConnectedDevicesWidgetData(count: deviceCount),
      ),
    );
  }

  test('presentation keeps used amount when plan is invalid', () {
    final snapshot = synced(
      usedSummary: '75.6 MB',
      usagePercent: null,
    );
    final unavailable = LynqoRouterWidgetSnapshot(
      updatedAt: DateTime.utc(2026, 1, 1),
      battery: const BatteryWidgetData(),
      dataUsage: const DataUsageWidgetData(
        usedSummary: '75.6 MB',
        remainingSummary: '39.7 MB remaining',
        planUnavailable: true,
      ),
      signal: const SignalWidgetData(),
      connection: const ConnectionWidgetData(),
      devices: const ConnectedDevicesWidgetData(),
      networkSpeed: const NetworkSpeedWidgetData(),
      routerOverview: const RouterOverviewWidgetData(routerName: 'MiFi'),
    );
    expect(LynqoMediumMiFiPresentation.dataPrimary(unavailable), '75.6 MB');
    expect(
      LynqoMediumMiFiPresentation.dataSecondary(unavailable),
      '39.7 MB remaining',
    );
    expect(LynqoMediumMiFiPresentation.dataPrimary(snapshot), isNot('—'));
  });

  test('presentation formats data secondary as of limit', () {
    final snapshot = synced(
      usedSummary: '12.4 GB',
      limitSummary: '50 GB',
      usagePercent: 25,
    );
    expect(
      LynqoMediumMiFiPresentation.dataSecondary(snapshot),
      'of 50 GB',
    );
  });

  test('presentation omits fake battery when unsynced', () {
    final snapshot = synced(batteryPercent: 94);
    final unsynced = LynqoRouterWidgetSnapshot(
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      battery: const BatteryWidgetData(percent: 94),
      dataUsage: const DataUsageWidgetData(),
      signal: const SignalWidgetData(),
      connection: const ConnectionWidgetData(),
      devices: const ConnectedDevicesWidgetData(),
      networkSpeed: const NetworkSpeedWidgetData(),
      routerOverview: const RouterOverviewWidgetData(routerName: 'MiFi'),
    );
    expect(LynqoMediumMiFiPresentation.batteryPrimary(unsynced), '—');
    expect(LynqoMediumMiFiPresentation.batteryPrimary(snapshot), '94%');
  });

  test('battery vial fill is green above 20% and red at or below 20%', () {
    expect(LynqoWidgetColors.batteryLevel(21), LynqoWidgetColors.accentGreen);
    expect(LynqoWidgetColors.batteryLevel(20), LynqoWidgetColors.accentRed);
    expect(LynqoWidgetColors.batteryLevel(5), LynqoWidgetColors.accentRed);
  });

  test('battery ring is green above 20% and red at or below 20%', () {
    expect(
      LynqoMediumMiFiPresentation.batteryProgressColor(
        synced(batteryPercent: 100),
      ),
      LynqoWidgetColors.accentGreen,
    );
    expect(
      LynqoMediumMiFiPresentation.batteryProgressColor(
        synced(batteryPercent: 21),
      ),
      LynqoWidgetColors.accentGreen,
    );
    expect(
      LynqoMediumMiFiPresentation.batteryProgressColor(
        synced(batteryPercent: 20),
      ),
      LynqoWidgetColors.accentRed,
    );
    expect(
      LynqoMediumMiFiPresentation.batteryProgressColor(
        synced(batteryPercent: 5),
      ),
      LynqoWidgetColors.accentRed,
    );
  });

  testWidgets('medium home widget shows four metric labels', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [LynqoWidgetTheme.light]),
        home: Scaffold(
          body: LynqoMediumMiFiWidget(
            snapshot: synced(
              batteryPercent: 94,
              usedSummary: '12.4 GB',
              limitSummary: '50 GB',
              usagePercent: 25,
              deviceCount: 3,
            ),
          ),
        ),
      ),
    );

    expect(find.text('94%'), findsOneWidget);
    expect(find.text('12.4 GB'), findsOneWidget);
    expect(find.text('of 50 GB'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Restart'), findsOneWidget);
    expect(find.text('Battery'), findsNothing);
    expect(find.text('Devices'), findsNothing);
    expect(find.text('MiFi'), findsNothing);
  });

  testWidgets('unsynced snapshot shows dashes not mock percents', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [LynqoWidgetTheme.light]),
        home: Scaffold(
          body: LynqoMediumMiFiWidget(
            snapshot: LynqoRouterWidgetSnapshot(
              updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
              battery: const BatteryWidgetData(percent: 94),
              dataUsage: const DataUsageWidgetData(usedSummary: '12.4 GB'),
              signal: const SignalWidgetData(),
              connection: const ConnectionWidgetData(),
              devices: const ConnectedDevicesWidgetData(count: 3),
              networkSpeed: const NetworkSpeedWidgetData(),
              routerOverview: const RouterOverviewWidgetData(routerName: 'MiFi'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('94%'), findsNothing);
    expect(find.text('12.4 GB'), findsNothing);
    expect(find.text('3'), findsNothing);
    expect(find.text('—'), findsNWidgets(3));
  });
}
