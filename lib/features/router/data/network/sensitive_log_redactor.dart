abstract final class SensitiveLogRedactor {
  static const _sensitiveHeaderNames = {
    'authorization',
    'cookie',
    'set-cookie',
    'x-csrf-token',
    'x-xsrf-token',
  };

  static final _sensitiveKeyPattern = RegExp(
    r'(password|passwd|token|session|csrf|cookie|auth|credential|secret|sessionid)',
    caseSensitive: false,
  );

  static const _alwaysRedactQueryKeys = {'sessionid'};

  static Map<String, dynamic> redactHeaders(Map<String, dynamic> headers) {
    final redacted = <String, dynamic>{};
    for (final entry in headers.entries) {
      final key = entry.key.toString();
      if (_sensitiveHeaderNames.contains(key.toLowerCase())) {
        redacted[key] = '[REDACTED]';
      } else {
        redacted[key] = entry.value;
      }
    }
    return redacted;
  }

  static String redactBody(String body) {
    if (body.isEmpty) {
      return body;
    }
    if (_sensitiveKeyPattern.hasMatch(body)) {
      return '[REDACTED: body may contain sensitive fields]';
    }
    return body.length > 500 ? '${body.substring(0, 500)}…' : body;
  }

  static String redactUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return url;
    }
    if (uri.queryParameters.isEmpty) {
      return url;
    }
    final redactedQuery = <String, String>{};
    var stripped = false;
    for (final entry in uri.queryParameters.entries) {
      final key = entry.key;
      if (_alwaysRedactQueryKeys.contains(key.toLowerCase()) ||
          _sensitiveKeyPattern.hasMatch(key)) {
        stripped = true;
        continue;
      }
      redactedQuery[key] = entry.value;
    }
    if (!stripped) {
      return url;
    }
    if (redactedQuery.isEmpty) {
      return uri.replace(queryParameters: null).toString();
    }
    return uri.replace(queryParameters: redactedQuery).toString();
  }
}
