import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/router_profile_catalog.dart';
import '../../data/auth/att_wifi/att_wifi_auth_spec.dart';
import '../../domain/router_authentication_state.dart';
import '../../domain/router_connection_state.dart';
import 'router_providers.dart';

class RouterConnectionStatus {
  const RouterConnectionStatus({
    required this.host,
    required this.authenticationLabel,
    required this.roleLabel,
    required this.connectionLabel,
    required this.isFullyConnected,
  });

  final String host;
  final String authenticationLabel;
  final String roleLabel;
  final String connectionLabel;
  final bool isFullyConnected;
}

final routerConnectionStatusProvider = FutureProvider<RouterConnectionStatus>((
  ref,
) async {
  final repository = ref.watch(routerRepositoryProvider);
  final authService = ref.watch(routerAuthServiceProvider);

  final profile = repository.activeAdapter?.profile;
  final host = profile?.host ?? RouterProfileCatalog.attWifi.host;

  final authState = await authService.restoreSession();
  final connectionState = repository.connectionState;

  final isAuthenticated = authState == RouterAuthenticationState.authenticated;
  final isAttProfile =
      profile?.id == AttWifiAuthSpec.profileId ||
      (await ref.read(routerSecureStorageProvider).readSessionProfileId()) ==
          AttWifiAuthSpec.profileId;

  final authenticationLabel = isAuthenticated
      ? 'Authenticated'
      : switch (authState) {
          RouterAuthenticationState.failed => 'Failed',
          RouterAuthenticationState.unauthenticated => 'Not signed in',
          _ => 'Unknown',
        };

  final roleLabel = isAuthenticated && isAttProfile
      ? AttWifiAuthSpec.adminUserRole
      : '—';

  final isOnline =
      connectionState == RouterConnectionState.reachable && isAuthenticated;
  final connectionLabel = isOnline ? 'Online' : 'Offline';

  return RouterConnectionStatus(
    host: host,
    authenticationLabel: authenticationLabel,
    roleLabel: roleLabel,
    connectionLabel: connectionLabel,
    isFullyConnected: isOnline,
  );
});
