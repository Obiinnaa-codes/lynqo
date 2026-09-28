import 'package:flutter/foundation.dart';

import '../../../config/router_profile_catalog.dart';
import '../../../domain/router_authentication_state.dart';
import '../../../domain/router_diagnostics.dart';
import '../../../domain/router_failure.dart';
import '../../../domain/router_profile.dart';
import '../../../domain/router_session.dart';
import '../../../presentation/router_user_messages.dart';
import '../../network/router_client_factory.dart';
import '../../network/router_http_diagnostic.dart';
import '../../network/router_http_response.dart';
import '../../router_api_client.dart';
import '../router_auth_result.dart';
import '../router_auth_service.dart';
import '../router_secure_storage.dart';
import '../../network/sensitive_log_redactor.dart';
import 'att_wifi_auth_investigator.dart';
import 'att_wifi_auth_spec.dart';

class AttWifiRouterAuthService implements RouterAuthService {
  AttWifiRouterAuthService({
    required this._clientFactory,
    required this._secureStorage,
  });

  final RouterClientFactory _clientFactory;
  final RouterSecureStorage _secureStorage;

  RouterApiClient _clientFromFactory() {
    final bundle = _clientFactory.createForProfile(
      RouterProfileCatalog.attWifi,
    );
    return RouterApiClient(bundle.networkService);
  }

  @override
  Future<RouterAuthResult> login({
    required String username,
    required String password,
    RouterDiagnostics? discoveryDiagnostics,
    RouterProfile? profile,
  }) async {
    if (profile != null && profile.id != AttWifiAuthSpec.profileId) {
      return RouterAuthResult(
        state: RouterAuthenticationState.failed,
        message: 'Unsupported router profile.',
        failure: const UnsupportedRouter(),
      );
    }

    try {
      if (kDebugMode) {
        debugPrint('[RouterConnect] auth profile=att_wifi');
      }
      final client = _clientFromFactory();
      if (kDebugMode) {
        debugPrint('[RouterConnect] auth step: bootstrap GET /');
      }
      final bootstrap = await client.getRoot();
      final bootstrapSessionId =
          AttWifiSessionParser.sessionIdFromBootstrap(bootstrap) ??
          await client.readSessionIdFromCookieJar();
      final bootstrapCookieEstablished = bootstrapSessionId != null;
      if (kDebugMode) {
        debugPrint(
          '[RouterConnect] bootstrap cookie established=$bootstrapCookieEstablished',
        );
      }
      if (!bootstrapCookieEstablished) {
        return _failed(const InvalidResponse());
      }

      if (kDebugMode) {
        debugPrint('[RouterConnect] auth step: pre-login GET model.json');
      }
      final model = await client.fetchAttWifiModel();
      final secToken = AttWifiSessionParser.secTokenFromModelBody(model.body);
      if (secToken == null) {
        return _failed(const InvalidResponse());
      }

      if (kDebugMode) {
        debugPrint('[RouterConnect] auth step: POST /Forms/config');
      }
      final loginResponse = await client.submitAttWifiForm(
        fields: _loginFields(secToken: secToken, password: password),
      );

      if (kDebugMode) {
        debugPrint(
          '[RouterConnect] login POST completed status=${loginResponse.statusCode}',
        );
      }

      final outcome = AttWifiLoginResponseParser.parseHttpResponse(
        loginResponse,
      );
      if (kDebugMode) {
        debugPrint(
          '[RouterConnect] auth step: login response parsed '
          'outcome=${outcome.runtimeType} '
          'status=${loginResponse.statusCode} '
          'redirectDetected=${loginResponse.redirectDetected}',
        );
      }
      return switch (outcome) {
        AttWifiLoginSuccess() => await _completeLogin(
          bootstrapSessionId: bootstrapSessionId,
          client: client,
          loginHttpResponse: loginResponse,
        ),
        AttWifiLoginInvalidCredentials() => RouterAuthResult(
          state: RouterAuthenticationState.failed,
          message: RouterUserMessages.incorrectCredentials,
          failure: const AuthenticationFailed(
            RouterUserMessages.incorrectCredentials,
          ),
        ),
        AttWifiLoginUnexpected() => () {
          _logUnexpectedLoginResponse(loginResponse);
          return _failed(const InvalidResponse());
        }(),
      };
    } on RouterFailure catch (failure) {
      return _failed(failure);
    }
  }

  Map<String, String> _loginFields({
    required String secToken,
    required String password,
  }) {
    return {
      AttWifiAuthSpec.tokenFormField: secToken,
      AttWifiAuthSpec.errorRedirectFormField:
          AttWifiAuthSpec.htmlErrorRedirectPath,
      AttWifiAuthSpec.okRedirectFormField: AttWifiAuthSpec.htmlOkRedirectPath,
      AttWifiAuthSpec.passwordFormField: password,
    };
  }

  Future<RouterAuthResult> _completeLogin({
    required String bootstrapSessionId,
    required RouterApiClient client,
    RouterHttpResponse? loginHttpResponse,
  }) async {
    if (kDebugMode && loginHttpResponse != null) {
      RouterHttpDiagnostic.logSetCookieNames(
        'login response',
        loginHttpResponse,
      );
    }

    final jarSessionId = await client.readSessionIdFromCookieJar();
    final sessionRotated = jarSessionId != null &&
        jarSessionId.isNotEmpty &&
        jarSessionId != bootstrapSessionId;
    if (kDebugMode) {
      debugPrint(
        '[RouterConnect] session cookie rotated=$sessionRotated',
      );
      debugPrint(
        '[RouterConnect] authenticated model URL=${AttWifiAuthSpec.modelJsonPath}'
        '?${AttWifiAuthSpec.internalApiQueryFlag}=${AttWifiAuthSpec.internalApiQueryValue}'
        '&${AttWifiAuthSpec.cacheBustQueryParameter}=<redacted>',
      );
      await client.debugProbePostLoginModel();
      debugPrint(
        '[RouterConnect] auth step: post-login GET model.json (jar cookies)',
      );
    }

    try {
      final model = await client.fetchAttWifiModelAuthenticated();
      final role = AttWifiSessionParser.userRoleFromModelBody(model.body);
      if (kDebugMode) {
        debugPrint(
          '[RouterConnect] authenticated model status=${model.statusCode}',
        );
        debugPrint(
          '[RouterConnect] authenticated model success=${role == AttWifiAuthSpec.adminUserRole}',
        );
      }
      if (role != AttWifiAuthSpec.adminUserRole) {
        return _failed(const InvalidResponse());
      }
    } on RouterFailure catch (failure) {
      return _failed(failure);
    }

    final persistedSessionId = jarSessionId ?? bootstrapSessionId;
    await _secureStorage.saveAttWifiSession(sessionId: persistedSessionId);
    return RouterAuthResult(
      state: RouterAuthenticationState.authenticated,
      message: 'Signed in.',
      session: const RouterSession(profileId: AttWifiAuthSpec.profileId),
    );
  }

  void _logUnexpectedLoginResponse(RouterHttpResponse response) {
    if (!kDebugMode) {
      return;
    }
    final trimmed = response.body.trim();
    final looksJson = trimmed.startsWith('{');
    final location = response.headers['location']?.firstOrNull;
    final redactedLocation = location == null
        ? 'none'
        : SensitiveLogRedactor.redactUrl(location);
    debugPrint(
      '[Router] AT&T login unexpected response '
      'status=${response.statusCode} '
      'redirectDetected=${response.redirectDetected} '
      'looksJson=$looksJson '
      'location=$redactedLocation',
    );
  }

  RouterAuthResult _failed(RouterFailure failure) {
    return RouterAuthResult(
      state: RouterAuthenticationState.failed,
      message: failure.message,
      failure: failure,
    );
  }

  @override
  Future<void> logout() async {
    final sessionId = await _secureStorage.readAttWifiSessionId();
    if (sessionId != null) {
      try {
        final client = _clientFromFactory();
        final model = await client.fetchAttWifiModel(
          sessionIdForCookie: sessionId,
        );
        final secToken = AttWifiSessionParser.secTokenFromModelBody(model.body);
        if (secToken != null) {
          await client.submitAttWifiForm(
            sessionIdForCookie: sessionId,
            fields: {
              AttWifiAuthSpec.tokenFormField: secToken,
              AttWifiAuthSpec.errorRedirectFormField:
                  AttWifiAuthSpec.errorRedirectPath,
              AttWifiAuthSpec.okRedirectFormField:
                  AttWifiAuthSpec.successRedirectPath,
              AttWifiAuthSpec.passwordFormField:
                  AttWifiAuthSpec.logoutPasswordValue,
            },
          );
        }
      } catch (_) {
        // Local session is cleared even if the router rejects logout.
      }
    }
    await _secureStorage.clearSession();
  }

  @override
  Future<bool> isAuthenticated() async {
    final state = await restoreSession();
    return state == RouterAuthenticationState.authenticated;
  }

  @override
  Future<RouterAuthenticationState> restoreSession() async {
    final active = await _secureStorage.isSessionActive();
    if (!active) {
      return RouterAuthenticationState.unauthenticated;
    }

    final profileId = await _secureStorage.readSessionProfileId();
    if (profileId != AttWifiAuthSpec.profileId) {
      return RouterAuthenticationState.unauthenticated;
    }

    final sessionId = await _secureStorage.readAttWifiSessionId();
    if (sessionId == null || sessionId.isEmpty) {
      await _secureStorage.clearSession();
      return RouterAuthenticationState.unauthenticated;
    }

    try {
      final model = await _clientFromFactory().fetchAttWifiModel(
        sessionIdForCookie: sessionId,
      );
      if (model.statusCode == 401 || model.statusCode == 403) {
        await _secureStorage.clearSession();
        return RouterAuthenticationState.failed;
      }

      final role = AttWifiSessionParser.userRoleFromModelBody(model.body);
      if (role == AttWifiAuthSpec.adminUserRole) {
        return RouterAuthenticationState.authenticated;
      }

      await _secureStorage.clearSession();
      return RouterAuthenticationState.unauthenticated;
    } on RouterFailure {
      await _secureStorage.clearSession();
      return RouterAuthenticationState.failed;
    }
  }
}

class RouterAuthServiceSelector implements RouterAuthService {
  RouterAuthServiceSelector({
    required this._pending,
    required this._attWifi,
  });

  final PendingRouterAuthService _pending;
  final AttWifiRouterAuthService _attWifi;

  RouterAuthService _delegate(RouterProfile? profile) {
    if (profile?.id == AttWifiAuthSpec.profileId) {
      return _attWifi;
    }
    return _pending;
  }

  @override
  Future<RouterAuthResult> login({
    required String username,
    required String password,
    RouterDiagnostics? discoveryDiagnostics,
    RouterProfile? profile,
  }) {
    return _delegate(profile).login(
      username: username,
      password: password,
      discoveryDiagnostics: discoveryDiagnostics,
      profile: profile,
    );
  }

  @override
  Future<void> logout() async {
    await _attWifi.logout();
    await _pending.logout();
  }

  @override
  Future<bool> isAuthenticated() async {
    if (await _attWifi.isAuthenticated()) {
      return true;
    }
    return _pending.isAuthenticated();
  }

  @override
  Future<RouterAuthenticationState> restoreSession() async {
    final attState = await _attWifi.restoreSession();
    if (attState != RouterAuthenticationState.unauthenticated) {
      return attState;
    }
    return _pending.restoreSession();
  }
}
