import '../../config/router_config.dart';
import '../../config/router_profile_catalog.dart';
import '../../domain/router_diagnostics.dart';
import '../../domain/router_discovery_result.dart';
import '../../domain/router_failure.dart';
import '../../domain/router_info.dart';
import '../../domain/router_profile.dart';
import '../auth/att_wifi/att_wifi_auth_investigator.dart';
import '../auth/att_wifi/att_wifi_auth_spec.dart';
import '../network/router_client_factory.dart';
import '../network/sensitive_log_redactor.dart';
import '../router_api_client.dart';
import 'router_api_analyzer.dart';

class RouterDiscoveryService {
  RouterDiscoveryService({
    required this._apiClient,
    required this._config,
    RouterApiAnalyzer? analyzer,
    this._clientFactory,
  }) : _analyzer = analyzer ?? RouterApiAnalyzer();

  static const _maxScriptFetchesDefault = 5;
  static const _maxScriptFetchesAttWifi = 12;
  static const _bodyPreviewLength = 2000;

  final RouterApiClient _apiClient;
  final RouterConfig _config;
  final RouterApiAnalyzer _analyzer;
  final RouterClientFactory? _clientFactory;
  final AttWifiAuthInvestigator _attWifiInvestigator =
      const AttWifiAuthInvestigator();

  Future<RouterDiscoveryResult> discover() => discoverProfile(_config.profile);

  Future<List<RouterDiscoveryResult>> discoverKnownProfiles() async {
    final factory =
        _clientFactory ?? RouterClientFactory(transportConfig: _config);
    final results = <RouterDiscoveryResult>[];

    final attBundle = factory.createForProfile(RouterProfileCatalog.attWifi);
    final attResult = await attBundle.discoveryService.discoverProfile(
      RouterProfileCatalog.attWifi,
    );
    results.add(attResult);

    // att_wifi uses http://attwifimanager/ only; do not probe 192.168.0.1 once
    // the captive-DNS host is reachable (default_mifi profile unchanged).
    if (attResult.isSuccess) {
      return results;
    }

    final mifiBundle = factory.createForProfile(
      RouterProfileCatalog.defaultMifi,
    );
    results.add(
      await mifiBundle.discoveryService.discoverProfile(
        RouterProfileCatalog.defaultMifi,
      ),
    );

    return results;
  }

  static RouterDiscoveryResult? selectReachableProfile(
    List<RouterDiscoveryResult> results,
  ) {
    RouterDiscoveryResult? firstReachable;
    RouterDiscoveryResult? attWithLoginForm;

    for (final result in results) {
      if (!result.isSuccess) {
        continue;
      }
      firstReachable ??= result;
      if (result.profile.id == RouterProfileCatalog.attWifiId &&
          result.diagnostics.needsFurtherInspection.any(
            (note) => note.contains('AT&T login form detected'),
          )) {
        attWithLoginForm = result;
      }
    }

    return attWithLoginForm ?? firstReachable;
  }

  Future<RouterDiscoveryResult> discoverProfile(RouterProfile profile) async {
    try {
      final response = await _apiClient.getRoot();
      var analysis = _analyzer.analyze(
        body: response.body,
        contentType: response.contentType,
        statusCode: response.statusCode,
        headers: response.headers,
      );

      final scriptHints = await _fetchScriptHints(
        profile: profile,
        scriptSources: analysis.scriptSources,
      );
      final endpointHints = {
        ...analysis.endpointHints,
        ...scriptHints,
        if (profile.id == RouterProfileCatalog.attWifiId)
          AttWifiAuthSpec.authenticationPath,
        if (profile.id == RouterProfileCatalog.attWifiId)
          AttWifiAuthSpec.modelJsonPath,
      }.take(30).toList();

      final needsInspection = [...analysis.openQuestions];
      if (profile.id == RouterProfileCatalog.attWifiId) {
        final investigation = _attWifiInvestigator.investigateHtml(
          response.body,
        );
        if (investigation.loginFormDetected) {
          needsInspection.add(
            'AT&T login form detected; authentication uses '
            '${investigation.httpMethod} ${investigation.authenticationEndpoint}.',
          );
        }
      }
      if (endpointHints.isEmpty) {
        needsInspection.add(
          'No API endpoints could be inferred automatically from the root page.',
        );
      }
      needsInspection.add(
        'Login/authentication endpoint and payload format are not implemented until confirmed.',
      );

      final diagnostics = RouterDiagnostics(
        routerReachable: true,
        httpStatus: response.statusCode,
        responseContentType: response.contentType,
        redirectDetected: response.redirectDetected,
        authenticationRequired: analysis.authenticationRequired,
        cookiesDetected: response.setCookieNames,
        likelyApiFormat: analysis.likelyApiFormat,
        discoveredEndpointHints: endpointHints,
        bodyPreview: _bodyPreview(response.body),
        needsFurtherInspection: needsInspection,
        finalRequestUrl: SensitiveLogRedactor.redactUrl(response.requestUrl),
        jsonTopLevelKeys: analysis.jsonTopLevelKeys,
      );

      final info = RouterInfo(
        host: profile.host,
        serverHeader: _firstHeader(response.headers, 'server'),
        pageTitle: analysis.pageTitle,
      );

      return RouterDiscoveryResult(
        profile: profile,
        diagnostics: diagnostics,
        info: info,
      );
    } on RouterFailure catch (failure) {
      return RouterDiscoveryResult(
        profile: profile,
        diagnostics: RouterDiagnostics(
          routerReachable: false,
          needsFurtherInspection: [failure.message],
        ),
        failure: failure,
      );
    }
  }

  Future<List<String>> _fetchScriptHints({
    required RouterProfile profile,
    required List<String> scriptSources,
  }) async {
    final hints = <String>{};
    var fetched = 0;

    for (final src in scriptSources) {
      if (fetched >= _maxScriptFetchesFor(profile)) {
        break;
      }
      final path = _resolveScriptPath(profile, src);
      if (path == null) {
        continue;
      }
      try {
        final scriptResponse = await _apiClient.getPath(path);
        hints.addAll(_analyzer.analyzeScriptContent(scriptResponse.body));
        fetched++;
      } catch (_) {
        continue;
      }
    }

    return hints.toList();
  }

  int _maxScriptFetchesFor(RouterProfile profile) {
    if (profile.id == RouterProfileCatalog.attWifiId) {
      return _maxScriptFetchesAttWifi;
    }
    return _maxScriptFetchesDefault;
  }

  String? _resolveScriptPath(RouterProfile profile, String src) {
    if (src.startsWith('http://') || src.startsWith('https://')) {
      final uri = Uri.tryParse(src);
      if (uri == null || uri.host != profile.host) {
        return null;
      }
      return uri.path.isEmpty ? '/' : uri.path;
    }
    if (src.startsWith('/')) {
      return src;
    }
    return '/$src';
  }

  String? _firstHeader(Map<String, List<String>> headers, String name) {
    final values = headers[name];
    if (values == null || values.isEmpty) {
      return null;
    }
    return values.first;
  }

  String? _bodyPreview(String body) {
    if (body.isEmpty) {
      return null;
    }
    final redacted = SensitiveLogRedactor.redactBody(body);
    if (redacted.startsWith('[REDACTED')) {
      return redacted;
    }
    if (redacted.length <= _bodyPreviewLength) {
      return redacted;
    }
    return '${redacted.substring(0, _bodyPreviewLength)}…';
  }
}
