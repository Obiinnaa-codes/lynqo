import 'package:lynqo/features/router/data/adapters/router_adapter_factory.dart';
import 'package:lynqo/features/router/data/auth/router_auth_service.dart';
import 'package:lynqo/features/router/data/auth/router_secure_storage.dart';
import 'package:lynqo/features/router/data/discovery/router_discovery_service.dart';
import 'package:lynqo/features/router/data/network/router_client_factory.dart';
import 'package:lynqo/features/router/config/router_config.dart';
import 'package:lynqo/features/router/config/router_profile_catalog.dart';
import 'package:lynqo/features/router/data/network/router_network_service.dart';
import 'package:lynqo/features/router/data/router_api_client.dart';
import 'package:lynqo/features/router/data/router_repository.dart';
import 'package:lynqo/features/router/domain/router_authentication_state.dart';
import 'package:lynqo/features/router/domain/router_connect_outcome.dart';
import 'package:lynqo/features/router/domain/router_connection_state.dart';
import 'package:dio/dio.dart';

// Test mock repository for widget tests (no live router).
class FakeRouterRepository extends RouterRepository {
  FakeRouterRepository()
    : super(
        networkService: RouterNetworkService(
          dio: Dio(),
          config: RouterConfig.development(),
        ),
        discoveryService: RouterDiscoveryService(
          apiClient: RouterApiClient(
            RouterNetworkService(
              dio: Dio(),
              config: RouterConfig.development(),
            ),
          ),
          config: RouterConfig.development(),
        ),
        adapterFactory: RouterAdapterFactory(
          clientFactory: RouterClientFactory(
            transportConfig: RouterConfig.development(),
          ),
          authService: PendingRouterAuthService(RouterSecureStorage()),
        ),
      );

  @override
  Future<RouterConnectOutcome> connect({
    required String username,
    required String password,
  }) async {
    return RouterConnectOutcome(
      connectionState: RouterConnectionState.reachable,
      authenticationState: RouterAuthenticationState.pendingApiIdentification,
      message: 'Test mock: router discovery pending.',
      selectedProfile: RouterProfileCatalog.defaultMifi,
    );
  }
}
