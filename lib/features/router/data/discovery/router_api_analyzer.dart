import 'dart:convert';

import '../../domain/possible_api_format.dart';

class RouterApiAnalysis {
  const RouterApiAnalysis({
    required this.likelyApiFormat,
    this.endpointHints = const [],
    this.openQuestions = const [],
    this.jsonTopLevelKeys = const [],
    this.pageTitle,
    this.scriptSources = const [],
    this.authenticationRequired = false,
  });

  final PossibleApiFormat likelyApiFormat;
  final List<String> endpointHints;
  final List<String> openQuestions;
  final List<String> jsonTopLevelKeys;
  final String? pageTitle;
  final List<String> scriptSources;
  final bool authenticationRequired;
}

class RouterApiAnalyzer {
  static final _endpointPattern = RegExp(
    r'''(?:["'`])(/(?:api|cgi-bin|goform|xml|json|wlan|device|status|login|auth)[^"'`\s]*)["'`]''',
    caseSensitive: false,
  );

  static final _genericPathPattern = RegExp(
    r'''["'`]([/][a-zA-Z0-9_./-]+\.(?:cgi|asp|aspx|json|xml|do|action))["'`]''',
    caseSensitive: false,
  );

  static final _fetchPattern = RegExp(
    r'''fetch\s*\(\s*["'`]([^"'`]+)["'`]''',
    caseSensitive: false,
  );

  static final _xhrPattern = RegExp(
    r'''\.open\s*\(\s*["'`][A-Z]+["'`]\s*,\s*["'`]([^"'`]+)["'`]''',
    caseSensitive: false,
  );

  RouterApiAnalysis analyze({
    required String body,
    String? contentType,
    int? statusCode,
    Map<String, List<String>> headers = const {},
  }) {
    final format = _detectFormat(body, contentType);
    final hints = <String>{};
    final questions = <String>[];
    final scriptSources = <String>[];
    var authRequired = _statusImpliesAuth(statusCode, headers);

    if (format == PossibleApiFormat.json) {
      final keys = _jsonTopLevelKeys(body);
      return RouterApiAnalysis(
        likelyApiFormat: format,
        jsonTopLevelKeys: keys,
        endpointHints: const [],
        openQuestions: keys.isEmpty
            ? const ['JSON body could not be parsed.']
            : const [],
        authenticationRequired: authRequired,
      );
    }

    if (format == PossibleApiFormat.xml) {
      return RouterApiAnalysis(
        likelyApiFormat: format,
        openQuestions: const [
          'XML response detected; identify request endpoints from router docs or captured traffic.',
        ],
        authenticationRequired: authRequired,
      );
    }

    if (format == PossibleApiFormat.html || _looksLikeHtml(body)) {
      authRequired =
          authRequired || _htmlImpliesAuth(body, statusCode, headers);
      hints.addAll(_extractHtmlEndpointHints(body));
      scriptSources.addAll(_extractScriptSources(body));
      final title = _extractTitle(body);

      if (scriptSources.isNotEmpty) {
        questions.add(
          'Inspect linked JavaScript for API paths (${scriptSources.length} script(s) found).',
        );
      }
      if (_hasPasswordField(body)) {
        questions.add(
          'Login form with password field detected; submit URL and CSRF/session rules are not confirmed.',
        );
      }
      if (hints.isEmpty) {
        questions.add(
          'No API endpoint hints found in HTML; manual inspection of the web UI or JS bundles may be required.',
        );
      }

      return RouterApiAnalysis(
        likelyApiFormat: PossibleApiFormat.html,
        endpointHints: hints.toList(),
        openQuestions: questions,
        pageTitle: title,
        scriptSources: scriptSources,
        authenticationRequired: authRequired,
      );
    }

    return RouterApiAnalysis(
      likelyApiFormat: format,
      openQuestions: const [
        'Response format is unclear; capture more router traffic to identify the API.',
      ],
      authenticationRequired: authRequired,
    );
  }

  List<String> analyzeScriptContent(String scriptBody) {
    return _extractEndpointHintsFromText(scriptBody);
  }

  static PossibleApiFormat _detectFormat(String body, String? contentType) {
    final type = contentType?.toLowerCase() ?? '';
    if (type.contains('json')) {
      return PossibleApiFormat.json;
    }
    if (type.contains('xml')) {
      return PossibleApiFormat.xml;
    }
    if (type.contains('html')) {
      return PossibleApiFormat.html;
    }
    final trimmed = body.trimLeft();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      return PossibleApiFormat.json;
    }
    if (trimmed.startsWith('<?xml') || trimmed.startsWith('<')) {
      if (trimmed.toLowerCase().contains('<html')) {
        return PossibleApiFormat.html;
      }
      return PossibleApiFormat.xml;
    }
    if (body.isEmpty) {
      return PossibleApiFormat.unknown;
    }
    return PossibleApiFormat.plain;
  }

  static bool _looksLikeHtml(String body) {
    final lower = body.toLowerCase();
    return lower.contains('<html') ||
        lower.contains('<!doctype html') ||
        lower.contains('<head');
  }

  static bool _statusImpliesAuth(
    int? statusCode,
    Map<String, List<String>> headers,
  ) {
    if (statusCode == 401 || statusCode == 403) {
      return true;
    }
    return headers.containsKey('www-authenticate');
  }

  static bool _htmlImpliesAuth(
    String body,
    int? statusCode,
    Map<String, List<String>> headers,
  ) {
    if (_statusImpliesAuth(statusCode, headers)) {
      return true;
    }
    final lower = body.toLowerCase();
    if (lower.contains('type="password"') ||
        lower.contains("type='password'")) {
      return true;
    }
    if (lower.contains('login') && lower.contains('<form')) {
      return true;
    }
    return false;
  }

  static bool _hasPasswordField(String body) {
    final lower = body.toLowerCase();
    return lower.contains('type="password"') ||
        lower.contains("type='password'");
  }

  static String? _extractTitle(String body) {
    final match = RegExp(
      r'<title[^>]*>([^<]*)</title>',
      caseSensitive: false,
    ).firstMatch(body);
    return match?.group(1)?.trim();
  }

  static List<String> _extractScriptSources(String body) {
    final pattern = RegExp(
      r'''<script[^>]+src=["']([^"']+)["']''',
      caseSensitive: false,
    );
    return pattern
        .allMatches(body)
        .map((m) => m.group(1)!)
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static List<String> _extractHtmlEndpointHints(String body) {
    final hints = <String>{};
    hints.addAll(_extractEndpointHintsFromText(body));

    final formAction = RegExp(
      r'''<form[^>]+action=["']([^"']+)["']''',
      caseSensitive: false,
    );
    for (final match in formAction.allMatches(body)) {
      final action = match.group(1);
      if (action != null && action.isNotEmpty && action != '#') {
        hints.add(action);
      }
    }

    return hints.take(30).toList();
  }

  static List<String> _extractEndpointHintsFromText(String text) {
    final hints = <String>{};
    for (final pattern in [
      _endpointPattern,
      _genericPathPattern,
      _fetchPattern,
      _xhrPattern,
    ]) {
      for (final match in pattern.allMatches(text)) {
        final value = match.group(1);
        if (value != null && value.startsWith('/')) {
          hints.add(value);
        }
      }
    }
    return hints.take(30).toList();
  }

  static List<String> _jsonTopLevelKeys(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        return decoded.keys.map((k) => k.toString()).toList();
      }
    } catch (_) {
      return const [];
    }
    return const [];
  }
}
