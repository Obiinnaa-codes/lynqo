import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lynqo/features/router/presentation/providers/router_providers.dart';
import 'package:lynqo/main.dart';

import '../router/mocks/fake_router_repository.dart';
import '../../support/login_test_helpers.dart';

Finder get usernameFieldFinder => find.byType(TextField).first;

Finder get passwordFieldFinder => find.byType(TextField).last;

TextField usernameField(WidgetTester tester) {
  return tester.widget<TextField>(usernameFieldFinder);
}

TextField passwordField(WidgetTester tester) {
  return tester.widget<TextField>(passwordFieldFinder);
}

Future<void> pumpLogin(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        routerRepositoryProvider.overrideWithValue(FakeRouterRepository()),
      ],
      child: const LynqoApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> typeCharacterByCharacter(
  WidgetTester tester,
  Finder field,
  String value,
) async {
  await tester.tap(field);
  await tester.pump();
  for (var i = 0; i < value.length; i++) {
    final partial = value.substring(0, i + 1);
    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: partial,
        selection: TextSelection.collapsed(offset: partial.length),
      ),
    );
    await tester.pump();
  }
}

void main() {
  group('Login text input', () {
    testWidgets('username controller accumulates admin character by character', (
      WidgetTester tester,
    ) async {
      await pumpLogin(tester);
      await typeCharacterByCharacter(tester, usernameFieldFinder, 'admin');

      expect(usernameField(tester).controller!.text, 'admin');
      expect(find.text('admin'), findsOneWidget);
    });

    testWidgets('password controller holds testPassword123', (
      WidgetTester tester,
    ) async {
      await pumpLogin(tester);
      await typeCharacterByCharacter(
        tester,
        passwordFieldFinder,
        'testPassword123',
      );

      expect(passwordField(tester).controller!.text, 'testPassword123');
    });

    testWidgets('password controller unchanged when obscureText toggles', (
      WidgetTester tester,
    ) async {
      await pumpLogin(tester);

      const password = 'testPassword123';
      await tester.enterText(passwordFieldFinder, password);
      await tester.pump();

      expect(passwordField(tester).controller!.text, password);

      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(passwordField(tester).controller!.text, password);

      await tester.tap(find.byTooltip('Hide password'));
      await tester.pump();
      expect(passwordField(tester).controller!.text, password);
    });

    testWidgets('username survives sibling Connect loading rebuild', (
      WidgetTester tester,
    ) async {
      await pumpLogin(tester);

      const username = 'admin123';
      await tester.enterText(usernameFieldFinder, username);
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Connect'));
      await tester.pump();

      expect(usernameField(tester).controller!.text, username);
    });

    testWidgets('username survives keyboard inset change', (
      WidgetTester tester,
    ) async {
      await pumpLogin(tester);

      await tester.enterText(usernameFieldFinder, 'admin');
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

      expect(usernameField(tester).controller!.text, 'admin');
      expect(find.text('admin'), findsOneWidget);
    });

    testWidgets('focus switch preserves both field values', (
      WidgetTester tester,
    ) async {
      await pumpLogin(tester);

      await tester.enterText(usernameFieldFinder, 'admin123');
      await tester.pump();

      await tester.tap(passwordFieldFinder);
      await tester.pump();

      await tester.enterText(passwordFieldFinder, 'testPassword123');
      await tester.pump();

      expect(usernameField(tester).controller!.text, 'admin123');
      expect(passwordField(tester).controller!.text, 'testPassword123');
    });

    testWidgets('validation errors do not clear controller text', (
      WidgetTester tester,
    ) async {
      await pumpLogin(tester);

      await tester.enterText(usernameFieldFinder, 'admin');
      await tester.pump();

      await tapConnectButton(tester);

      expect(find.text('Password is required'), findsOneWidget);
      expect(usernameField(tester).controller!.text, 'admin');
    });

  });
}
