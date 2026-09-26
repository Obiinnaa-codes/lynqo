import '../../domain/router_discovery_result.dart';
import '../../domain/router_diagnostics.dart';
import '../../domain/router_profile.dart';
import '../auth/router_auth_result.dart';
import '../auth/router_auth_service.dart';
import '../discovery/router_discovery_service.dart';
import '../network/router_network_service.dart';
import 'router_adapter.dart';

class GenericRouterAdapter implements RouterAdapter {
  GenericRouterAdapter({
    required this.profile,
    required this.networkService,
    required this.discoveryService,
    required this.authService,
  });

  @override
  final RouterProfile profile;
  final RouterNetworkService networkService;
  final RouterDiscoveryService discoveryService;
  final RouterAuthService authService;

  @override
  Future<bool> isReachable() => networkService.isReachable();

  @override
  Future<RouterDiscoveryResult> discover() =>
      discoveryService.discoverProfile(profile);

  @override
  Future<RouterAuthResult> authenticate({
    required String username,
    required String password,
    RouterDiagnostics? discoveryDiagnostics,
  }) {
    return authService.login(
      username: username,
      password: password,
      discoveryDiagnostics: discoveryDiagnostics,
      profile: profile,
    );
  }

  @override
  Future<void> logout() => authService.logout();
}
