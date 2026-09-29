import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> tapConnectButton(WidgetTester tester) async {
  final connect = find.widgetWithText(FilledButton, 'Connect');
  await tester.ensureVisible(connect);
  await tester.pumpAndSettle();
  await tester.tap(connect);
  await tester.pumpAndSettle();
}
