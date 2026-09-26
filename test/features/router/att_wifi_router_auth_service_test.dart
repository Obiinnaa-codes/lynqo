import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lynqo/features/router/config/router_config.dart';
import 'package:lynqo/features/router/config/router_profile_catalog.dart';
import 'package:lynqo/features/router/data/auth/att_wifi/att_wifi_auth_spec.dart';
import 'package:lynqo/features/router/data/auth/att_wifi/att_wifi_router_auth_service.dart';
import 'package:lynqo/features/router/data/auth/router_secure_storage.dart';
import 'package:lynqo/features/router/data/network/router_client_factory.dart';
import 'package:lynqo/features/router/domain/router_authentication_state.dart';
import 'package:lynqo/features/router/domain/router_failure.dart';

import 'mocks/mock_http_adapter.dart';

void main() {
  const fakeSessionId = 'REDACTED-SESSION-ID';
  const fakeSecToken = 'REDACTED-SEC-TOKEN';
  const fakePassword = 'fake-router-password';

  AttWifiRouterAuthService buildService({
    required Future<ResponseBody> Function(RequestOptions options) handler,
    bool resetSecureStorage = true,
  }) {
    if (resetSecureStorage) {
      FlutterSecureStorage.setMockInitialValues({});
    }
    final transport = RouterConfig.development();
    final factory = RouterClientFactory(
      transportConfig: transport,
      dioFactory: (config, {CookieJar? cookieJar}) {
        final dio = Dio(
          BaseOptions(baseUrl: config.baseUrl, validateStatus: (_) => true),
        );
        dio.httpClientAdapter = MockHttpAdapter(handler);
        return dio;
      },
    );
    return AttWifiRouterAuthService(
      clientFactory: factory,
      secureStorage: RouterSecureStorage(),
    );
  }

  Future<ResponseBody> bootstrapResponse() async {
    return mockResponse(
      statusCode: 200,
      body: '<html></html>',
      headers: {
        'set-cookie': ['sessionId=$fakeSessionId; path=/; HttpOnly'],
      },
    );
  }

  Future<ResponseBody> guestModelResponse() async {
    return mockResponse(
      statusCode: 200,
      body:
          '{"session": {"secToken": "$fakeSecToken", "userRole": "${AttWifiAuthSpec.guestUserRole}"}}',
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  test('successful authentication', () async {
    var authenticated = false;
    final service = buildService(
      handler: (options) async {
        if (options.path == '/' && options.method == 'GET') {
          return bootstrapResponse();
        }
        if (options.path.contains('model.json')) {
          return mockResponse(
            statusCode: 200,
            body: authenticated
                ? '{"session": {"secToken": "$fakeSecToken", "userRole": "${AttWifiAuthSpec.adminUserRole}"}}'
                : '{"session": {"secToken": "$fakeSecToken", "userRole": "${AttWifiAuthSpec.guestUserRole}"}}',
            headers: {
              'content-type': ['application/json'],
            },
          );
        }
        if (options.path == AttWifiAuthSpec.authenticationPath &&
            options.method == 'POST') {
          authenticated = true;
          return mockResponse(
            statusCode: 200,
            body: '{"success": true}',
            headers: {
              'content-type': ['application/json'],
            },
          );
        }
        return mockResponse(statusCode: 404);
      },
    );

    final result = await service.login(
      username: 'admin',
      password: fakePassword,
      profile: RouterProfileCatalog.attWifi,
    );

    expect(result.state, RouterAuthenticationState.authenticated);
    expect(await service.isAuthenticated(), isTrue);
  });

  test('successful authentication via POST 302 to success.json', () async {
    var authenticated = false;
    String? redirectRequestCookie;
    final service = buildService(
      handler: (options) async {
        if (options.path == '/' && options.method == 'GET') {
          return bootstrapResponse();
        }
        if (options.path.contains('model.json')) {
          return mockResponse(
            statusCode: 200,
            body: authenticated
                ? '{"session": {"secToken": "$fakeSecToken", "userRole": "${AttWifiAuthSpec.adminUserRole}"}}'
                : '{"session": {"secToken": "$fakeSecToken", "userRole": "${AttWifiAuthSpec.guestUserRole}"}}',
          );
        }
        if (options.path == AttWifiAuthSpec.authenticationPath &&
            options.method == 'POST') {
          authenticated = true;
          return mockResponse(
            statusCode: 302,
            body: '',
            headers: {
              'location': [AttWifiAuthSpec.successRedirectPath],
            },
          );
        }
        if (options.path == AttWifiAuthSpec.successRedirectPath &&
            options.method == 'GET') {
          redirectRequestCookie = options.headers['Cookie'] as String?;
          return mockResponse(statusCode: 200, body: '{"success": true}');
        }
        return mockResponse(statusCode: 404);
      },
    );

    final result = await service.login(
      username: 'admin',
      password: fakePassword,
      profile: RouterProfileCatalog.attWifi,
    );

    expect(result.state, RouterAuthenticationState.authenticated);
    expect(redirectRequestCookie, contains('sessionId=$fakeSessionId'));
  });

  test('incorrect password via POST 302 to error.json', () async {
    final service = buildService(
      handler: (options) async {
        if (options.path == '/' && options.method == 'GET') {
          return bootstrapResponse();
        }
        if (options.path.contains('model.json')) {
          return guestModelResponse();
        }
        if (options.path == AttWifiAuthSpec.authenticationPath &&
            options.method == 'POST') {
          return mockResponse(
            statusCode: 302,
            body: '',
            headers: {
              'location': [AttWifiAuthSpec.errorRedirectPath],
            },
          );
        }
        if (options.path == AttWifiAuthSpec.errorRedirectPath &&
            options.method == 'GET') {
          return mockResponse(
            statusCode: 200,
            body:
                '{"errNo": 2, "errDetail": "${AttWifiAuthSpec.invalidPasswordErrorDetail}"}',
          );
        }
        return mockResponse(statusCode: 404);
      },
    );

    final result = await service.login(
      username: 'admin',
      password: 'wrong-password',
      profile: RouterProfileCatalog.attWifi,
    );

    expect(result.state, RouterAuthenticationState.failed);
    expect(result.message, 'Incorrect username or password.');
  });

  test('POST 302 without Location is unexpected', () async {
    final service = buildService(
      handler: (options) async {
        if (options.path == '/' && options.method == 'GET') {
          return bootstrapResponse();
        }
        if (options.path.contains('model.json')) {
          return guestModelResponse();
        }
        if (options.path == AttWifiAuthSpec.authenticationPath &&
            options.method == 'POST') {
          return mockResponse(statusCode: 302, body: '');
        }
        return mockResponse(statusCode: 404);
      },
    );

    final result = await service.login(
      username: 'admin',
      password: fakePassword,
      profile: RouterProfileCatalog.attWifi,
    );

    expect(result.state, RouterAuthenticationState.failed);
    expect(result.failure, isA<InvalidResponse>());
  });

  test('incorrect password', () async {
    final service = buildService(
      handler: (options) async {
        if (options.path == '/' && options.method == 'GET') {
          return bootstrapResponse();
        }
        if (options.path.contains('model.json')) {
          return guestModelResponse();
        }
        if (options.path == AttWifiAuthSpec.authenticationPath) {
          return mockResponse(
            statusCode: 200,
            body:
                '{"errno": 2, "errdetail": "${AttWifiAuthSpec.invalidPasswordErrorDetail}"}',
          );
        }
        return mockResponse(statusCode: 404);
      },
    );

    final result = await service.login(
      username: 'admin',
      password: 'wrong-password',
      profile: RouterProfileCatalog.attWifi,
    );

    expect(result.state, RouterAuthenticationState.failed);
    expect(result.failure, isA<AuthenticationFailed>());
    expect(result.message, 'Incorrect username or password.');
  });

  test('POST success without Admin role fails login', () async {
    final service = buildService(
      handler: (options) async {
        if (options.path == '/' && options.method == 'GET') {
          return bootstrapResponse();
        }
        if (options.path.contains('model.json')) {
          return guestModelResponse();
        }
        if (options.path == AttWifiAuthSpec.authenticationPath &&
            options.method == 'POST') {
          return mockResponse(
            statusCode: 200,
            body: '{"success": true}',
            headers: {
              'content-type': ['application/json'],
            },
          );
        }
        return mockResponse(statusCode: 404);
      },
    );

    final result = await service.login(
      username: 'admin',
      password: fakePassword,
      profile: RouterProfileCatalog.attWifi,
    );

    expect(result.state, RouterAuthenticationState.failed);
    expect(result.failure, isA<InvalidResponse>());
  });

  test('connection timeout during login', () async {
    final service = buildService(
      handler: (_) async {
        throw DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.receiveTimeout,
        );
      },
    );

    final result = await service.login(
      username: 'admin',
      password: fakePassword,
      profile: RouterProfileCatalog.attWifi,
    );

    expect(result.state, RouterAuthenticationState.failed);
    expect(result.failure, isA<ConnectionTimeout>());
  });

  test('expired session on restore', () async {
    FlutterSecureStorage.setMockInitialValues({
      RouterSecureStorage.sessionActiveKey: 'true',
      RouterSecureStorage.sessionProfileKey: AttWifiAuthSpec.profileId,
      RouterSecureStorage.attSessionIdKey: fakeSessionId,
    });

    final service = buildService(
      resetSecureStorage: false,
      handler: (options) async {
        if (options.path.contains('model.json')) {
          return mockResponse(statusCode: 403, body: '{"errno": 1}');
        }
        return mockResponse(statusCode: 404);
      },
    );

    final state = await service.restoreSession();
    expect(state, RouterAuthenticationState.failed);
    expect(await service.isAuthenticated(), isFalse);
  });

  test('missing session on restore', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final service = buildService(
      handler: (_) async => mockResponse(statusCode: 200),
    );

    expect(
      await service.restoreSession(),
      RouterAuthenticationState.unauthenticated,
    );
  });

  test('unexpected router response during login', () async {
    final service = buildService(
      handler: (options) async {
        if (options.path == '/' && options.method == 'GET') {
          return bootstrapResponse();
        }
        if (options.path.contains('model.json')) {
          return guestModelResponse();
        }
        if (options.path == AttWifiAuthSpec.authenticationPath) {
          return mockResponse(statusCode: 200, body: '<html>unexpected</html>');
        }
        return mockResponse(statusCode: 404);
      },
    );

    final result = await service.login(
      username: 'admin',
      password: fakePassword,
      profile: RouterProfileCatalog.attWifi,
    );

    expect(result.state, RouterAuthenticationState.failed);
    expect(result.failure, isA<InvalidResponse>());
  });

  test('router unavailable during login', () async {
    final service = buildService(
      handler: (_) async {
        throw DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.connectionError,
        );
      },
    );

    final result = await service.login(
      username: 'admin',
      password: fakePassword,
      profile: RouterProfileCatalog.attWifi,
    );

    expect(result.state, RouterAuthenticationState.failed);
    expect(result.failure, isA<RouterNotReachable>());
  });
}
