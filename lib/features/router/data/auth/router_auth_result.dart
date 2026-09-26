import '../../domain/router_authentication_state.dart';
import '../../domain/router_diagnostics.dart';
import '../../domain/router_failure.dart';
import '../../domain/router_session.dart';

class RouterAuthResult {
  const RouterAuthResult({
    required this.state,
    required this.message,
    this.failure,
    this.diagnostics,
    this.session,
  });

  final RouterAuthenticationState state;
  final String message;
  final RouterFailure? failure;
  final RouterDiagnostics? diagnostics;
  final RouterSession? session;

  bool get isPendingApi =>
      state == RouterAuthenticationState.pendingApiIdentification;
}
