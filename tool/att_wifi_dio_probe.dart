/// Dev-only AT&T WiFi Manager HTTP probe using the same Dio stack as the app.
///
/// Run on a device/emulator attached to the MiFi network:
///
///   flutter run -t tool/att_wifi_dio_probe.dart -d <device_id>
///
/// Optional password for real login POST (value never logged):
///   ATT_WIFI_PROBE_PASSWORD via shell export — visible to [Platform.environment]
///     on desktop/host only; iOS/Android app processes do not inherit the shell.
///   ATT_WIFI_PROBE_PASSWORD via --dart-define=ATT_WIFI_PROBE_PASSWORD=...
///     required on iOS/Android (e.g. --dart-define=ATT_WIFI_PROBE_PASSWORD=\$ATT_WIFI_PROBE_PASSWORD).
/// Optional env (desktop/host): ATT_WIFI_PROBE_PLATFORM — label in logs
///
/// Compile-time defines are baked on full `flutter run` only (not hot reload/restart).
/// Diagnostic: --dart-define=PROBE_TEST_VALUE=hello (harmless; never log the value).
library;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:lynqo/features/router/config/router_config.dart' as router_cfg;
import 'package:lynqo/features/router/config/router_profile_catalog.dart';
import 'package:lynqo/features/router/data/auth/att_wifi/att_wifi_auth_investigator.dart';
import 'package:lynqo/features/router/data/auth/att_wifi/att_wifi_auth_spec.dart';
import 'package:lynqo/features/router/data/discovery/router_discovery_service.dart';
import 'package:lynqo/features/router/data/network/router_client_factory.dart';
import 'package:lynqo/features/router/data/network/router_dio_error_details.dart';
import 'package:lynqo/features/router/data/network/router_http_response.dart';
import 'package:lynqo/features/router/data/network/sensitive_log_redactor.dart';
import 'package:lynqo/features/router/domain/router_failure.dart';

/// Compile-time `--dart-define=ATT_WIFI_PROBE_PASSWORD=...` (must be top-level const).
const _attWifiProbePasswordFromDartDefine =
    String.fromEnvironment('ATT_WIFI_PROBE_PASSWORD');

/// Harmless canary for `--dart-define=PROBE_TEST_VALUE=hello`.
const _probeTestValueFromDartDefine =
    String.fromEnvironment('PROBE_TEST_VALUE');

String? _resolveAttWifiProbePassword() {
  if (_attWifiProbePasswordFromDartDefine.isNotEmpty) {
    return _attWifiProbePasswordFromDartDefine;
  }
  final fromPlatform = Platform.environment['ATT_WIFI_PROBE_PASSWORD'];
  if (fromPlatform != null && fromPlatform.isNotEmpty) {
    return fromPlatform;
  }
  return null;
}

void _logAttWifiProbePasswordDiagnostics() {
  final dartDefineDetected = _attWifiProbePasswordFromDartDefine.isNotEmpty;
  final platformEnv = Platform.environment['ATT_WIFI_PROBE_PASSWORD'];
  final platformEnvironmentDetected =
      platformEnv != null && platformEnv.isNotEmpty;
  final effectivePasswordDetected = _resolveAttWifiProbePassword() != null;
  debugPrint(
    '[AttWifiProbe] passwordDefineDiagnostics '
    'dartDefineDetected=$dartDefineDetected '
    'platformEnvironmentDetected=$platformEnvironmentDetected '
    'effectivePasswordDetected=$effectivePasswordDetected',
  );
  debugPrint(
    '[AttWifiProbe] PROBE_TEST_VALUE dartDefineDetected='
    '${_probeTestValueFromDartDefine.isNotEmpty}',
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final platformLabel =
      Platform.environment['ATT_WIFI_PROBE_PLATFORM'] ?? Platform.operatingSystem;
  debugPrint('[AttWifiProbe] platform=$platformLabel');
  _logAttWifiProbePasswordDiagnostics();
  final probePassword = _resolveAttWifiProbePassword();
  try {
    await runAttWifiDioProbe(probePassword: probePassword);
  } on RouterFailure catch (failure) {
    debugPrint(
      '[AttWifiProbe] aborted: ${failure.runtimeType} ${failure.message}',
    );
    exit(1);
  } on DioException catch (error) {
    debugPrint(
      '[AttWifiProbe] aborted: ${error.type.name} '
      '${SensitiveLogRedactor.redactUrl(error.requestOptions.uri.toString())}',
    );
    exit(1);
  }
  exit(0);
}

Future<void> runAttWifiDioProbe({String? probePassword}) async {
  final config = router_cfg.RouterConfig.development().forProfile(
    RouterProfileCatalog.attWifi,
  );
  final factory = RouterClientFactory(transportConfig: config);
  final bundle = factory.createForProfile(RouterProfileCatalog.attWifi);
  final net = bundle.networkService;
  final client = bundle.apiClient;

  await _logDnsResolution(RouterProfileCatalog.attWifi.host);

  await _probeStep('GET /', () async {
    final response = await net.get('/');
    _logHttpSummary(response);
    return response;
  });

  final bootstrap = await client.getRoot();
  final sessionId = AttWifiSessionParser.sessionIdFromBootstrap(bootstrap) ??
      await net.readSessionIdFromCookieJar();
  if (sessionId == null) {
    debugPrint('[AttWifiProbe] ERROR: no sessionId after bootstrap');
    return;
  }
  debugPrint('[AttWifiProbe] sessionId present: yes (value [REDACTED])');

  await _probeStep('GET /success.json (pre-auth, same jar)', () async {
    final response = await net.get(AttWifiAuthSpec.successRedirectPath);
    _logHttpSummary(response);
    _logSafeBodyPreview(response.body);
    debugPrint(
      '[AttWifiProbe] session cookie in jar: '
      '${await net.hasSessionIdCookieInJar() ? 'yes' : 'no'}',
    );
    return response;
  });

  await _probeStep('GET model.json (pre-auth)', () async {
    final response = await client.fetchAttWifiModel(sessionIdQuery: sessionId);
    _logHttpSummary(response);
    final role = AttWifiSessionParser.userRoleFromModelBody(response.body);
    debugPrint('[AttWifiProbe] userRole: ${role ?? 'unknown'}');
    return response;
  });

  final model = await client.fetchAttWifiModel(sessionIdQuery: sessionId);
  final secToken = AttWifiSessionParser.secTokenFromModelBody(model.body);
  if (secToken == null) {
    debugPrint('[AttWifiProbe] ERROR: secToken missing');
    return;
  }
  debugPrint('[AttWifiProbe] secToken present: yes (value [REDACTED])');

    await _probeStep('POST /Forms/config (invalid password)', () async {
      final response = await client.submitAttWifiForm(
        sessionIdQuery: sessionId,
        fields: {
        AttWifiAuthSpec.tokenFormField: secToken,
        AttWifiAuthSpec.errorRedirectFormField:
            AttWifiAuthSpec.htmlErrorRedirectPath,
        AttWifiAuthSpec.okRedirectFormField: AttWifiAuthSpec.htmlOkRedirectPath,
        AttWifiAuthSpec.passwordFormField: 'probe-invalid-password',
      },
    );
    _logHttpSummary(response);
    return response;
  });

  debugPrint(
    '[AttWifiProbe] ATT_WIFI_PROBE_PASSWORD detected=${probePassword != null}',
  );
  if (probePassword != null) {
    final refreshed = await client.fetchAttWifiModel(sessionIdQuery: sessionId);
    final token = AttWifiSessionParser.secTokenFromModelBody(refreshed.body);
    if (token == null) {
      debugPrint('[AttWifiProbe] ERROR: secToken missing before real login');
      return;
    }
    await _probeStep('POST /Forms/config (real login)', () async {
      final response = await client.submitAttWifiForm(
        sessionIdQuery: sessionId,
        fields: {
          AttWifiAuthSpec.tokenFormField: token,
          AttWifiAuthSpec.errorRedirectFormField:
              AttWifiAuthSpec.htmlErrorRedirectPath,
          AttWifiAuthSpec.okRedirectFormField: AttWifiAuthSpec.htmlOkRedirectPath,
          AttWifiAuthSpec.passwordFormField: probePassword,
        },
      );
      _logHttpSummary(response);
      final parsed = AttWifiLoginResponseParser.parseHttpResponse(response);
      debugPrint(
        '[AttWifiProbe] login parse outcome: ${parsed.runtimeType}',
      );
      return response;
    });

    final jarRotated = await net.readSessionIdFromCookieJar() != sessionId;
    debugPrint('[AttWifiProbe] session cookie rotated: $jarRotated');
    await client.debugProbePostLoginModel();
    await _probeStep('GET model.json (post-login, jar cookies)', () async {
      final response = await client.fetchAttWifiModelAuthenticated();
      _logHttpSummary(response);
      final role = AttWifiSessionParser.userRoleFromModelBody(response.body);
      debugPrint('[AttWifiProbe] post-login userRole: ${role ?? 'unknown'}');
      return response;
    });
  } else {
    debugPrint(
      '[AttWifiProbe] Skipping real login (set ATT_WIFI_PROBE_PASSWORD to run)',
    );
  }

  debugPrint('[AttWifiProbe] done');

  await _runDiscoveryProbe();
}

Future<void> _runDiscoveryProbe() async {
  debugPrint('[AttWifiProbe] === discoverKnownProfiles (Connect pre-step) ===');
  final transport = router_cfg.RouterConfig.development();
  final factory = RouterClientFactory(transportConfig: transport);
  final defaultBundle = factory.createForProfile(RouterProfileCatalog.defaultMifi);
  final discovery = RouterDiscoveryService(
    apiClient: defaultBundle.apiClient,
    config: transport,
    clientFactory: factory,
  );
  final stopwatch = Stopwatch()..start();
  try {
    final results = await discovery.discoverKnownProfiles();
    stopwatch.stop();
    for (final result in results) {
      debugPrint(
        '[AttWifiProbe] discovery profile=${result.profile.id} '
        'success=${result.isSuccess} '
        'failure=${result.failure?.runtimeType} '
        'reachable=${result.diagnostics.routerReachable}',
      );
    }
    final selected = RouterDiscoveryService.selectReachableProfile(results);
    debugPrint(
      '[AttWifiProbe] discovery selected=${selected?.profile.id ?? 'none'} '
      'totalDuration: ${stopwatch.elapsedMilliseconds}ms',
    );
  } on Object catch (error) {
    stopwatch.stop();
    debugPrint(
      '[AttWifiProbe] discovery FAIL duration: ${stopwatch.elapsedMilliseconds}ms '
      'error: $error',
    );
  }
}

Future<T> _probeStep<T>(String label, Future<T> Function() action) async {
  debugPrint('[AttWifiProbe] === $label ===');
  final stopwatch = Stopwatch()..start();
  try {
    final result = await action();
    stopwatch.stop();
    debugPrint(
      '[AttWifiProbe] OK $label duration: ${stopwatch.elapsedMilliseconds}ms',
    );
    return result;
  } on RouterFailure catch (failure) {
    stopwatch.stop();
    debugPrint(
      '[AttWifiProbe] FAIL $label duration: ${stopwatch.elapsedMilliseconds}ms '
      'failure: ${failure.runtimeType} message: ${failure.message}',
    );
    rethrow;
  } on DioException catch (error) {
    stopwatch.stop();
    debugPrint(
      '[AttWifiProbe] FAIL $label duration: ${stopwatch.elapsedMilliseconds}ms '
      '${RouterDioErrorDetails.formatSingleLine(error)}',
    );
    rethrow;
  }
}

Future<void> _logDnsResolution(String host) async {
  try {
    final addresses = await InternetAddress.lookup(host);
    final ips = addresses.map((a) => a.address).join(', ');
    debugPrint('[AttWifiProbe] DNS $host -> $ips');
  } on SocketException catch (error) {
    debugPrint('[AttWifiProbe] DNS $host FAILED: ${error.message}');
  }
}

void _logSafeBodyPreview(String body) {
  final trimmed = body.trim();
  if (trimmed.isEmpty) {
    debugPrint('[AttWifiProbe] body preview: (empty)');
    return;
  }
  if (trimmed.toLowerCase().contains('<html')) {
    debugPrint('[AttWifiProbe] body preview: format=html');
    return;
  }
  debugPrint(
    '[AttWifiProbe] body preview: ${SensitiveLogRedactor.redactBody(trimmed)}',
  );
}

void _logHttpSummary(RouterHttpResponse response) {
  final contentType = response.headers['content-type']?.firstOrNull;
  final location = response.headers['location']?.firstOrNull;
  final redactedLocation = location == null
      ? 'none'
      : SensitiveLogRedactor.redactUrl(location);
  debugPrint(
    '[AttWifiProbe] status=${response.statusCode} '
    'contentType=${contentType ?? 'unknown'} '
    'bodyLength=${response.body.length} '
    'redirectDetected=${response.redirectDetected} '
    'location=$redactedLocation',
  );
}
