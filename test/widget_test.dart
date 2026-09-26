import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lynqo/features/router/presentation/providers/router_providers.dart';
import 'package:lynqo/main.dart';

import 'features/router/mocks/fake_router_repository.dart';

void main() {
  testWidgets('Login screen shows validation when Connect is tapped empty', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          routerRepositoryProvider.overrideWithValue(FakeRouterRepository()),
        ],
        child: const LynqoApp(),
      ),
    );
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
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          routerRepositoryProvider.overrideWithValue(FakeRouterRepository()),
        ],
        child: const LynqoApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'user');
    await tester.enterText(find.byType(TextField).last, 'secret');
    await tester.tap(find.widgetWithText(FilledButton, 'Connect'));
    await tester.pumpAndSettle();

    expect(find.text('Connect to your MiFi'), findsOneWidget);
    expect(find.text('Login successful'), findsNothing);
  });

  testWidgets('Username field keeps full entered text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          routerRepositoryProvider.overrideWithValue(FakeRouterRepository()),
        ],
        child: const LynqoApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'admin');
    await tester.pump();

    expect(find.text('admin'), findsOneWidget);
  });

  testWidgets('Username survives keyboard inset rebuild', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          routerRepositoryProvider.overrideWithValue(FakeRouterRepository()),
        ],
        child: const LynqoApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'admin');
    await tester.pump();

    final originalViewInsets = tester.view.viewInsets;
    tester.view.viewInsets = FakeViewPadding(
      bottom: 300,
      left: originalViewInsets.left,
      right: originalViewInsets.right,
      top: originalViewInsets.top,
    );
    addTearDown(() => tester.view.viewInsets = originalViewInsets);
    await tester.pump();

    expect(find.text('admin'), findsOneWidget);
  });
}
