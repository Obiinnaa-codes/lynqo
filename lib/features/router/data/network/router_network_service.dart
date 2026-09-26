import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../config/router_config.dart';
import '../../domain/router_failure.dart';
import 'router_connectivity_gate.dart';
import 'router_http_response.dart';
import 'sensitive_log_redactor.dart';

class RouterNetworkService {
  RouterNetworkService({
    required this._dio,
    required this._config,
    CookieJar? cookieJar,
    Future<List<ConnectivityResult>> Function()? connectivityCheck,
  }) : _cookieJar = cookieJar,
       _connectivityCheck =
           connectivityCheck ?? (() => Connectivity().checkConnectivity());

  final Dio _dio;
  final RouterConfig _config;
  final CookieJar? _cookieJar;
  final Future<List<ConnectivityResult>> Function() _connectivityCheck;

  String get baseUrl => _config.baseUrl;

  Future<String?> readSessionIdFromCookieJar() async {
    final jar = _cookieJar;
    if (jar == null) {
      return null;
    }
    final uri = Uri.parse(_config.baseUrl);
    final cookies = await jar.loadForRequest(uri);
    for (final cookie in cookies) {
      if (cookie.name == 'sessionId' &&
          cookie.value.isNotEmpty &&
          cookie.value != 'unknown') {
        return cookie.value;
      }
    }
    return null;
  }

  Future<void> ensureNetworkAvailable() async {
    final results = await _connectivityCheck();
    if (kDebugMode) {
      debugPrint('[RouterConnectivity] ensureNetworkAvailable invoked');
    }
    if (shouldBlockForConnectivity(results)) {
      throw const NetworkUnavailable();
    }
  }

  Future<bool> isReachable() async {
    try {
      final response = await get('/');
      return response.statusCode > 0;
    } on RouterFailure {
      return false;
    }
  }

  Future<RouterHttpResponse> get(
    String path, {
    bool followRedirects = true,
    Map<String, String>? queryParameters,
    String? cookieHeader,
  }) async {
    try {
      final response = await _dio.get<List<int>>(
        path,
        queryParameters: queryParameters,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: followRedirects,
          headers: cookieHeader == null ? null : {'Cookie': cookieHeader},
        ),
      );

      final bytes = response.data ?? const <int>[];
      final truncated = bytes.length > _config.maxResponseBodyBytes;
      final capped = truncated
          ? bytes.sublist(0, _config.maxResponseBodyBytes)
          : bytes;
      final body = utf8.decode(capped, allowMalformed: true);

      final status = response.statusCode;
      final redirectDetected =
          (status != null && status >= 300 && status < 400) ||
          response.requestOptions.uri.toString() != response.realUri.toString();

      return RouterHttpResponse(
        statusCode: response.statusCode ?? 0,
        headers: _normalizeHeaders(response.headers.map),
        body: body,
        requestUrl: response.realUri.toString(),
        redirectDetected: redirectDetected,
        bodyTruncated: truncated,
      );
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  static const _formPostMaxRedirects = 5;

  Future<RouterHttpResponse> postForm(
    String path, {
    Map<String, String>? queryParameters,
    required Map<String, String> fields,
    String? cookieHeader,
  }) async {
    try {
      final body = fields.entries
          .map(
            (entry) =>
                '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
          )
          .join('&');

      final response = await _dio.post<List<int>>(
        path,
        data: body,
        queryParameters: queryParameters,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          maxRedirects: _formPostMaxRedirects,
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Cookie': ?cookieHeader,
          },
        ),
      );

      var httpResponse = _responseFromDio(response);

      final location = _singleHeaderValue(httpResponse.headers, 'location');
      final shouldFollow = _shouldFollowFormRedirect(httpResponse, location);

      if (shouldFollow && location != null && location.isNotEmpty) {
        _logFormPostRedirect(
          method: 'POST',
          path: path,
          statusCode: httpResponse.statusCode,
          location: location,
        );
        final redirectUri = _resolveRedirectUri(location);
        final followPath = redirectUri.path.isEmpty ? '/' : redirectUri.path;
        final followQuery = redirectUri.queryParameters.isEmpty
            ? null
            : redirectUri.queryParameters;
        httpResponse = await get(
          followPath,
          queryParameters: followQuery,
          cookieHeader: cookieHeader,
        );
        return RouterHttpResponse(
          statusCode: httpResponse.statusCode,
          headers: httpResponse.headers,
          body: httpResponse.body,
          requestUrl: httpResponse.requestUrl,
          redirectDetected: true,
          bodyTruncated: httpResponse.bodyTruncated,
        );
      }

      if (httpResponse.statusCode >= 300 && httpResponse.statusCode < 400) {
        _logFormPostRedirect(
          method: 'POST',
          path: path,
          statusCode: httpResponse.statusCode,
          location: location,
        );
      }

      final dioRedirect =
          response.requestOptions.uri.toString() != response.realUri.toString();
      return RouterHttpResponse(
        statusCode: httpResponse.statusCode,
        headers: httpResponse.headers,
        body: httpResponse.body,
        requestUrl: httpResponse.requestUrl,
        redirectDetected:
            dioRedirect ||
            (httpResponse.statusCode >= 300 && httpResponse.statusCode < 400),
        bodyTruncated: httpResponse.bodyTruncated,
      );
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  RouterHttpResponse _responseFromDio(Response<List<int>> response) {
    final bytes = response.data ?? const <int>[];
    final truncated = bytes.length > _config.maxResponseBodyBytes;
    final capped = truncated
        ? bytes.sublist(0, _config.maxResponseBodyBytes)
        : bytes;
    final responseBody = utf8.decode(capped, allowMalformed: true);

    return RouterHttpResponse(
      statusCode: response.statusCode ?? 0,
      headers: _normalizeHeaders(response.headers.map),
      body: responseBody,
      requestUrl: response.realUri.toString(),
      redirectDetected: false,
      bodyTruncated: truncated,
    );
  }

  bool _shouldFollowFormRedirect(
    RouterHttpResponse response,
    String? location,
  ) {
    if (location == null || location.isEmpty) {
      return false;
    }
    final status = response.statusCode;
    if (status >= 300 && status < 400) {
      return true;
    }
    final trimmed = response.body.trim();
    return trimmed.isEmpty || !trimmed.startsWith('{');
  }

  Uri _resolveRedirectUri(String location) {
    final parsed = Uri.tryParse(location);
    if (parsed == null) {
      return Uri.parse(_config.baseUrl);
    }
    if (parsed.hasScheme) {
      return parsed;
    }
    final base = Uri.parse(_config.baseUrl);
    if (location.startsWith('/')) {
      return base.replace(
        path: parsed.path,
        query: parsed.hasQuery ? parsed.query : null,
      );
    }
    return base.resolve(location);
  }

  String? _singleHeaderValue(Map<String, List<String>> headers, String name) {
    final values = headers[name];
    if (values == null || values.isEmpty) {
      return null;
    }
    return values.first;
  }

  void _logFormPostRedirect({
    required String method,
    required String path,
    required int statusCode,
    required String? location,
  }) {
    if (!kDebugMode || !_config.enableDevelopmentLogging) {
      return;
    }
    final redactedLocation = location == null
        ? 'none'
        : SensitiveLogRedactor.redactUrl(
            _resolveRedirectUri(location).toString(),
          );
    debugPrint(
      '[Router] form POST redirect status=$statusCode '
      'path=$path location=$redactedLocation',
    );
  }

  RouterFailure _mapDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ConnectionTimeout();
      case DioExceptionType.connectionError:
        return const RouterNotReachable();
      case DioExceptionType.badResponse:
        return InvalidResponse(
          'Unexpected HTTP response from the MiFi (${error.response?.statusCode}).',
        );
      case DioExceptionType.cancel:
        return const RouterNotReachable('Request to the MiFi was cancelled.');
      case DioExceptionType.badCertificate:
        return const InvalidResponse('Invalid certificate from the MiFi.');
      case DioExceptionType.transformTimeout:
        return const ConnectionTimeout();
      case DioExceptionType.unknown:
        return RouterNotReachable(error.message ?? 'Could not reach the MiFi.');
    }
  }

  Map<String, List<String>> _normalizeHeaders(
    Map<String, List<String>> headers,
  ) {
    final normalized = <String, List<String>>{};
    for (final entry in headers.entries) {
      normalized[entry.key.toLowerCase()] = entry.value;
    }
    return normalized;
  }
}
