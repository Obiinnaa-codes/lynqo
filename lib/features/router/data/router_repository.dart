import 'package:flutter/foundation.dart';

import '../domain/router_authentication_state.dart';
import '../domain/router_connect_outcome.dart';
import '../domain/router_connection_state.dart';
import '../domain/router_discovery_result.dart';
import '../domain/router_failure.dart';
import '../presentation/router_user_messages.dart';
import 'adapters/router_adapter.dart';
import 'adapters/router_adapter_factory.dart';
import 'discovery/router_discovery_service.dart';
import 'network/router_network_service.dart';

class RouterRepository {
  RouterRepository({
    required this._networkService,
    required this._discoveryService,
    required this._adapterFactory,
  });

  final RouterNetworkService _networkService;
  final RouterDiscoveryService _discoveryService;
  final RouterAdapterFactory _adapterFactory;

  RouterConnectionState _connectionState = RouterConnectionState.idle;
  RouterAdapter? _activeAdapter;

  RouterConnectionState get connectionState => _connectionState;

  RouterAdapter? get activeAdapter => _activeAdapter;

  Future<RouterConnectOutcome> connect({
    required String username,
    required String password,
  }) async {
    _connectionState = RouterConnectionState.checking;

    if (kDebugMode) {
      debugPrint('[RouterConnect] discovery start');
    }

    try {
      await _networkService.ensureNetworkAvailable();
    } on NetworkUnavailable catch (failure) {
      _connectionState = RouterConnectionState.error;
      return RouterConnectOutcome(
        connectionState: _connectionState,
        authenticationState: RouterAuthenticationState.unauthenticated,
        message: failure.message,
        failure: failure,
      );
    }

    final discoveryAttempts = await _discoveryService.discoverKnownProfiles();
    final selected = RouterDiscoveryService.selectReachableProfile(
      discoveryAttempts,
    );

    if (kDebugMode) {
      for (final attempt in discoveryAttempts) {
        debugPrint(
          '[RouterConnect] discovery attempt profile=${attempt.profile.id} '
          'host=${attempt.profile.host} reachable=${attempt.isSuccess} '
          'failure=${attempt.failure?.runtimeType}',
        );
      }
      debugPrint(
        '[RouterConnect] discovery end '
        'selectedProfile=${selected?.profile.id ?? 'none'} '
        'host=${selected?.profile.host ?? 'none'} '
        'attempts=${discoveryAttempts.length}',
      );
    }

    if (selected == null) {
      _connectionState = RouterConnectionState.unreachable;
      _activeAdapter = null;
      final failure = _failureFromAttempts(discoveryAttempts);
      return RouterConnectOutcome(
        connectionState: _connectionState,
        authenticationState: RouterAuthenticationState.unauthenticated,
        message: failure.message,
        failure: failure,
        discoveryAttempts: discoveryAttempts,
      );
    }

    _connectionState = RouterConnectionState.reachable;
    final adapter = _adapterFactory.create(selected.profile);
    _activeAdapter = adapter;

    final diagnostics = selected.diagnostics;

    if (kDebugMode) {
      debugPrint(
        '[RouterConnect] authentication start profile=${selected.profile.id}',
      );
    }

    final authResult = await adapter.authenticate(
      username: username,
      password: password,
      discoveryDiagnostics: diagnostics,
    );

    if (authResult.state ==
        RouterAuthenticationState.pendingApiIdentification) {
      return RouterConnectOutcome(
        connectionState: _connectionState,
        authenticationState: authResult.state,
        message: RouterUserMessages.profileFound(selected.profile),
        diagnostics: diagnostics,
        failure: diagnostics.authenticationRequired
            ? const AuthenticationRequired()
            : const UnknownRouterApi(),
        selectedProfile: selected.profile,
        discoveryAttempts: discoveryAttempts,
      );
    }

    if (kDebugMode) {
      debugPrint(
        '[RouterConnect] authentication end '
        'state=${authResult.state} '
        'failure=${authResult.failure?.runtimeType}',
      );
    }

    if (authResult.failure != null) {
      return RouterConnectOutcome(
        connectionState: _connectionState,
        authenticationState: RouterAuthenticationState.failed,
        message: RouterUserMessages.fromFailure(authResult.failure),
        diagnostics: diagnostics,
        failure: authResult.failure,
        selectedProfile: selected.profile,
        discoveryAttempts: discoveryAttempts,
      );
    }

    return RouterConnectOutcome(
      connectionState: _connectionState,
      authenticationState: authResult.state,
      message: RouterUserMessages.forAuthenticationState(
        profile: selected.profile,
        state: authResult.state,
      ),
      diagnostics: diagnostics,
      selectedProfile: selected.profile,
      discoveryAttempts: discoveryAttempts,
    );
  }

  RouterFailure _failureFromAttempts(List<RouterDiscoveryResult> attempts) {
    if (attempts.isEmpty) {
      return const RouterNotReachable();
    }
    final lastFailure = attempts.last.failure;
    if (lastFailure != null) {
      return lastFailure;
    }
    return const RouterNotReachable();
  }
}
