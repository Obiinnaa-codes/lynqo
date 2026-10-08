import '../config/router_profile_catalog.dart';
import '../domain/router_failure.dart';
import '../domain/router_status.dart';
import 'auth/att_wifi/att_wifi_auth_investigator.dart';
import 'auth/att_wifi/att_wifi_auth_spec.dart';
import 'auth/att_wifi/att_wifi_model_parser.dart';
import 'auth/router_auth_service.dart';
import 'auth/router_secure_storage.dart';
import 'network/router_client_factory.dart';

class AttWifiDashboardService {
  AttWifiDashboardService({
    required this._clientFactory,
    required this._secureStorage,
    required this._authService,
    Future<void> Function(Duration duration)? wait,
  }) : _wait = wait ?? Future<void>.delayed;

  final RouterClientFactory _clientFactory;
  final RouterSecureStorage _secureStorage;
  final RouterAuthService _authService;
  final Future<void> Function(Duration duration) _wait;

  static const refreshInterval = Duration(seconds: 10);
  static const retryInterval = Duration(seconds: 5);
  static const rebootBackoff = Duration(seconds: 30);

  var _pauseForReboot = false;
  Future<RouterStatus>? _inFlight;

  /// The running poll waits before the next fetch (MiFi reboot).
  void pauseForReboot() {
    _pauseForReboot = true;
  }

  Stream<RouterStatus> watchStatus() async* {
    while (true) {
      if (_pauseForReboot) {
        _pauseForReboot = false;
        await _wait(rebootBackoff);
        await _authService.tryRelogin();
      }
      try {
        yield await fetchStatus();
        await _wait(refreshInterval);
      } on RouterFailure {
        await _wait(_pauseForReboot ? rebootBackoff : retryInterval);
        _pauseForReboot = false;
      }
    }
  }

  Future<RouterStatus> fetchStatus() {
    final inFlight = _inFlight;
    if (inFlight != null) {
      return inFlight;
    }
    final future = _fetchStatusWithRelogin();
    _inFlight = future;
    return future.whenComplete(() {
      if (identical(_inFlight, future)) {
        _inFlight = null;
      }
    });
  }

  Future<RouterStatus> _fetchStatusWithRelogin() async {
    try {
      return await _fetchStatusOnce();
    } on RouterFailure {
      final relogged = await _authService.tryRelogin();
      if (!relogged) {
        rethrow;
      }
      return _fetchStatusOnce();
    }
  }

  Future<RouterStatus> _fetchStatusOnce() async {
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
