import '../config/router_profile_catalog.dart';
import '../domain/router_failure.dart';
import 'auth/att_wifi/att_wifi_auth_investigator.dart';
import 'auth/att_wifi/att_wifi_auth_spec.dart';
import 'auth/router_secure_storage.dart';
import 'network/router_client_factory.dart';
import 'network/router_http_response.dart';
import 'router_api_client.dart';

class AttWifiDeviceActionsService {
  AttWifiDeviceActionsService({
    required this._clientFactory,
    required RouterSecureStorage secureStorage,
  }) : _secureStorage = secureStorage;

  final RouterClientFactory _clientFactory;
  final RouterSecureStorage _secureStorage;

  /// Reboots the MiFi (`general.shutdown=restart`), matching the web admin menu.
  Future<void> rebootRouter() async {
    await _submitAction({
      AttWifiAuthSpec.shutdownFormField: AttWifiAuthSpec.rebootShutdownValue,
    });
  }

  /// Sets active Wi‑Fi profile to 2.4 GHz only (`wifi.profile=WiFi24GHz`).
  Future<void> setWifiProfile24Ghz() async {
    await _submitAction({
      AttWifiAuthSpec.wifiProfileFormField: AttWifiAuthSpec.wifiProfile24Ghz,
    });
  }

  /// Sets active Wi‑Fi profile to 5 GHz only (`wifi.profile=WiFi5GHz`).
  Future<void> setWifiProfile5Ghz() async {
    await _submitAction({
      AttWifiAuthSpec.wifiProfileFormField: AttWifiAuthSpec.wifiProfile5Ghz,
    });
  }

  Future<void> deleteSmsMessage(String messageId) async {
    await _submitAction({
      AttWifiAuthSpec.smsDeleteIdFormField: messageId,
    });
  }

  Future<void> deleteAllSmsMessages() async {
    await _submitAction({
      AttWifiAuthSpec.smsDeleteAllFormField: AttWifiAuthSpec.smsDeleteAllValue,
    });
  }

  Future<void> _submitAction(Map<String, String> data) async {
    final sessionId = await _requireSessionId();
    final client = _clientFactory
        .createForProfile(RouterProfileCatalog.attWifi)
        .apiClient;

    final secToken = await _requireSecToken(client, sessionId);

    final response = await client.submitAttWifiForm(
      sessionIdQuery: sessionId,
      sessionIdForCookie: sessionId,
      fields: AttWifiAuthSpec.jsonActionFields(
        secToken: secToken,
        data: data,
      ),
    );

    _ensureActionAccepted(response);
  }

  Future<String> _requireSessionId() async {
    final sessionId = await _secureStorage.readAttWifiSessionId();
    if (sessionId == null || sessionId.isEmpty) {
      throw const AuthenticationFailed('Sign in to control the MiFi.');
    }

    final profileId = await _secureStorage.readSessionProfileId();
    if (profileId != AttWifiAuthSpec.profileId) {
      throw const UnsupportedRouter();
    }

    return sessionId;
  }

  Future<String> _requireSecToken(
    RouterApiClient client,
    String sessionId,
  ) async {
    final model = await client.fetchAttWifiModel(
      sessionIdForCookie: sessionId,
      sessionIdQuery: sessionId,
    );

    if (model.statusCode == 401 || model.statusCode == 403) {
      throw const AuthenticationFailed();
    }

    final role = AttWifiSessionParser.userRoleFromModelBody(model.body);
    if (role != AttWifiAuthSpec.adminUserRole) {
      throw const AuthenticationFailed('Admin session required.');
    }

    final secToken = AttWifiSessionParser.secTokenFromModelBody(model.body);
    if (secToken == null) {
      throw const InvalidResponse('Could not read security token from the MiFi.');
    }

    return secToken;
  }

  void _ensureActionAccepted(RouterHttpResponse response) {
    final outcome = AttWifiLoginResponseParser.parseHttpResponse(response);
    if (outcome is AttWifiLoginSuccess) {
      return;
    }
    throw const InvalidResponse('The MiFi did not accept the request.');
  }
}
