import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lynqo/features/router/config/router_config.dart';
import 'package:lynqo/features/router/config/router_profile_catalog.dart';
import 'package:lynqo/features/router/data/adapters/router_adapter_factory.dart';
import 'package:lynqo/features/router/data/auth/router_auth_service.dart';
import 'package:lynqo/features/router/data/auth/router_secure_storage.dart';
import 'package:lynqo/features/router/data/discovery/router_discovery_service.dart';
import 'package:lynqo/features/router/data/network/router_client_factory.dart';
import 'package:lynqo/features/router/data/network/router_network_service.dart';
import 'package:lynqo/features/router/data/router_api_client.dart';
import 'package:lynqo/features/router/data/router_repository.dart';
import 'package:lynqo/features/router/domain/router_authentication_state.dart';
import 'package:lynqo/features/router/domain/router_connection_state.dart';
import 'package:lynqo/features/router/domain/router_failure.dart';

import 'mocks/mock_http_adapter.dart';

void main() {
  RouterRepository buildRepository({
    required Future<ResponseBody> Function(RequestOptions options) handler,
    bool hasConnectivity = true,
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

    final network = RouterNetworkService(
      dio: defaultBundle.dio,
      config: defaultBundle.config,
      connectivityCheck: () async => hasConnectivity
          ? const [ConnectivityResult.wifi]
          : const [ConnectivityResult.none],
    );

    final discovery = RouterDiscoveryService(
      apiClient: RouterApiClient(network),
      config: transport,
      clientFactory: clientFactory,
    );

    final auth = PendingRouterAuthService(RouterSecureStorage());
    final adapterFactory = RouterAdapterFactory(
      clientFactory: clientFactory,
      authService: auth,
    );

    return RouterRepository(
      networkService: network,
      discoveryService: discovery,
      adapterFactory: adapterFactory,
    );
  }

  test('returns NetworkUnavailable when device has no connectivity', () async {
    final repository = buildRepository(
      handler: (_) async => mockResponse(statusCode: 200),
      hasConnectivity: false,
    );

    final outcome = await repository.connect(
      username: 'admin',
      password: 'password',
    );

    expect(outcome.failure, isA<NetworkUnavailable>());
    expect(outcome.connectionState, RouterConnectionState.error);
  });

  test('returns unreachable when all router hosts fail', () async {
    final repository = buildRepository(
      handler: (_) async {
        throw DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.connectionError,
        );
      },
    );

    final outcome = await repository.connect(
      username: 'admin',
      password: 'password',
    );

    expect(outcome.failure, isA<RouterNotReachable>());
    expect(outcome.connectionState, RouterConnectionState.unreachable);
    expect(outcome.discoveryAttempts, hasLength(2));
  });

  test('selects second profile when first host is unavailable', () async {
    final repository = buildRepository(
      handler: (options) async {
        if (options.baseUrl.contains('192.168.0.1')) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          );
        }
        return mockResponse(
          statusCode: 200,
          body:
              '<html><head><title>MiFi</title></head><body>'
              '<form action="/login.cgi"><input type="password"/></form>'
              '</body></html>',
          headers: {
            'content-type': ['text/html'],
          },
        );
      },
    );

    final outcome = await repository.connect(
      username: 'admin',
      password: 'password',
    );

    expect(outcome.connectionState, RouterConnectionState.reachable);
    expect(outcome.selectedProfile?.id, 'att_wifi');
    expect(outcome.discoveryAttempts, hasLength(2));
    expect(
      outcome.authenticationState,
      RouterAuthenticationState.pendingApiIdentification,
    );
    expect(outcome.message, 'AT&T WiFi Manager found');
  });

  test(
    'returns pending auth when default MiFi router responds with HTML login',
    () async {
      final repository = buildRepository(
        handler: (options) async {
          if (options.baseUrl.contains('attwifimanager')) {
            throw DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
            );
          }
          return mockResponse(
            statusCode: 200,
            body:
                '<html><head><title>MiFi</title></head><body>'
                '<form action="/login.cgi"><input type="password"/></form>'
                '</body></html>',
            headers: {
              'content-type': ['text/html'],
            },
          );
        },
      );

      final outcome = await repository.connect(
        username: 'admin',
        password: 'password',
      );

      expect(outcome.connectionState, RouterConnectionState.reachable);
      expect(outcome.selectedProfile?.id, 'default_mifi');
      expect(
        outcome.authenticationState,
        RouterAuthenticationState.pendingApiIdentification,
      );
      expect(outcome.message, 'MiFi found');
      expect(outcome.diagnostics?.authenticationRequired, isTrue);
    },
  );
}
