import '../../domain/router_profile.dart';
import '../../domain/router_discovery_result.dart';
import '../auth/router_auth_result.dart';
import '../../domain/router_diagnostics.dart';

abstract class RouterAdapter {
  RouterProfile get profile;

  Future<bool> isReachable();

  Future<RouterDiscoveryResult> discover();

  Future<RouterAuthResult> authenticate({
    required String username,
    required String password,
    RouterDiagnostics? discoveryDiagnostics,
  });

  Future<void> logout();
}
