import 'router_diagnostics.dart';
import 'router_discovery_status.dart';
import 'router_failure.dart';
import 'router_info.dart';
import 'router_profile.dart';

class RouterDiscoveryResult {
  const RouterDiscoveryResult({
    required this.profile,
    required this.diagnostics,
    this.info,
    this.failure,
  });

  final RouterProfile profile;
  final RouterDiagnostics diagnostics;
  final RouterInfo? info;
  final RouterFailure? failure;

  bool get isSuccess => failure == null && diagnostics.routerReachable;

  bool get reachable => diagnostics.routerReachable;

  RouterDiscoveryStatus get status {
    if (failure is ConnectionTimeout) {
      return RouterDiscoveryStatus.timeout;
    }
    if (!diagnostics.routerReachable) {
      return RouterDiscoveryStatus.unreachable;
    }
    if (diagnostics.redirectDetected) {
      return RouterDiscoveryStatus.redirect;
    }
    if (diagnostics.authenticationRequired) {
      return RouterDiscoveryStatus.authenticationRequired;
    }
    if (failure != null) {
      return RouterDiscoveryStatus.unknown;
    }
    return RouterDiscoveryStatus.reachable;
  }
}
