import 'dart:math';

import 'auth/att_wifi/att_wifi_auth_investigator.dart';
import 'auth/att_wifi/att_wifi_auth_spec.dart';
import 'network/router_network_service.dart';
import 'network/router_http_response.dart';

class RouterApiClient {
  RouterApiClient(this._networkService);

  final RouterNetworkService _networkService;

  RouterNetworkService get networkService => _networkService;

  Future<String?> readSessionIdFromCookieJar() =>
      _networkService.readSessionIdFromCookieJar();

  Future<RouterHttpResponse> getRoot() => _networkService.get('/');

  Future<RouterHttpResponse> getPath(
    String path, {
    Map<String, String>? queryParameters,
    String? cookieHeader,
  }) => _networkService.get(
    path,
    queryParameters: queryParameters,
    cookieHeader: cookieHeader,
  );

  Future<RouterHttpResponse> postForm(
    String path, {
    Map<String, String>? queryParameters,
    required Map<String, String> fields,
    String? cookieHeader,
    String? referer,
  }) => _networkService.postForm(
    path,
    queryParameters: queryParameters,
    fields: fields,
    cookieHeader: cookieHeader,
    referer: referer,
  );

  /// Guest/pre-login model read (browser: `internalapi=1` + cache-bust `x`, cookie jar).
  Future<RouterHttpResponse> fetchAttWifiModel({
    String? sessionIdForCookie,
    String? sessionIdQuery,
  }) {
    final sessionId = sessionIdQuery ?? sessionIdForCookie;
    return getPath(
      AttWifiAuthSpec.modelJsonPath,
      queryParameters: _browserModelQueryParameters(
        sessionIdQuery: sessionId,
      ),
      cookieHeader: sessionIdForCookie == null
          ? null
          : _sessionCookie(sessionIdForCookie),
    );
  }

  /// Post-login model read: cookie jar only; no `sessionId` query parameter.
  Future<RouterHttpResponse> fetchAttWifiModelAuthenticated() {
    return getPath(
      AttWifiAuthSpec.modelJsonPath,
      queryParameters: _browserModelQueryParameters(),
    );
  }

  /// Debug-only redirect probe for post-login model (jar cookies only).
  Future<void> debugProbePostLoginModel() {
    return _networkService.logPostLoginModelProbe(
      path: AttWifiAuthSpec.modelJsonPath,
      queryParameters: _browserModelQueryParameters(),
    );
  }

  static Map<String, String> _browserModelQueryParameters({
    String? sessionIdQuery,
  }) {
    return {
      AttWifiAuthSpec.internalApiQueryFlag:
          AttWifiAuthSpec.internalApiQueryValue,
      AttWifiAuthSpec.cacheBustQueryParameter: _cacheBustValue(),
      if (sessionIdQuery != null)
        AttWifiAuthSpec.sessionIdQueryParameter: sessionIdQuery,
    };
  }

  static String _cacheBustValue() {
    final random = Random();
    return '${DateTime.now().microsecondsSinceEpoch}${random.nextInt(1 << 20)}';
  }

  Future<RouterHttpResponse> submitAttWifiForm({
    required Map<String, String> fields,
    String? sessionIdQuery,
    String? sessionIdForCookie,
  }) {
    final baseUrl = _networkService.baseUrl;
    final referer = Uri.parse(baseUrl).replace(
      path: AttWifiAuthSpec.loginPagePath,
    ).toString();
    return postForm(
      AttWifiAuthSpec.authenticationPath,
      fields: fields,
      queryParameters: sessionIdQuery == null
          ? null
          : {
              AttWifiAuthSpec.sessionIdQueryParameter: sessionIdQuery,
            },
      cookieHeader: sessionIdForCookie == null
          ? null
          : _sessionCookie(sessionIdForCookie),
      referer: referer,
    );
  }

  /// Resolves `sessionId` after the verified bootstrap chain (`GET /`, login page).
  Future<String?> bootstrapAttWifiSessionId() async {
    final root = await getRoot();
    var sessionId = await _networkService.readSessionIdFromCookieJar();
    sessionId ??= AttWifiSessionParser.sessionIdFromBootstrap(root);

    if (sessionId == null) {
      final loginPage = await getPath(AttWifiAuthSpec.loginPagePath);
      sessionId = AttWifiSessionParser.sessionIdFromBootstrap(loginPage);
      sessionId ??= await _networkService.readSessionIdFromCookieJar();
    }

    return sessionId;
  }

  static String _sessionCookie(String sessionId) {
    return '${AttWifiAuthSpec.sessionIdCookieName}=$sessionId';
  }
}
