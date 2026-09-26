import 'router_authentication_state.dart';
import 'router_connection_state.dart';
import 'router_diagnostics.dart';
import 'router_discovery_result.dart';
import 'router_failure.dart';
import 'router_profile.dart';

class RouterConnectOutcome {
  const RouterConnectOutcome({
    required this.connectionState,
    required this.authenticationState,
    required this.message,
    this.diagnostics,
    this.failure,
    this.unexpectedError = false,
    this.selectedProfile,
    this.discoveryAttempts = const [],
  });

  final RouterConnectionState connectionState;
  final RouterAuthenticationState authenticationState;
  final String message;
  final RouterDiagnostics? diagnostics;
  final RouterFailure? failure;
  final bool unexpectedError;
  final RouterProfile? selectedProfile;
  final List<RouterDiscoveryResult> discoveryAttempts;
}
