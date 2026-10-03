import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lynqo/features/widget_kit/domain/lynqo_widget_type.dart';
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
}
