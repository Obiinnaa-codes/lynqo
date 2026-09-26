import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lynqo/features/router/data/auth/att_wifi/att_wifi_auth_investigator.dart';
import 'package:lynqo/features/router/data/auth/att_wifi/att_wifi_auth_spec.dart';
import 'package:lynqo/features/router/data/network/router_http_response.dart';

void main() {
  test('investigator detects login form in fixture HTML', () {
    final html = File('test/fixtures/att_wifi/login_page.html')
        .readAsStringSync();
    const investigator = AttWifiAuthInvestigator();
    final result = investigator.investigateHtml(html);

    expect(result.loginFormDetected, isTrue);
    expect(result.authenticationEndpoint, AttWifiAuthSpec.authenticationPath);
    expect(result.passwordFieldName, AttWifiAuthSpec.passwordFormField);
    expect(result.httpMethod, AttWifiAuthSpec.httpMethodPost);
  });

  test('login response parser maps success and invalid password', () {
    expect(
      AttWifiLoginResponseParser.parse('{"success": true}'),
      isA<AttWifiLoginSuccess>(),
    );
    expect(
      AttWifiLoginResponseParser.parse(
        '{"errno": 2, "errdetail": "session.password"}',
      ),
      isA<AttWifiLoginInvalidCredentials>(),
    );
    expect(
      AttWifiLoginResponseParser.parse('{"errno": 2}'),
      isA<AttWifiLoginInvalidCredentials>(),
    );
    expect(
      AttWifiLoginResponseParser.parse(
        '{"errNo": 2, "errDetail": "session.password"}',
      ),
      isA<AttWifiLoginInvalidCredentials>(),
    );
    expect(
      AttWifiLoginResponseParser.parse('not json'),
      isA<AttWifiLoginUnexpected>(),
    );
  });

  test('session parser reads cookie and model fields from synthetic data', () {
    final sessionId = AttWifiSessionParser.sessionIdFromBootstrap(
      RouterHttpResponse(
        statusCode: 200,
        headers: {
          'set-cookie': ['sessionId=REDACTED-SESSION-VALUE; path=/; HttpOnly'],
        },
        body: '',
        requestUrl: 'http://attwifimanager/index.html',
        redirectDetected: false,
      ),
    );
    expect(sessionId, 'REDACTED-SESSION-VALUE');

    final token = AttWifiSessionParser.secTokenFromModelBody(
      '{"session": {"secToken": "REDACTED-TOKEN", "userRole": "Guest"}}',
    );
    expect(token, 'REDACTED-TOKEN');

    final role = AttWifiSessionParser.userRoleFromModelBody(
      '{"session": {"userRole": "Admin"}}',
    );
    expect(role, AttWifiAuthSpec.adminUserRole);
  });
}
