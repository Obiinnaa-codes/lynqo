import 'auth/att_wifi/att_wifi_auth_investigator.dart';
import 'auth/att_wifi/att_wifi_auth_spec.dart';
import 'network/router_network_service.dart';
import 'network/router_http_response.dart';

class RouterApiClient {
  RouterApiClient(this._networkService);

  final RouterNetworkService _networkService;

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
  }) => _networkService.postForm(
    path,
    queryParameters: queryParameters,
    fields: fields,
    cookieHeader: cookieHeader,
  );

  Future<RouterHttpResponse> fetchAttWifiModel({required String sessionId}) {
    return getPath(
      AttWifiAuthSpec.modelJsonPath,
      queryParameters: {
        AttWifiAuthSpec.internalApiQueryFlag:
            AttWifiAuthSpec.internalApiQueryValue,
        AttWifiAuthSpec.sessionIdQueryParameter: sessionId,
      },
      cookieHeader: _sessionCookie(sessionId),
    );
  }

  Future<RouterHttpResponse> submitAttWifiForm({
    required String sessionId,
    required Map<String, String> fields,
  }) {
    return postForm(
      AttWifiAuthSpec.authenticationPath,
      queryParameters: {AttWifiAuthSpec.sessionIdQueryParameter: sessionId},
      fields: fields,
      cookieHeader: _sessionCookie(sessionId),
    );
  }

  /// Resolves `sessionId` after the verified bootstrap chain (`GET /`, login page).
  Future<String?> bootstrapAttWifiSessionId() async {
    final root = await getRoot();
    var sessionId = AttWifiSessionParser.sessionIdFromBootstrap(root);
    sessionId ??= await _networkService.readSessionIdFromCookieJar();

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
