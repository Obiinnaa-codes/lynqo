import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lynqo/features/router/config/router_config.dart';
import 'package:lynqo/features/router/data/att_wifi_device_actions_service.dart';
import 'package:lynqo/features/router/data/auth/att_wifi/att_wifi_auth_spec.dart';
import 'package:lynqo/features/router/data/auth/router_secure_storage.dart';
import 'package:lynqo/features/router/data/network/router_client_factory.dart';
import 'package:lynqo/features/router/domain/router_failure.dart';

import 'mocks/mock_http_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const fakeSessionId = 'REDACTED-SESSION-ID';
  const fakeSecToken = 'REDACTED-SEC-TOKEN';

  AttWifiDeviceActionsService buildService({
    required Future<ResponseBody> Function(RequestOptions options) handler,
  }) {
    FlutterSecureStorage.setMockInitialValues({});
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
    return AttWifiDeviceActionsService(
      clientFactory: factory,
      secureStorage: RouterSecureStorage(),
    );
  }

  Future<void> seedSession() async {
    FlutterSecureStorage.setMockInitialValues({
      RouterSecureStorage.sessionActiveKey: 'true',
      RouterSecureStorage.sessionProfileKey: AttWifiAuthSpec.profileId,
      RouterSecureStorage.attSessionIdKey: fakeSessionId,
    });
  }

  test('reboot posts general.shutdown=restart with token and JSON redirects', () async {
    await seedSession();
    String? rebootField;
    String? tokenField;
    String? okRedirect;
    final storage = RouterSecureStorage();

    final service = AttWifiDeviceActionsService(
      clientFactory: RouterClientFactory(
        transportConfig: RouterConfig.development(),
        dioFactory: (config, {CookieJar? cookieJar}) {
          final jar = cookieJar ?? CookieJar();
          final dio = Dio(
            BaseOptions(baseUrl: config.baseUrl, validateStatus: (_) => true),
          );
          dio.interceptors.add(CookieManager(jar));
          dio.httpClientAdapter = MockHttpAdapter((options) async {
            if (options.path.contains('model.json')) {
              return mockResponse(
                statusCode: 200,
                body:
                    '{"session": {"secToken": "$fakeSecToken", "userRole": "${AttWifiAuthSpec.adminUserRole}"}}',
                headers: {
                  'content-type': ['application/json'],
                },
              );
            }
            if (options.path == AttWifiAuthSpec.authenticationPath &&
                options.method == 'POST') {
              final body = options.data as String? ?? '';
              for (final part in body.split('&')) {
                final kv = part.split('=');
                if (kv.length != 2) {
                  continue;
                }
                final key = Uri.decodeQueryComponent(kv[0]);
                final value = Uri.decodeQueryComponent(kv[1]);
                switch (key) {
                  case AttWifiAuthSpec.shutdownFormField:
                    rebootField = value;
                  case AttWifiAuthSpec.tokenFormField:
                    tokenField = value;
                  case AttWifiAuthSpec.okRedirectFormField:
                    okRedirect = value;
                }
              }
              return mockResponse(
                statusCode: 200,
                body: '{"success": true}',
                headers: {
                  'content-type': ['application/json'],
                },
              );
            }
            return mockResponse(statusCode: 404);
          });
          return dio;
        },
      ),
      secureStorage: storage,
    );

    await service.rebootRouter();

    expect(rebootField, AttWifiAuthSpec.rebootShutdownValue);
    expect(tokenField, fakeSecToken);
    expect(okRedirect, AttWifiAuthSpec.successRedirectPath);
  });

  test('reboot requires stored session', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final service = buildService(
      handler: (_) async => mockResponse(statusCode: 404),
    );

    expect(
      () => service.rebootRouter(),
      throwsA(isA<AuthenticationFailed>()),
    );
  });

  test('reboot rejects non-admin model role', () async {
    await seedSession();
    final storage = RouterSecureStorage();
    final service = AttWifiDeviceActionsService(
      clientFactory: RouterClientFactory(
        transportConfig: RouterConfig.development(),
        dioFactory: (config, {CookieJar? cookieJar}) {
          final jar = cookieJar ?? CookieJar();
          final dio = Dio(
            BaseOptions(baseUrl: config.baseUrl, validateStatus: (_) => true),
          );
          dio.interceptors.add(CookieManager(jar));
          dio.httpClientAdapter = MockHttpAdapter((options) async {
            if (options.path.contains('model.json')) {
              return mockResponse(
                statusCode: 200,
                body:
                    '{"session": {"secToken": "$fakeSecToken", "userRole": "${AttWifiAuthSpec.guestUserRole}"}}',
              );
            }
            return mockResponse(statusCode: 404);
          });
          return dio;
        },
      ),
      secureStorage: storage,
    );

    expect(
      () => service.rebootRouter(),
      throwsA(isA<AuthenticationFailed>()),
    );
  });

  test('setWifiProfile5Ghz posts wifi.profile=WiFi5GHz', () async {
    await seedSession();
    String? profileField;
    final service = AttWifiDeviceActionsService(
      clientFactory: RouterClientFactory(
        transportConfig: RouterConfig.development(),
        dioFactory: (config, {CookieJar? cookieJar}) {
          final jar = cookieJar ?? CookieJar();
          final dio = Dio(
            BaseOptions(baseUrl: config.baseUrl, validateStatus: (_) => true),
          );
          dio.interceptors.add(CookieManager(jar));
          dio.httpClientAdapter = MockHttpAdapter((options) async {
            if (options.path.contains('model.json')) {
              return mockResponse(
                statusCode: 200,
                body:
                    '{"session": {"secToken": "$fakeSecToken", "userRole": "${AttWifiAuthSpec.adminUserRole}"}}',
              );
            }
            if (options.path == AttWifiAuthSpec.authenticationPath &&
                options.method == 'POST') {
              final body = options.data as String? ?? '';
              for (final part in body.split('&')) {
                final kv = part.split('=');
                if (kv.length != 2) {
                  continue;
                }
                if (Uri.decodeQueryComponent(kv[0]) ==
                    AttWifiAuthSpec.wifiProfileFormField) {
                  profileField = Uri.decodeQueryComponent(kv[1]);
                }
              }
              return mockResponse(statusCode: 200, body: '{"success": true}');
            }
            return mockResponse(statusCode: 404);
          });
          return dio;
        },
      ),
      secureStorage: RouterSecureStorage(),
    );

    await service.setWifiProfile5Ghz();
    expect(profileField, AttWifiAuthSpec.wifiProfile5Ghz);
  });

  test('deleteSmsMessage posts sms.deleteId', () async {
    await seedSession();
    String? deleteId;
    final service = AttWifiDeviceActionsService(
      clientFactory: RouterClientFactory(
        transportConfig: RouterConfig.development(),
        dioFactory: (config, {CookieJar? cookieJar}) {
          final jar = cookieJar ?? CookieJar();
          final dio = Dio(
            BaseOptions(baseUrl: config.baseUrl, validateStatus: (_) => true),
          );
          dio.interceptors.add(CookieManager(jar));
          dio.httpClientAdapter = MockHttpAdapter((options) async {
            if (options.path.contains('model.json')) {
              return mockResponse(
                statusCode: 200,
                body:
                    '{"session": {"secToken": "$fakeSecToken", "userRole": "${AttWifiAuthSpec.adminUserRole}"}}',
              );
            }
            if (options.path == AttWifiAuthSpec.authenticationPath &&
                options.method == 'POST') {
              final body = options.data as String? ?? '';
              for (final part in body.split('&')) {
                final kv = part.split('=');
                if (kv.length != 2) {
                  continue;
                }
                if (Uri.decodeQueryComponent(kv[0]) ==
                    AttWifiAuthSpec.smsDeleteIdFormField) {
                  deleteId = Uri.decodeQueryComponent(kv[1]);
                }
              }
              return mockResponse(statusCode: 200, body: '{"success": true}');
            }
            return mockResponse(statusCode: 404);
          });
          return dio;
        },
      ),
      secureStorage: RouterSecureStorage(),
    );

    await service.deleteSmsMessage('42');
    expect(deleteId, '42');
  });
}
