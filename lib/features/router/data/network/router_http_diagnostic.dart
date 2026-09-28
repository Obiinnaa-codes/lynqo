import 'package:flutter/foundation.dart';

import 'router_http_response.dart';
import 'sensitive_log_redactor.dart';

/// Safe cookie attachment summary (no values).
class CookieSendReport {
  const CookieSendReport({
    required this.jarContainsSession,
    required this.explicitCookieHeader,
    required this.jarCookieCount,
    required this.jarCookieNames,
    required this.explicitCookieNames,
    required this.querySessionMatchesJar,
  });

  final bool jarContainsSession;
  final bool explicitCookieHeader;
  final int jarCookieCount;
  final List<String> jarCookieNames;
  final List<String> explicitCookieNames;
  final bool querySessionMatchesJar;

  void logToDebugPrint() {
    if (!kDebugMode) {
      return;
    }
    debugPrint(
      '[Router] cookie attachment '
      'jarContainsSession: ${jarContainsSession ? 'yes' : 'no'} '
      'explicitCookieHeader: ${explicitCookieHeader ? 'yes' : 'no'} '
      'jarCookieCount: $jarCookieCount '
      'jarCookieNames: ${jarCookieNames.join(', ')} '
      'explicitCookieNames: ${explicitCookieNames.join(', ')} '
      'querySessionMatchesJar: ${querySessionMatchesJar ? 'yes' : 'no'}',
    );
  }
}

abstract final class RouterHttpDiagnostic {
  static List<String> explicitCookieNamesFromHeader(String? cookieHeader) {
    if (cookieHeader == null || cookieHeader.isEmpty) {
      return const [];
    }
    final names = <String>[];
    for (final part in cookieHeader.split(';')) {
      final segment = part.trim();
      if (segment.isEmpty) {
        continue;
      }
      final eq = segment.indexOf('=');
      final name = eq < 0 ? segment : segment.substring(0, eq).trim();
      if (name.isNotEmpty) {
        names.add(name);
      }
    }
    return names;
  }

  static String bodyFormatHint(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return 'empty';
    }
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      return 'json';
    }
    if (trimmed.toLowerCase().contains('<html')) {
      return 'html';
    }
    return 'plain';
  }

  static void logHop({
    required int hop,
    required String requestLabel,
    required RouterHttpResponse response,
  }) {
    if (!kDebugMode) {
      return;
    }
    final location = response.headers['location']?.firstOrNull;
    final redactedLocation = location == null
        ? 'none'
        : SensitiveLogRedactor.redactUrl(location);
    final contentType = response.contentType ?? 'unknown';
    final format = bodyFormatHint(response.body);
    final preview = SensitiveLogRedactor.redactBody(response.body.trim());
    debugPrint(
      '[Router] post-login model probe hop=$hop '
      'request=$requestLabel '
      'status=${response.statusCode} '
      'location=$redactedLocation '
      'contentType=$contentType '
      'bodyFormat=$format '
      'bodyLength=${response.body.length} '
      'preview=$preview',
    );
  }

  static void logSetCookieNames(String context, RouterHttpResponse response) {
    if (!kDebugMode) {
      return;
    }
    final names = response.setCookieNames;
    debugPrint(
      '[Router] $context set-cookie names: '
      '${names.isEmpty ? '(none)' : names.join(', ')}',
    );
  }
}
