import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/router_authentication_state.dart';
import 'router_providers.dart';

class RouterAuthGateState {
  const RouterAuthGateState({
    required this.isLoading,
    required this.isAuthenticated,
  });

  final bool isLoading;
  final bool isAuthenticated;
}

class RouterAuthGate extends Notifier<RouterAuthGateState> {
  @override
  RouterAuthGateState build() {
    Future<void>.microtask(_restoreFromStorage);
    return const RouterAuthGateState(
      isLoading: true,
      isAuthenticated: false,
    );
  }

  Future<void> _restoreFromStorage() async {
    final authState = await ref.read(routerAuthServiceProvider).restoreSession();
    state = RouterAuthGateState(
      isLoading: false,
      isAuthenticated: authState == RouterAuthenticationState.authenticated,
    );
  }

  void markAuthenticated() {
    state = const RouterAuthGateState(
      isLoading: false,
      isAuthenticated: true,
    );
  }

  void markLoggedOut() {
    state = const RouterAuthGateState(
      isLoading: false,
      isAuthenticated: false,
    );
  }

  Future<void> refresh() => _restoreFromStorage();
}

final routerAuthGateProvider =
    NotifierProvider<RouterAuthGate, RouterAuthGateState>(RouterAuthGate.new);

/// Notifies [GoRouter] when auth gate changes.
final goRouterRefreshProvider = Provider<GoRouterRefresh>((ref) {
  final refresh = GoRouterRefresh();
  ref.onDispose(refresh.dispose);
  ref.listen(routerAuthGateProvider, (_, _) => refresh.notifyListeners());
  return refresh;
});

class GoRouterRefresh extends ChangeNotifier {
  @override
  void notifyListeners() {
    if (hasListeners) {
      super.notifyListeners();
    }
  }
}
