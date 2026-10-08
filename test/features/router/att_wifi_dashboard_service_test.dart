import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lynqo/features/router/config/router_config.dart';
import 'package:lynqo/features/router/data/att_wifi_dashboard_service.dart';
import 'package:lynqo/features/router/data/auth/att_wifi/att_wifi_auth_spec.dart';
import 'package:lynqo/features/router/data/auth/att_wifi/att_wifi_router_auth_service.dart';
import 'package:lynqo/features/router/data/auth/router_secure_storage.dart';
import 'package:lynqo/features/router/data/network/router_client_factory.dart';

import 'mocks/mock_http_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const fakeSessionId = 'REDACTED-SESSION-ID';
  final adminModel = File(
    'test/fixtures/att_wifi/model_admin.json',
  ).readAsStringSync();

  AttWifiDashboardService buildService({
    required Future<ResponseBody> Function(RequestOptions options) handler,
    Future<void> Function(Duration duration)? wait,
  }) {
    final factory = RouterClientFactory(
      transportConfig: RouterConfig.development(),
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
    final storage = RouterSecureStorage();
    return AttWifiDashboardService(
      clientFactory: factory,
      secureStorage: storage,
      authService: AttWifiRouterAuthService(
        clientFactory: factory,
        secureStorage: storage,
      ),
      wait: wait,
    );
  }

  Future<void> seedSession() async {
    FlutterSecureStorage.setMockInitialValues({
      RouterSecureStorage.sessionActiveKey: 'true',
      RouterSecureStorage.sessionProfileKey: AttWifiAuthSpec.profileId,
      RouterSecureStorage.attSessionIdKey: fakeSessionId,
    });
  }

  test('watchStatus retries after an unreachable fetch', () async {
    await seedSession();
    var attempts = 0;
    final waits = <Duration>[];
    final service = buildService(
      wait: (duration) async {
        waits.add(duration);
      },
      handler: (options) async {
        if (!options.path.contains('model.json')) {
          return mockResponse(statusCode: 404);
        }
        attempts += 1;
        if (attempts == 1) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          );
        }
        return mockResponse(statusCode: 200, body: adminModel);
      },
    );

    final status = await service.watchStatus().first;

    expect(status.batteryPercent, 72);
    expect(waits, contains(AttWifiDashboardService.retryInterval));
  });

  test('pauseForReboot delays the first poll', () async {
    await seedSession();
    final waits = <Duration>[];
    final service = buildService(
      wait: (duration) async {
        waits.add(duration);
      },
      handler: (options) async {
        if (!options.path.contains('model.json')) {
          return mockResponse(statusCode: 404);
        }
        return mockResponse(statusCode: 200, body: adminModel);
      },
    );

    service.pauseForReboot();
    await service.watchStatus().first;

    expect(waits.first, AttWifiDashboardService.rebootBackoff);
  });

  test('pauseForReboot delays the next poll on a live stream', () async {
    await seedSession();
    final waits = <Duration>[];
    late AttWifiDashboardService service;
    service = buildService(
      wait: (duration) async {
        waits.add(duration);
        if (duration == AttWifiDashboardService.refreshInterval) {
          service.pauseForReboot();
        }
      },
      handler: (options) async {
        if (!options.path.contains('model.json')) {
          return mockResponse(statusCode: 404);
        }
        return mockResponse(statusCode: 200, body: adminModel);
      },
    );

    final status = await service.watchStatus().skip(1).first;

    expect(status.batteryPercent, 72);
    expect(waits, contains(AttWifiDashboardService.rebootBackoff));
  });

  test('fetchStatus re-logins when the stored session is no longer admin', () async {
    const fakePassword = 'fake-router-password';
    const fakeSecToken = 'REDACTED-SEC-TOKEN';
    var authenticated = false;
    FlutterSecureStorage.setMockInitialValues({
      RouterSecureStorage.sessionActiveKey: 'true',
      RouterSecureStorage.sessionProfileKey: AttWifiAuthSpec.profileId,
      RouterSecureStorage.attSessionIdKey: fakeSessionId,
      RouterSecureStorage.rememberedPasswordKey: fakePassword,
    });

    final service = buildService(
      handler: (options) async {
        if (options.path == '/' && options.method == 'GET') {
          return mockResponse(
            statusCode: 200,
            body: '<html></html>',
            headers: {
              'set-cookie': ['sessionId=$fakeSessionId; path=/; HttpOnly'],
            },
          );
        }
        if (options.path.contains('model.json')) {
          return mockResponse(
            statusCode: 200,
            body: authenticated
                ? adminModel
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

    final status = await service.fetchStatus();
    expect(status.batteryPercent, 72);
  });

  test('fetchStatus re-logins when the stored session times out', () async {
    const fakePassword = 'fake-router-password';
    const fakeSecToken = 'REDACTED-SEC-TOKEN';
    var modelFetches = 0;
    var authenticated = false;
    FlutterSecureStorage.setMockInitialValues({
      RouterSecureStorage.sessionActiveKey: 'true',
      RouterSecureStorage.sessionProfileKey: AttWifiAuthSpec.profileId,
      RouterSecureStorage.attSessionIdKey: fakeSessionId,
      RouterSecureStorage.rememberedPasswordKey: fakePassword,
    });

    final service = buildService(
      handler: (options) async {
        if (options.path == '/' && options.method == 'GET') {
          return mockResponse(
            statusCode: 200,
            body: '<html></html>',
            headers: {
              'set-cookie': ['sessionId=$fakeSessionId; path=/; HttpOnly'],
            },
          );
        }
        if (options.path.contains('model.json')) {
          modelFetches += 1;
          if (modelFetches == 1) {
            throw DioException(
              requestOptions: options,
              type: DioExceptionType.connectionTimeout,
            );
          }
          return mockResponse(
            statusCode: 200,
            body: authenticated
                ? adminModel
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

    final status = await service.fetchStatus();
    expect(status.batteryPercent, 72);
  });
}
