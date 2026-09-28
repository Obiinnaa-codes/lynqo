import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lynqo/features/router/config/router_config.dart';
import 'package:lynqo/features/router/data/network/router_network_service.dart';
import 'package:lynqo/features/router/domain/router_failure.dart';

import 'mocks/mock_http_adapter.dart';

void main() {
  late Dio dio;
  late RouterNetworkService service;

  setUp(() {
    final config = RouterConfig.development();
    dio = Dio(
      BaseOptions(baseUrl: config.baseUrl, validateStatus: (_) => true),
    );
    service = RouterNetworkService(dio: dio, config: config);
  });

  test('ensureNetworkAvailable allows empty connectivity (unknown)', () async {
    final config = RouterConfig.development();
    final gated = RouterNetworkService(
      dio: dio,
      config: config,
      connectivityCheck: () async => const [],
    );

    await expectLater(gated.ensureNetworkAvailable(), completes);
  });

  test('maps connection timeout to ConnectionTimeout', () async {
    dio.httpClientAdapter = MockHttpAdapter((options) async {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionTimeout,
      );
    });

    await expectLater(service.get('/'), throwsA(isA<ConnectionTimeout>()));
  });

  test('maps connection error to RouterNotReachable', () async {
    dio.httpClientAdapter = MockHttpAdapter((options) async {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    });

    await expectLater(service.get('/'), throwsA(isA<RouterNotReachable>()));
  });

  test('maps redirect loop DioException to InvalidResponse', () async {
    dio.httpClientAdapter = MockHttpAdapter((options) async {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.unknown,
        message: 'Redirect loop detected',
        error: StateError('Redirect loop detected'),
      );
    });

    await expectLater(
      service.get('/'),
      throwsA(
        predicate<InvalidResponse>(
          (f) => f.message.toLowerCase().contains('redirect loop'),
        ),
      ),
    );
  });

  test('maps unknown non-socket DioException to InvalidResponse', () async {
    dio.httpClientAdapter = MockHttpAdapter((options) async {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.unknown,
        message: 'HttpException: unexpected chunk',
        error: FormatException('bad chunk'),
      );
    });

    await expectLater(service.get('/'), throwsA(isA<InvalidResponse>()));
  });

  test('parses successful HTTP response body', () async {
    dio.httpClientAdapter = MockHttpAdapter((options) async {
      return mockResponse(
        statusCode: 200,
        body: '<html><title>Router</title></html>',
        headers: {
          'content-type': ['text/html'],
        },
      );
    });

    final response = await service.get('/');
    expect(response.statusCode, 200);
    expect(response.contentType, 'text/html');
    expect(response.body, contains('Router'));
  });

  test('postForm follows 302 without stale explicit Cookie on redirect GET', () async {
    const staleSessionCookie = 'sessionId=STALE-SESSION-ID';
    String? followUpExplicitCookie;
    dio.httpClientAdapter = MockHttpAdapter((options) async {
      if (options.path == '/Forms/config' && options.method == 'POST') {
        return mockResponse(
          statusCode: 302,
          body: '',
          headers: {
            'location': ['/success.json'],
          },
        );
      }
      if (options.path == '/success.json' && options.method == 'GET') {
        followUpExplicitCookie = options.headers['Cookie'] as String?;
        return mockResponse(statusCode: 200, body: '{"success": true}');
      }
      return mockResponse(statusCode: 404);
    });

    final response = await service.postForm(
      '/Forms/config',
      queryParameters: {'sessionId': 'REDACTED-SESSION-ID'},
      fields: {'token': 'REDACTED'},
      cookieHeader: staleSessionCookie,
    );

    expect(response.statusCode, 200);
    expect(response.body, contains('"success": true'));
    expect(response.redirectDetected, isTrue);
    expect(followUpExplicitCookie, isNull);
  });

  test('postForm 302 Set-Cookie uses jar cookie on redirect GET', () async {
    const staleSessionCookie = 'sessionId=STALE-SESSION-ID';
    final jar = CookieJar();
    final config = RouterConfig.development();
    final cookieDio = Dio(
      BaseOptions(baseUrl: config.baseUrl, validateStatus: (_) => true),
    );
    cookieDio.interceptors.add(CookieManager(jar));
    String? followUpCookie;
    cookieDio.httpClientAdapter = MockHttpAdapter((options) async {
      if (options.path == '/Forms/config' && options.method == 'POST') {
        return mockResponse(
          statusCode: 302,
          body: '',
          headers: {
            'location': ['/success.json'],
            'set-cookie': ['sessionId=AUTHENTICATED-SESSION; Path=/; HttpOnly'],
          },
        );
      }
      if (options.path == '/success.json' && options.method == 'GET') {
        followUpCookie = options.headers['Cookie'] as String?;
        return mockResponse(statusCode: 200, body: '{"success": true}');
      }
      return mockResponse(statusCode: 404);
    });
    final cookieService = RouterNetworkService(
      dio: cookieDio,
      config: config,
      cookieJar: jar,
    );

    final response = await cookieService.postForm(
      '/Forms/config',
      fields: {'token': 'REDACTED'},
      cookieHeader: staleSessionCookie,
    );

    expect(response.statusCode, 200);
    expect(response.body, contains('"success": true'));
    expect(followUpCookie, isNot(contains('STALE-SESSION-ID')));
    expect(followUpCookie, contains('AUTHENTICATED-SESSION'));
    expect(await cookieService.hasSessionIdCookieInJar(), isTrue);
  });

  test('postForm 302 without Location returns redirect status', () async {
    dio.httpClientAdapter = MockHttpAdapter((options) async {
      return mockResponse(statusCode: 302, body: '');
    });

    final response = await service.postForm(
      '/Forms/config',
      fields: {'token': 'x'},
    );

    expect(response.statusCode, 302);
    expect(response.redirectDetected, isTrue);
    expect(response.body, isEmpty);
  });
}
