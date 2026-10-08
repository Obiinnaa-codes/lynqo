import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lynqo/features/widget_kit/domain/lynqo_widget_type.dart';
import 'package:lynqo/features/widget_kit/layout/lynqo_dashboard_layout.dart';
import 'package:lynqo/features/widget_kit/layout/lynqo_widget_grid.dart';
import 'widget_snapshot_fixtures.dart';
import 'package:lynqo/features/widget_kit/sizing/lynqo_widget_size.dart';
import 'package:lynqo/features/widget_kit/theme/lynqo_widget_theme.dart';

void main() {
  testWidgets('grid renders overview widget', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [LynqoWidgetTheme.light]),
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: LynqoWidgetGrid(
              snapshot: syncedWidgetSnapshotFixture(),
              entries: const [
                LynqoWidgetGridEntry(
                  type: LynqoWidgetType.routerOverview,
                  size: LynqoWidgetSize.large,
                  columnSpan: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('MyHotspot'), findsOneWidget);
  });

  testWidgets('grid places span-1 tiles side by side', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData(extensions: const [LynqoWidgetTheme.light]),
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: LynqoWidgetGrid(
                snapshot: syncedWidgetSnapshotFixture(),
                routerStatus: routerStatusFixture(),
                entries: const [
                  LynqoWidgetGridEntry(
                    type: LynqoWidgetType.dataUsage,
                    size: LynqoWidgetSize.medium,
                  ),
                  LynqoWidgetGridEntry(
                    type: LynqoWidgetType.wifiProfile,
                    size: LynqoWidgetSize.medium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Data usage'), findsOneWidget);
    expect(find.text('Wi‑Fi'), findsOneWidget);
    final dataBox = tester.getRect(find.text('Data usage'));
    final wifiBox = tester.getRect(find.text('Wi‑Fi'));
    expect(dataBox.top, closeTo(wifiBox.top, 1));
    expect(dataBox.left, lessThan(wifiBox.left));
  });

  testWidgets('dashboard layout does not overflow on a phone width', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData(extensions: const [LynqoWidgetTheme.light]),
          home: Scaffold(
            body: SizedBox(
              width: 390,
              child: SingleChildScrollView(
                child: LynqoWidgetGrid(
                  snapshot: syncedWidgetSnapshotFixture(),
                  routerStatus: routerStatusFixture(),
                  entries: LynqoDashboardLayout.entries,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Data usage'), findsNothing);
    expect(find.text('Wi‑Fi'), findsNothing);
    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('MyHotspot'), findsOneWidget);
    expect(find.text('Connected devices'), findsNothing);
  });
}
