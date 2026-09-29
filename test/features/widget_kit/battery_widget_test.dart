import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lynqo/features/widget_kit/domain/models/widget_view_models.dart';
import 'package:lynqo/features/widget_kit/sizing/lynqo_widget_size.dart';
import 'package:lynqo/features/widget_kit/theme/lynqo_widget_theme.dart';
import 'package:lynqo/features/widget_kit/widgets/battery_widget.dart';

void main() {
  testWidgets('battery widget shows percent', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [LynqoWidgetTheme.light]),
        home: const Scaffold(
          body: BatteryWidget(
            size: LynqoWidgetSize.small,
            data: BatteryWidgetData(percent: 94),
          ),
        ),
      ),
    );

    expect(find.text('94%'), findsOneWidget);
  });

  testWidgets('battery widget omits missing percent', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [LynqoWidgetTheme.light]),
        home: const Scaffold(
          body: BatteryWidget(
            size: LynqoWidgetSize.small,
            data: BatteryWidgetData(),
          ),
        ),
      ),
    );

    expect(find.text('—'), findsOneWidget);
  });
}
