import 'package:dio/dio.dart';
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

  test('postForm follows 302 Location with session cookie', () async {
    const sessionCookie = 'sessionId=REDACTED-SESSION-ID';
    String? followUpCookie;
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
        followUpCookie = options.headers['Cookie'] as String?;
        return mockResponse(statusCode: 200, body: '{"success": true}');
      }
      return mockResponse(statusCode: 404);
    });

    final response = await service.postForm(
      '/Forms/config',
      queryParameters: {'sessionId': 'REDACTED-SESSION-ID'},
      fields: {'token': 'REDACTED'},
      cookieHeader: sessionCookie,
    );

    expect(response.statusCode, 200);
    expect(response.body, contains('"success": true'));
    expect(response.redirectDetected, isTrue);
    expect(followUpCookie, sessionCookie);
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
