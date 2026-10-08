import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../router/domain/router_authentication_state.dart';
import '../../../router/domain/router_connection_state.dart';
import '../../../router/presentation/providers/router_auth_gate_provider.dart';
import '../../../router/presentation/providers/router_providers.dart';

/// Result of a login connect attempt for the UI (no Riverpod rebuild of text fields).
class LoginConnectOutcome {
  const LoginConnectOutcome({
    this.usernameError,
    this.passwordError,
    this.connectMessage,
    this.connectMessageIsError = false,
    this.unexpectedFailure = false,
    this.didNavigate = false,
  });

  final String? usernameError;
  final String? passwordError;
  final String? connectMessage;
  final bool connectMessageIsError;
  final bool unexpectedFailure;
  final bool didNavigate;
}

class LoginController {
  LoginController(this._ref);

  final Ref _ref;
  var _connectInFlight = false;

  Future<LoginConnectOutcome> connect({
    required String usernameFromField,
    required String passwordFromField,
    required bool rememberPassword,
  }) async {
    if (_connectInFlight) {
      return const LoginConnectOutcome();
    }

    _connectInFlight = true;
    try {
      if (kDebugMode) {
        debugPrint('[RouterConnect] Connect pressed');
      }
      final username = usernameFromField.trim();
      final password = passwordFromField;

      String? usernameError;
      String? passwordError;

      if (username.isEmpty) {
        usernameError = 'Username is required';
      }
      if (password.isEmpty) {
        passwordError = 'Password is required';
      }

      if (usernameError != null || passwordError != null) {
        return LoginConnectOutcome(
          usernameError: usernameError,
          passwordError: passwordError,
        );
      }

      try {
        final outcome = await _ref
            .read(routerRepositoryProvider)
            .connect(username: username, password: password);

        if (outcome.authenticationState ==
            RouterAuthenticationState.authenticated) {
          final storage = _ref.read(routerSecureStorageProvider);
          await storage.saveSignedInPassword(password);
          await storage.setRememberPasswordEnabled(rememberPassword);
          _ref.read(routerAuthGateProvider.notifier).markAuthenticated();
          _ref.read(goRouterProvider).go(AppRoutes.routerDashboard);
          return const LoginConnectOutcome(didNavigate: true);
        }

        final isError =
            outcome.unexpectedError ||
            outcome.connectionState == RouterConnectionState.unreachable ||
            outcome.connectionState == RouterConnectionState.error ||
            (outcome.failure != null &&
                outcome.authenticationState !=
                    RouterAuthenticationState.pendingApiIdentification);

        return LoginConnectOutcome(
          connectMessage: outcome.message,
          connectMessageIsError: isError,
          unexpectedFailure: outcome.unexpectedError,
        );
      } catch (_) {
        return const LoginConnectOutcome(
          connectMessage: 'An unexpected error occurred while connecting.',
          connectMessageIsError: true,
          unexpectedFailure: true,
        );
      }
    } finally {
      _connectInFlight = false;
    }
  }
}

final loginControllerProvider = Provider<LoginController>((ref) {
  return LoginController(ref);
});
