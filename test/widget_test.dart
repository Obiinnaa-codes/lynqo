import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lynqo/main.dart';

void main() {
  testWidgets('Login screen shows validation when Connect is tapped empty', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: LynqoApp()));
    await tester.pumpAndSettle();

    expect(find.text('Connect to your MiFi'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Connect'));
    await tester.pumpAndSettle();

    expect(find.text('Username is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('Valid credentials stay on login without success message', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: LynqoApp()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'user');
    await tester.enterText(find.byType(TextField).last, 'secret');
    await tester.tap(find.widgetWithText(FilledButton, 'Connect'));
    await tester.pumpAndSettle();

    expect(find.text('Connect to your MiFi'), findsOneWidget);
    expect(find.text('Login successful'), findsNothing);
  });
}
