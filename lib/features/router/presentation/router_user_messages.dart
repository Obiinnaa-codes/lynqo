import '../config/router_profile_catalog.dart';
import '../domain/router_authentication_state.dart';
import '../domain/router_failure.dart';
import '../domain/router_profile.dart';

abstract final class RouterUserMessages {
  static const incorrectCredentials = 'Incorrect username or password.';

  static String profileFound(RouterProfile profile) {
    switch (profile.id) {
      case RouterProfileCatalog.attWifiId:
        return 'AT&T WiFi Manager found';
      case RouterProfileCatalog.defaultMifiId:
        return 'MiFi found';
      default:
        return '${profile.displayName} found';
    }
  }

  static String authenticationSuccess(RouterProfile profile) {
    return switch (profile.id) {
      RouterProfileCatalog.attWifiId => 'Signed in to AT&T WiFi Manager.',
      _ => 'Signed in to your MiFi.',
    };
  }

  static String pendingAuthentication() {
    return 'Authentication is not available yet.';
  }

  static String forAuthenticationState({
    required RouterProfile profile,
    required RouterAuthenticationState state,
    RouterFailure? failure,
  }) {
    return switch (state) {
      RouterAuthenticationState.authenticated => authenticationSuccess(profile),
      RouterAuthenticationState.pendingApiIdentification =>
        pendingAuthentication(),
      RouterAuthenticationState.failed => fromFailure(failure),
      RouterAuthenticationState.unauthenticated => 'Not signed in.',
      RouterAuthenticationState.unknown => 'Connection status unknown.',
    };
  }

  static String fromFailure(RouterFailure? failure) {
    return switch (failure) {
      null => 'Authentication failed.',
      AuthenticationFailed() => failure.message,
      AuthenticationRequired() => 'Authentication is required.',
      ConnectionTimeout() => 'The MiFi is not responding. Try again.',
      InvalidResponse() => 'Unexpected router response.',
      NetworkUnavailable() => failure.message,
      RouterNotReachable() => 'Router unavailable.',
      UnknownRouterApi() => 'This router is not fully supported yet.',
      UnsupportedRouter() => failure.message,
    };
  }
}
