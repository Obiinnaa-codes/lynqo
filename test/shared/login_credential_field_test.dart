import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lynqo/shared/widgets/login_credential_field.dart';

void main() {
  test('LoginCredentialField uses stable iOS input path on iOS target', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    expect(LoginCredentialField.useIosStableTextInput, isTrue);
  });

  test('LoginCredentialField uses direct Material field on Android target', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    expect(LoginCredentialField.useIosStableTextInput, isFalse);
  });
}
