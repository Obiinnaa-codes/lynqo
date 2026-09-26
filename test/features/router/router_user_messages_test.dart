import 'package:flutter_test/flutter_test.dart';
import 'package:lynqo/features/router/config/router_profile_catalog.dart';
import 'package:lynqo/features/router/domain/router_authentication_state.dart';
import 'package:lynqo/features/router/domain/router_failure.dart';
import 'package:lynqo/features/router/presentation/router_user_messages.dart';

void main() {
  test('profile found messages are user-facing and non-technical', () {
    expect(
      RouterUserMessages.profileFound(RouterProfileCatalog.attWifi),
      'AT&T WiFi Manager found',
    );
    expect(
      RouterUserMessages.profileFound(RouterProfileCatalog.defaultMifi),
      'MiFi found',
    );

    final message = RouterUserMessages.profileFound(
      RouterProfileCatalog.attWifi,
    );
    expect(message.toLowerCase(), isNot(contains('sessionid')));
    expect(message, isNot(contains('HTTP')));
    expect(message, isNot(contains('Content-Type')));
  });

  test('failure mapping stays generic', () {
    expect(
      RouterUserMessages.fromFailure(
        const AuthenticationFailed(RouterUserMessages.incorrectCredentials),
      ),
      'Incorrect username or password.',
    );
    expect(
      RouterUserMessages.forAuthenticationState(
        profile: RouterProfileCatalog.attWifi,
        state: RouterAuthenticationState.authenticated,
      ),
      contains('AT&T WiFi Manager'),
    );
  });
}
