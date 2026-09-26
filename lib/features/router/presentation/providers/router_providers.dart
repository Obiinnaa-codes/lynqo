import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/router_config.dart';
import '../../data/adapters/router_adapter_factory.dart';
import '../../data/auth/att_wifi/att_wifi_router_auth_service.dart';
import '../../data/auth/router_auth_service.dart';
import '../../data/auth/router_secure_storage.dart';
import '../../data/discovery/router_discovery_service.dart';
import '../../data/network/router_client_factory.dart';
import '../../data/network/router_dio_factory.dart';
import '../../data/network/router_network_service.dart';
import '../../data/router_api_client.dart';
import '../../data/router_repository.dart';

final routerConfigProvider = Provider<RouterConfig>(
  (ref) => RouterConfig.development(),
);

final routerClientFactoryProvider = Provider<RouterClientFactory>((ref) {
  return RouterClientFactory(transportConfig: ref.watch(routerConfigProvider));
});

final routerDioProvider = Provider<Dio>((ref) {
  final config = ref.watch(routerConfigProvider);
  return createRouterDio(config);
});

final routerSecureStorageProvider = Provider<RouterSecureStorage>(
  (ref) => RouterSecureStorage(),
);

final routerNetworkServiceProvider = Provider<RouterNetworkService>((ref) {
  return RouterNetworkService(
    dio: ref.watch(routerDioProvider),
    config: ref.watch(routerConfigProvider),
  );
});

final routerApiClientProvider = Provider<RouterApiClient>((ref) {
  return RouterApiClient(ref.watch(routerNetworkServiceProvider));
});

final routerDiscoveryServiceProvider = Provider<RouterDiscoveryService>((ref) {
  return RouterDiscoveryService(
    apiClient: ref.watch(routerApiClientProvider),
    config: ref.watch(routerConfigProvider),
    clientFactory: ref.watch(routerClientFactoryProvider),
  );
});

final routerAuthServiceProvider = Provider<RouterAuthService>((ref) {
  final storage = ref.watch(routerSecureStorageProvider);
  final pending = PendingRouterAuthService(storage);
  final attWifi = AttWifiRouterAuthService(
    clientFactory: ref.watch(routerClientFactoryProvider),
    secureStorage: storage,
  );
  return RouterAuthServiceSelector(pending: pending, attWifi: attWifi);
});

final routerAdapterFactoryProvider = Provider<RouterAdapterFactory>((ref) {
  return RouterAdapterFactory(
    clientFactory: ref.watch(routerClientFactoryProvider),
    authService: ref.watch(routerAuthServiceProvider),
  );
});

final routerRepositoryProvider = Provider<RouterRepository>((ref) {
  return RouterRepository(
    networkService: ref.watch(routerNetworkServiceProvider),
    discoveryService: ref.watch(routerDiscoveryServiceProvider),
    adapterFactory: ref.watch(routerAdapterFactoryProvider),
  );
});
