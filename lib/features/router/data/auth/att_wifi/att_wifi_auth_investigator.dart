import '../../network/router_http_response.dart';
import 'att_wifi_auth_spec.dart';

class AttWifiAuthInvestigation {
  const AttWifiAuthInvestigation({
    required this.loginFormDetected,
    required this.passwordFieldName,
    required this.authenticationEndpoint,
    required this.httpMethod,
    required this.usesJavaScriptSessionQuery,
    required this.modelJsonEndpoint,
  });

  final bool loginFormDetected;
  final String passwordFieldName;
  final String authenticationEndpoint;
  final String httpMethod;
  final bool usesJavaScriptSessionQuery;
  final String modelJsonEndpoint;
}

class AttWifiAuthInvestigator {
  const AttWifiAuthInvestigator();

  AttWifiAuthInvestigation investigateHtml(String body) {
    final loginFormDetected = body.contains('id="login_form"');
    return AttWifiAuthInvestigation(
      loginFormDetected: loginFormDetected,
      passwordFieldName: AttWifiAuthSpec.passwordFormField,
      authenticationEndpoint: AttWifiAuthSpec.authenticationPath,
      httpMethod: AttWifiAuthSpec.httpMethodPost,
      usesJavaScriptSessionQuery: body.contains('sessionId'),
      modelJsonEndpoint: AttWifiAuthSpec.modelJsonPath,
    );
  }

  AttWifiAuthInvestigation investigateScriptHints(List<String> hints) {
    final usesFormsConfig = hints.any(
      (hint) => hint.contains(AttWifiAuthSpec.authenticationPath),
    );
    return AttWifiAuthInvestigation(
      loginFormDetected: usesFormsConfig,
      passwordFieldName: AttWifiAuthSpec.passwordFormField,
      authenticationEndpoint: AttWifiAuthSpec.authenticationPath,
      httpMethod: AttWifiAuthSpec.httpMethodPost,
      usesJavaScriptSessionQuery: hints.any((h) => h.contains('sessionId')),
      modelJsonEndpoint: AttWifiAuthSpec.modelJsonPath,
    );
  }
}

class AttWifiSessionParser {
  const AttWifiSessionParser._();

  static String? sessionIdFromBootstrap(RouterHttpResponse response) {
    final cookies = response.headers['set-cookie'];
    if (cookies != null) {
      for (final raw in cookies) {
        final segment = raw.split(';').first.trim();
        if (segment.startsWith('${AttWifiAuthSpec.sessionIdCookieName}=')) {
          final value = segment.substring(
            AttWifiAuthSpec.sessionIdCookieName.length + 1,
          );
          if (value.isNotEmpty && value != 'unknown') {
            return value;
          }
        }
      }
    }

    final uri = Uri.tryParse(response.requestUrl);
    final fromQuery =
        uri?.queryParameters[AttWifiAuthSpec.sessionIdQueryParameter];
    if (fromQuery != null && fromQuery.isNotEmpty) {
      return fromQuery;
    }
    return null;
  }

  static String? secTokenFromModelBody(String body) {
    final pattern = '"${AttWifiAuthSpec.secTokenJsonKey}"\\s*:\\s*"([^"]+)"';
    final match = RegExp(pattern).firstMatch(body);
    return match?.group(1);
  }

  static String? userRoleFromModelBody(String body) {
    final pattern = '"${AttWifiAuthSpec.userRoleJsonKey}"\\s*:\\s*"([^"]+)"';
    final match = RegExp(pattern).firstMatch(body);
    return match?.group(1);
  }

  static String cookieHeader(String sessionId) {
    return '${AttWifiAuthSpec.sessionIdCookieName}=$sessionId';
  }

  /// Cookie jar wins over URL query so POST `sessionId` matches the HttpOnly cookie.
  static Future<String?> resolveActiveSessionId({
    required Future<String?> Function() readCookieJar,
    RouterHttpResponse? bootstrapResponse,
  }) async {
    final fromJar = await readCookieJar();
    if (fromJar != null) {
      return fromJar;
    }
    if (bootstrapResponse != null) {
      return sessionIdFromBootstrap(bootstrapResponse);
    }
    return null;
  }
}

class AttWifiLoginResponseParser {
  const AttWifiLoginResponseParser._();

  static AttWifiLoginOutcome parseHttpResponse(RouterHttpResponse response) {
    final fromBody = parse(response.body);
    if (fromBody is AttWifiLoginSuccess ||
        fromBody is AttWifiLoginInvalidCredentials) {
      return fromBody;
    }

    final requestUrl = response.requestUrl;
    if (_urlIndicatesLoginFailed(requestUrl)) {
      return _outcomeFromLoginFailureUrl(requestUrl);
    }
    if (_urlIndicatesHtmlLoginSuccess(requestUrl) &&
        response.statusCode >= 200 &&
        response.statusCode < 300) {
      return const AttWifiLoginOutcome.success();
    }

    return fromBody;
  }

  static bool _urlIndicatesLoginFailed(String url) {
    return url.contains(AttWifiAuthSpec.htmlErrorRedirectPath) ||
        url.contains('loginfailed');
  }

  static AttWifiLoginOutcome _outcomeFromLoginFailureUrl(String url) {
    final errno = errnoFromUrl(url);
    if (errno == AttWifiAuthSpec.invalidPasswordErrno) {
      return const AttWifiLoginOutcome.invalidCredentials();
    }
    if (errno == AttWifiAuthSpec.invalidSessionErrno) {
      return const AttWifiLoginOutcome.sessionError();
    }
    return const AttWifiLoginOutcome.invalidCredentials();
  }

  static int? errnoFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return null;
    }
    final fromParams = uri.queryParameters[AttWifiAuthSpec.errorNumberKey];
    if (fromParams != null && fromParams.isNotEmpty) {
      return int.tryParse(fromParams);
    }
    for (final segment in uri.query.split('&')) {
      if (segment.startsWith('${AttWifiAuthSpec.errorNumberKey}=')) {
        return int.tryParse(
          segment.substring(AttWifiAuthSpec.errorNumberKey.length + 1),
        );
      }
    }
    return null;
  }

  static bool _urlIndicatesHtmlLoginSuccess(String url) {
    if (_urlIndicatesLoginFailed(url)) {
      return false;
    }
    return url.contains(AttWifiAuthSpec.htmlOkRedirectPath) ||
        url.contains(AttWifiAuthSpec.loginPagePath);
  }

  static AttWifiLoginOutcome parse(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return const AttWifiLoginOutcome.unexpected();
    }
    if (!trimmed.startsWith('{')) {
      return const AttWifiLoginOutcome.unexpected();
    }

    final successMatch = RegExp(
      '"${AttWifiAuthSpec.successResponseKey}"\\s*:\\s*true',
    ).hasMatch(trimmed);
    if (successMatch) {
      return const AttWifiLoginOutcome.success();
    }

    final detail = _errorDetailFromBody(trimmed);
    if (detail == AttWifiAuthSpec.invalidPasswordErrorDetail) {
      return const AttWifiLoginOutcome.invalidCredentials();
    }

    if (_hasInvalidPasswordErrorNumber(trimmed)) {
      return const AttWifiLoginOutcome.invalidCredentials();
    }

    return const AttWifiLoginOutcome.unexpected();
  }

  static String? _errorDetailFromBody(String trimmed) {
    for (final key in ['errdetail', 'errDetail']) {
      final match = RegExp('"$key"\\s*:\\s*"([^"]+)"').firstMatch(trimmed);
      final value = match?.group(1);
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  static bool _hasInvalidPasswordErrorNumber(String trimmed) {
    for (final key in ['errno', 'errNo']) {
      if (RegExp(
        '"$key"\\s*:\\s*${AttWifiAuthSpec.invalidPasswordErrno}\\b',
      ).hasMatch(trimmed)) {
        return true;
      }
    }
    return false;
  }
}

sealed class AttWifiLoginOutcome {
  const AttWifiLoginOutcome();

  const factory AttWifiLoginOutcome.success() = AttWifiLoginSuccess;
  const factory AttWifiLoginOutcome.invalidCredentials() =
      AttWifiLoginInvalidCredentials;
  const factory AttWifiLoginOutcome.unexpected() = AttWifiLoginUnexpected;
  const factory AttWifiLoginOutcome.sessionError() = AttWifiLoginSessionError;
}

final class AttWifiLoginSuccess extends AttWifiLoginOutcome {
  const AttWifiLoginSuccess();
}

final class AttWifiLoginInvalidCredentials extends AttWifiLoginOutcome {
  const AttWifiLoginInvalidCredentials();
}

final class AttWifiLoginUnexpected extends AttWifiLoginOutcome {
  const AttWifiLoginUnexpected();
}

final class AttWifiLoginSessionError extends AttWifiLoginOutcome {
  const AttWifiLoginSessionError();
}
