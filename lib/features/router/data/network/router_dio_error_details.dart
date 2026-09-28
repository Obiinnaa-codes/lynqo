import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'sensitive_log_redactor.dart';

/// Safe, development-only detail lines for [DioException] (no secrets).
abstract final class RouterDioErrorDetails {
  static List<String> formatLines(DioException err) {
    final lines = <String>[
      'dioType: ${err.type.name}',
      'dioMessage: ${err.message ?? 'none'}',
      'exceptionRuntimeType: ${err.runtimeType}',
      'exceptionToString: ${SensitiveLogRedactor.redactBody(err.toString())}',
    ];

    final underlying = err.error;
    if (underlying != null) {
      lines.add('errorRuntimeType: ${underlying.runtimeType}');
      lines.add(
        'errorToString: ${SensitiveLogRedactor.redactBody(underlying.toString())}',
      );
    }

    final response = err.response;
    if (response != null) {
      lines.add('httpStatus: ${response.statusCode}');
      final contentType = response.headers.value('content-type');
      if (contentType != null) {
        lines.add('contentType: $contentType');
      }
      final headerMap = <String, dynamic>{};
      for (final entry in response.headers.map.entries) {
        headerMap[entry.key] = entry.value;
      }
      final redactedHeaders = SensitiveLogRedactor.redactHeaders(headerMap);
      lines.add('responseHeaders: $redactedHeaders');
      lines.add('responseBodyLength: ${_responseBodyLength(response)}');
      final preview = _responseBodyPreview(response);
      if (preview != null) {
        lines.add('responseBodyPreview: $preview');
      }
    }

    if (kDebugMode && err.stackTrace != StackTrace.empty) {
      lines.add('stackTrace: ${err.stackTrace}');
    }

    return lines;
  }

  static String formatSingleLine(DioException err) {
    return formatLines(err).join(' | ');
  }

  static int _responseBodyLength(Response<dynamic> response) {
    final data = response.data;
    if (data is List<int>) {
      return data.length;
    }
    if (data is String) {
      return data.length;
    }
    return 0;
  }

  static String? _responseBodyPreview(Response<dynamic> response) {
    final data = response.data;
    String text;
    if (data is List<int>) {
      if (data.isEmpty) {
        return null;
      }
      text = utf8.decode(data, allowMalformed: true);
    } else if (data is String) {
      if (data.isEmpty) {
        return null;
      }
      text = data;
    } else {
      return null;
    }

    final trimmed = text.trim();
    if (trimmed.startsWith('{')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) {
          return 'json keys: ${decoded.keys.map((k) => k.toString()).join(', ')}';
        }
      } catch (_) {
        // fall through to redacted preview
      }
    }
    if (trimmed.toLowerCase().contains('<html')) {
      return 'format: html';
    }
    return SensitiveLogRedactor.redactBody(trimmed);
  }
}
