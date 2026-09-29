import '../config/router_profile_catalog.dart';
import '../domain/router_failure.dart';
import '../domain/router_status.dart';
import 'auth/att_wifi/att_wifi_auth_investigator.dart';
import 'auth/att_wifi/att_wifi_auth_spec.dart';
import 'auth/att_wifi/att_wifi_model_parser.dart';
import 'auth/router_secure_storage.dart';
import 'network/router_client_factory.dart';

class AttWifiDashboardService {
  AttWifiDashboardService({
    required this._clientFactory,
    required RouterSecureStorage secureStorage,
  }) : _secureStorage = secureStorage;

  final RouterClientFactory _clientFactory;
  final RouterSecureStorage _secureStorage;

  static const refreshInterval = Duration(seconds: 10);

  Stream<RouterStatus> watchStatus() async* {
    while (true) {
      yield await fetchStatus();
      await Future<void>.delayed(refreshInterval);
    }
  }

  Future<RouterStatus> fetchStatus() async {
    final sessionId = await _secureStorage.readAttWifiSessionId();
    if (sessionId == null || sessionId.isEmpty) {
      throw const AuthenticationFailed('Sign in to view router status.');
    }

    final profileId = await _secureStorage.readSessionProfileId();
    if (profileId != AttWifiAuthSpec.profileId) {
      throw const UnsupportedRouter();
    }

    final client = _clientFactory
        .createForProfile(RouterProfileCatalog.attWifi)
        .apiClient;

    final response = await client.fetchAttWifiModel(
      sessionIdQuery: sessionId,
      sessionIdForCookie: sessionId,
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const AuthenticationFailed();
    }

    final role = AttWifiSessionParser.userRoleFromModelBody(response.body);
    if (role != AttWifiAuthSpec.adminUserRole) {
      throw const AuthenticationFailed('Admin session required.');
    }

    try {
      return AttWifiModelParser.parse(response.body);
    } on FormatException {
      throw const InvalidResponse('Could not read router status from the MiFi.');
    }
  }
}
