import 'package:cookie_jar/cookie_jar.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import '../../config/router_config.dart';
import '../../domain/router_profile.dart';
import '../discovery/router_discovery_service.dart';
import '../router_api_client.dart';
import 'router_dio_factory.dart';
import 'router_network_service.dart';

class RouterClientBundle {
  const RouterClientBundle({
    required this.dio,
    required this.networkService,
    required this.apiClient,
    required this.discoveryService,
    required this.config,
    required this.cookieJar,
  });

  final Dio dio;
  final RouterNetworkService networkService;
  final RouterApiClient apiClient;
  final RouterDiscoveryService discoveryService;
  final RouterConfig config;
  final CookieJar cookieJar;
}

typedef RouterDioFactory = Dio Function(
  RouterConfig config, {
  CookieJar? cookieJar,
});

class RouterClientFactory {
  RouterClientFactory({
    required this.transportConfig,
    RouterDioFactory? dioFactory,
  }) : _dioFactory = dioFactory ?? createRouterDio;

  final RouterConfig transportConfig;
  final RouterDioFactory _dioFactory;

  RouterClientBundle createForProfile(
    RouterProfile profile, {
    Dio? dio,
    CookieJar? cookieJar,
    Future<List<ConnectivityResult>> Function()? connectivityCheck,
  }) {
    final config = transportConfig.forProfile(profile);
    final jar = cookieJar ?? CookieJar();
    final clientDio = dio ?? _dioFactory(config, cookieJar: jar);
    final networkService = RouterNetworkService(
      dio: clientDio,
      config: config,
      cookieJar: jar,
      connectivityCheck: connectivityCheck,
    );
    final apiClient = RouterApiClient(networkService);
    final discoveryService = RouterDiscoveryService(
      apiClient: apiClient,
      config: config,
    );

    return RouterClientBundle(
      dio: clientDio,
      networkService: networkService,
      apiClient: apiClient,
      discoveryService: discoveryService,
      config: config,
      cookieJar: jar,
    );
  }
}
