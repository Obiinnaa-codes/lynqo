import '../../domain/router_authentication_state.dart';
import '../../domain/router_diagnostics.dart';
import '../../domain/router_profile.dart';
import 'router_auth_result.dart';
import 'router_secure_storage.dart';

abstract interface class RouterAuthService {
  Future<RouterAuthResult> login({
    required String username,
    required String password,
    RouterDiagnostics? discoveryDiagnostics,
    RouterProfile? profile,
  });

  Future<void> logout();

  Future<bool> isAuthenticated();

  Future<RouterAuthenticationState> restoreSession();
}

class PendingRouterAuthService implements RouterAuthService {
  PendingRouterAuthService(this._secureStorage);

  final RouterSecureStorage _secureStorage;

  @override
  Future<RouterAuthResult> login({
    required String username,
    required String password,
    RouterDiagnostics? discoveryDiagnostics,
    RouterProfile? profile,
  }) async {
    // Credentials are validated by the UI; login HTTP call is pending API discovery.
    final diagnostics = discoveryDiagnostics;
    final message = _buildPendingMessage(diagnostics, profile);

    return RouterAuthResult(
      state: RouterAuthenticationState.pendingApiIdentification,
      message: message,
      diagnostics: diagnostics,
    );
  }

  String pendingUserMessage() => 'Authentication is not available yet.';

  @override
  Future<void> logout() async {
    await _secureStorage.clearSession();
  }

  @override
  Future<bool> isAuthenticated() async {
    return await _secureStorage.isSessionActive();
  }

  @override
  Future<RouterAuthenticationState> restoreSession() async {
    final active = await _secureStorage.isSessionActive();
    if (active) {
      return RouterAuthenticationState.authenticated;
    }
    return RouterAuthenticationState.unauthenticated;
  }

  String _buildPendingMessage(
    RouterDiagnostics? diagnostics,
    RouterProfile? profile,
  ) {
    if (diagnostics == null || !diagnostics.routerReachable) {
      return 'Could not complete router discovery.';
    }

    return pendingUserMessage();
  }
}
