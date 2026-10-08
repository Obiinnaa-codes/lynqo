import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
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
        final jar = cookieJar ?? CookieJar();
        final dio = Dio(
          BaseOptions(baseUrl: config.baseUrl, validateStatus: (_) => true),
        );
        dio.interceptors.add(CookieManager(jar));
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
  });

  test(
    'post-login model uses jar only without bootstrap sessionId query',
    () async {
      const authenticatedSessionId = 'AUTHENTICATED-SESSION-ID';
      var authenticated = false;
      String? postLoginExplicitCookie;
      String? postLoginSessionQuery;
      String? postLoginCacheBust;
      String? postLoginInternalApi;
      final service = buildService(
        handler: (options) async {
          if (options.path == '/' && options.method == 'GET') {
            return bootstrapResponse();
          }
          if (options.path.contains('model.json')) {
            if (authenticated) {
              postLoginExplicitCookie = options.headers['Cookie'] as String?;
              postLoginSessionQuery =
                  options.queryParameters[AttWifiAuthSpec.sessionIdQueryParameter];
              postLoginCacheBust =
                  options.queryParameters[AttWifiAuthSpec.cacheBustQueryParameter];
              postLoginInternalApi =
                  options.queryParameters[AttWifiAuthSpec.internalApiQueryFlag];
            }
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
            expect(
              options.queryParameters[AttWifiAuthSpec.sessionIdQueryParameter],
              fakeSessionId,
            );
            return mockResponse(
              statusCode: 302,
              body: '',
              headers: {
                'location': [AttWifiAuthSpec.successRedirectPath],
                'set-cookie': [
                  'sessionId=$authenticatedSessionId; Path=/; HttpOnly',
                ],
              },
            );
          }
          if (options.path == AttWifiAuthSpec.successRedirectPath &&
              options.method == 'GET') {
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
      expect(postLoginSessionQuery, isNull);
      expect(postLoginCacheBust, isNotNull);
      expect(postLoginInternalApi, AttWifiAuthSpec.internalApiQueryValue);
      expect(postLoginExplicitCookie, isNot(contains(fakeSessionId)));
    },
  );

  test('successful authentication via POST 302 to index.html (browser parity)', () async {
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
          );
        }
        if (options.path == AttWifiAuthSpec.authenticationPath &&
            options.method == 'POST') {
          authenticated = true;
          final body = options.data as String? ?? '';
          expect(body, contains('ok_redirect=%2Findex.html'));
          expect(body, contains('err_redirect=%2Findex.html%3Floginfailed'));
          return mockResponse(
            statusCode: 302,
            body: '',
            headers: {
              'location': [AttWifiAuthSpec.htmlOkRedirectPath],
            },
          );
        }
        if (options.path == AttWifiAuthSpec.loginPagePath &&
            options.method == 'GET') {
          return mockResponse(statusCode: 200, body: '<html></html>');
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
  });

  test('pre-login model uses internalapi, x, and sessionId query', () async {
    String? preLoginSessionQuery;
    String? preLoginCacheBust;
    String? preLoginInternalApi;
    final service = buildService(
      handler: (options) async {
        if (options.path == '/' && options.method == 'GET') {
          return bootstrapResponse();
        }
        if (options.path.contains('model.json')) {
          preLoginSessionQuery ??=
              options.queryParameters[AttWifiAuthSpec.sessionIdQueryParameter];
          preLoginCacheBust ??=
              options.queryParameters[AttWifiAuthSpec.cacheBustQueryParameter];
          preLoginInternalApi ??=
              options.queryParameters[AttWifiAuthSpec.internalApiQueryFlag];
          return guestModelResponse();
        }
        if (options.path == AttWifiAuthSpec.authenticationPath) {
          return mockResponse(statusCode: 200, body: '{"success": true}');
        }
        return mockResponse(statusCode: 404);
      },
    );

    await service.login(
      username: 'admin',
      password: fakePassword,
      profile: RouterProfileCatalog.attWifi,
    );

    expect(preLoginSessionQuery, fakeSessionId);
    expect(preLoginCacheBust, isNotNull);
    expect(preLoginInternalApi, AttWifiAuthSpec.internalApiQueryValue);
  });

  test('att_wifi login does not request 192.168.0.1', () async {
    final requestedHosts = <String>{};
    final service = buildService(
      handler: (options) async {
        requestedHosts.add(options.baseUrl);
        if (options.path == '/' && options.method == 'GET') {
          return bootstrapResponse();
        }
        if (options.path.contains('model.json')) {
          return guestModelResponse();
        }
        if (options.path == AttWifiAuthSpec.authenticationPath) {
          return mockResponse(statusCode: 200, body: '{"success": true}');
        }
        return mockResponse(statusCode: 404);
      },
    );

    await service.login(
      username: 'admin',
      password: fakePassword,
      profile: RouterProfileCatalog.attWifi,
    );

    expect(requestedHosts.every((url) => !url.contains('192.168.0.1')), isTrue);
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

  test('expired session on restore without password signs out', () async {
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
    expect(state, RouterAuthenticationState.unauthenticated);
    expect(await service.isAuthenticated(), isFalse);
  });

  test('unreachable MiFi on restore keeps local sign-in', () async {
    FlutterSecureStorage.setMockInitialValues({
      RouterSecureStorage.sessionActiveKey: 'true',
      RouterSecureStorage.sessionProfileKey: AttWifiAuthSpec.profileId,
      RouterSecureStorage.attSessionIdKey: fakeSessionId,
    });

    final service = buildService(
      resetSecureStorage: false,
      handler: (_) async {
        throw DioException(
          requestOptions: RequestOptions(path: '/api/model.json'),
          type: DioExceptionType.connectionError,
        );
      },
    );

    final state = await service.restoreSession();
    expect(state, RouterAuthenticationState.authenticated);
    expect(await service.isAuthenticated(), isTrue);
    expect(
      await RouterSecureStorage().readAttWifiSessionId(),
      fakeSessionId,
    );
  });

  test('expired session on restore silently re-logins', () async {
    const expiredSessionId = 'EXPIRED-SESSION-ID';
    var authenticated = false;
    FlutterSecureStorage.setMockInitialValues({
      RouterSecureStorage.sessionActiveKey: 'true',
      RouterSecureStorage.sessionProfileKey: AttWifiAuthSpec.profileId,
      RouterSecureStorage.attSessionIdKey: expiredSessionId,
      RouterSecureStorage.rememberedPasswordKey: fakePassword,
    });

    final service = buildService(
      resetSecureStorage: false,
      handler: (options) async {
        if (options.path == '/' && options.method == 'GET') {
          return bootstrapResponse();
        }
        if (options.path.contains('model.json')) {
          final cookie = options.headers['Cookie'] as String? ?? '';
          if (cookie.contains(expiredSessionId) && !authenticated) {
            return mockResponse(statusCode: 403, body: '{"errno": 1}');
          }
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
          return mockResponse(statusCode: 200, body: '{"success": true}');
        }
        return mockResponse(statusCode: 404);
      },
    );

    final state = await service.restoreSession();
    expect(state, RouterAuthenticationState.authenticated);
    expect(await service.isAuthenticated(), isTrue);
    expect(
      await RouterSecureStorage().readAttWifiSessionId(),
      fakeSessionId,
    );
  });

  test('logout without remember password clears stored password', () async {
    FlutterSecureStorage.setMockInitialValues({
      RouterSecureStorage.sessionActiveKey: 'true',
      RouterSecureStorage.sessionProfileKey: AttWifiAuthSpec.profileId,
      RouterSecureStorage.attSessionIdKey: fakeSessionId,
      RouterSecureStorage.rememberedPasswordKey: fakePassword,
    });
    final storage = RouterSecureStorage();
    final service = buildService(
      resetSecureStorage: false,
      handler: (_) async => mockResponse(statusCode: 404),
    );

    await service.logout();

    expect(await storage.isSessionActive(), isFalse);
    expect(await storage.readSignedInPassword(), isNull);
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
