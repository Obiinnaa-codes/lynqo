import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lynqo/features/router/config/router_config.dart';
import 'package:lynqo/features/router/config/router_profile_catalog.dart';
import 'package:lynqo/features/router/data/discovery/router_discovery_service.dart';
import 'package:lynqo/features/router/data/network/router_client_factory.dart';
import 'package:lynqo/features/router/domain/router_discovery_status.dart';
import 'package:lynqo/features/router/domain/router_failure.dart';

import 'mocks/mock_http_adapter.dart';

void main() {
  RouterDiscoveryService buildDiscoveryService({
    required Future<ResponseBody> Function(RequestOptions options) handler,
  }) {
    final transport = RouterConfig.development();
    final clientFactory = RouterClientFactory(
      transportConfig: transport,
      dioFactory: (config, {CookieJar? cookieJar}) {
        final dio = Dio(
          BaseOptions(baseUrl: config.baseUrl, validateStatus: (_) => true),
        );
        dio.httpClientAdapter = MockHttpAdapter(handler);
        return dio;
      },
    );

    final defaultBundle = clientFactory.createForProfile(
      RouterProfileCatalog.defaultMifi,
    );

    return RouterDiscoveryService(
      apiClient: defaultBundle.apiClient,
      config: transport,
      clientFactory: clientFactory,
    );
  }

  test('discoverProfile reports reachable HTML router', () async {
    final service = buildDiscoveryService(
      handler: (_) async => mockResponse(
        statusCode: 200,
        body:
            '<html><head><title>MiFi</title></head><body>'
            '<form action="/login.cgi"><input type="password"/></form>'
            '</body></html>',
        headers: {
          'content-type': ['text/html'],
        },
      ),
    );

    final result = await service.discoverProfile(
      RouterProfileCatalog.defaultMifi,
    );

    expect(result.profile.id, 'default_mifi');
    expect(result.isSuccess, isTrue);
    expect(result.status, RouterDiscoveryStatus.authenticationRequired);
    expect(result.diagnostics.authenticationRequired, isTrue);
  });

  test('discoverProfile maps connection error to unreachable', () async {
    final service = buildDiscoveryService(
      handler: (_) async {
        throw DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.connectionError,
        );
      },
    );

    final result = await service.discoverProfile(
      RouterProfileCatalog.defaultMifi,
    );

    expect(result.reachable, isFalse);
    expect(result.failure, isA<RouterNotReachable>());
    expect(result.status, RouterDiscoveryStatus.unreachable);
  });

  test('discoverProfile maps timeout to timeout status', () async {
    final transport = RouterConfig.development();
    final clientFactory = RouterClientFactory(
      transportConfig: transport,
      dioFactory: (config, {CookieJar? cookieJar}) {
        final dio = Dio(
          BaseOptions(baseUrl: config.baseUrl, validateStatus: (_) => true),
        );
        dio.httpClientAdapter = MockHttpAdapter((_) async {
          throw DioException(
            requestOptions: RequestOptions(path: '/'),
            type: DioExceptionType.connectionTimeout,
          );
        });
        return dio;
      },
    );
    final attBundle = clientFactory.createForProfile(
      RouterProfileCatalog.attWifi,
    );
    final service = RouterDiscoveryService(
      apiClient: attBundle.apiClient,
      config: attBundle.config,
      clientFactory: clientFactory,
    );

    final result = await service.discoverProfile(RouterProfileCatalog.attWifi);

    expect(result.failure, isA<ConnectionTimeout>());
    expect(result.status, RouterDiscoveryStatus.timeout);
  });

  test(
    'discoverKnownProfiles skips 192.168.0.1 when attwifimanager is reachable',
    () async {
      var mifiProbed = false;
      final service = buildDiscoveryService(
        handler: (options) async {
          if (options.baseUrl.contains('192.168.0.1')) {
            mifiProbed = true;
            throw DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
            );
          }
          return mockResponse(
            statusCode: 200,
            body: '<html><title>AT&T</title></html>',
            headers: {
              'content-type': ['text/html'],
            },
          );
        },
      );

      final results = await service.discoverKnownProfiles();

      expect(results, hasLength(1));
      expect(results[0].profile.id, 'att_wifi');
      expect(results[0].isSuccess, isTrue);
      expect(mifiProbed, isFalse);

      final selected = RouterDiscoveryService.selectReachableProfile(results);
      expect(selected?.profile.id, 'att_wifi');
    },
  );

  test(
    'discoverKnownProfiles probes default_mifi when attwifimanager fails',
    () async {
      final service = buildDiscoveryService(
        handler: (options) async {
          if (options.baseUrl.contains('attwifimanager')) {
            throw DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
            );
          }
          return mockResponse(
            statusCode: 200,
            body: '<html><title>MiFi</title></html>',
            headers: {
              'content-type': ['text/html'],
            },
          );
        },
      );

      final results = await service.discoverKnownProfiles();

      expect(results, hasLength(2));
      expect(results[0].profile.id, 'att_wifi');
      expect(results[0].isSuccess, isFalse);
      expect(results[1].profile.id, 'default_mifi');
      expect(results[1].isSuccess, isTrue);
    },
  );

  test('discoverKnownProfiles probes attwifimanager base URL', () async {
    String? attBaseUrl;

    final service = buildDiscoveryService(
      handler: (options) async {
        if (options.baseUrl.contains('attwifimanager')) {
          attBaseUrl = options.baseUrl;
        }
        return mockResponse(statusCode: 200, body: '<html></html>');
      },
    );

    await service.discoverKnownProfiles();

    expect(attBaseUrl, 'http://attwifimanager/');
  });
}
