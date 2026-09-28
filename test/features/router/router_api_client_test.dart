import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lynqo/features/router/config/router_config.dart';
import 'package:lynqo/features/router/config/router_profile_catalog.dart';
import 'package:lynqo/features/router/data/auth/att_wifi/att_wifi_auth_spec.dart';
import 'package:lynqo/features/router/data/network/router_network_service.dart';
import 'package:lynqo/features/router/data/router_api_client.dart';

import 'mocks/mock_http_adapter.dart';

void main() {
  const bootstrapSessionId = 'BOOTSTRAP-SESSION-ID';

  RouterApiClient buildClient({
    required Future<ResponseBody> Function(RequestOptions options) handler,
  }) {
    final config = RouterConfig.development().forProfile(
      RouterProfileCatalog.attWifi,
    );
    final jar = CookieJar();
    final dio = Dio(
      BaseOptions(baseUrl: config.baseUrl, validateStatus: (_) => true),
    );
    dio.interceptors.add(CookieManager(jar));
    dio.httpClientAdapter = MockHttpAdapter(handler);
    final network = RouterNetworkService(
      dio: dio,
      config: config,
      cookieJar: jar,
    );
    return RouterApiClient(network);
  }

  test('bootstrap Set-Cookie is readable from jar', () async {
    final client = buildClient(
      handler: (options) async {
        if (options.path == '/' && options.method == 'GET') {
          return mockResponse(
            statusCode: 200,
            body: '<html></html>',
            headers: {
              'set-cookie': [
                'sessionId=$bootstrapSessionId; Path=/; HttpOnly',
              ],
            },
          );
        }
        return mockResponse(statusCode: 404);
      },
    );

    await client.getRoot();
    expect(await client.readSessionIdFromCookieJar(), bootstrapSessionId);
  });

  test('authenticated model request omits sessionId query', () async {
    String? sessionQuery;
    String? cacheBust;
    String? internalApi;
    final client = buildClient(
      handler: (options) async {
        if (options.path.contains('model.json')) {
          sessionQuery =
              options.queryParameters[AttWifiAuthSpec.sessionIdQueryParameter];
          cacheBust =
              options.queryParameters[AttWifiAuthSpec.cacheBustQueryParameter];
          internalApi =
              options.queryParameters[AttWifiAuthSpec.internalApiQueryFlag];
          return mockResponse(statusCode: 200, body: '{"session": {}}');
        }
        return mockResponse(statusCode: 404);
      },
    );

    await client.fetchAttWifiModelAuthenticated();
    expect(sessionQuery, isNull);
    expect(cacheBust, isNotNull);
    expect(internalApi, AttWifiAuthSpec.internalApiQueryValue);
  });

  test('login POST includes sessionId query when jar has bootstrap session', () async {
    String? loginSessionQuery;
    final client = buildClient(
      handler: (options) async {
        if (options.path == '/' && options.method == 'GET') {
          return mockResponse(
            statusCode: 200,
            body: '',
            headers: {
              'set-cookie': [
                'sessionId=$bootstrapSessionId; Path=/; HttpOnly',
              ],
            },
          );
        }
        if (options.path == AttWifiAuthSpec.authenticationPath &&
            options.method == 'POST') {
          loginSessionQuery =
              options.queryParameters[AttWifiAuthSpec.sessionIdQueryParameter];
          return mockResponse(statusCode: 200, body: '{"success": true}');
        }
        return mockResponse(statusCode: 404);
      },
    );

    await client.getRoot();
    await client.submitAttWifiForm(
      sessionIdQuery: bootstrapSessionId,
      fields: {'token': 'x'},
    );
    expect(loginSessionQuery, bootstrapSessionId);
  });

  test('login POST does not send stale explicit Cookie when jar has session', () async {
    String? loginCookieHeader;
    final client = buildClient(
      handler: (options) async {
        if (options.path == '/' && options.method == 'GET') {
          return mockResponse(
            statusCode: 200,
            body: '',
            headers: {
              'set-cookie': [
                'sessionId=$bootstrapSessionId; Path=/; HttpOnly',
              ],
            },
          );
        }
        if (options.path == AttWifiAuthSpec.authenticationPath &&
            options.method == 'POST') {
          loginCookieHeader = options.headers['Cookie'] as String?;
          return mockResponse(statusCode: 200, body: '{"success": true}');
        }
        return mockResponse(statusCode: 404);
      },
    );

    await client.getRoot();
    await client.submitAttWifiForm(
      sessionIdQuery: bootstrapSessionId,
      fields: {'token': 'x'},
    );
    expect(loginCookieHeader, contains(bootstrapSessionId));
    expect(loginCookieHeader, isNot(contains('STALE')));
  });
}
