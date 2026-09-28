import 'package:dio/dio.dart';

import 'router_dio_error_details.dart';
import 'sensitive_log_redactor.dart';

class RouterLogInterceptor extends Interceptor {
  RouterLogInterceptor({required this.enabled});

  final bool enabled;

  static const _startTimeKey = 'router_log_start_ms';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (enabled) {
      options.extra[_startTimeKey] = DateTime.now().millisecondsSinceEpoch;
      final cookieViaHeader = _cookieHeaderSent(options);
      // ignore: avoid_print
      print(
        '[Router] --> ${options.method} '
        '${SensitiveLogRedactor.redactUrl(options.uri.toString())} '
        'cookie via header: ${cookieViaHeader ? 'yes' : 'no'}',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (enabled) {
      final contentType = response.headers.value('content-type');
      final requestUri = response.requestOptions.uri.toString();
      final finalUri = response.realUri.toString();
      final redirectNote = requestUri != finalUri
          ? ' -> ${SensitiveLogRedactor.redactUrl(finalUri)}'
          : '';
      final durationMs = _elapsedMs(response.requestOptions);
      final setCookieReceived = _setCookieReceived(response);
      final bodyLength = _responseBodyLength(response);
      // ignore: avoid_print
      print(
        '[Router] <-- ${response.statusCode} '
        '${SensitiveLogRedactor.redactUrl(requestUri)}'
        '$redirectNote'
        '${contentType != null ? ' ($contentType)' : ''}'
        ' duration: ${durationMs}ms'
        ' set-cookie received: ${setCookieReceived ? 'yes' : 'no'}'
        ' bodyLength: $bodyLength',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (enabled) {
      final durationMs = _elapsedMs(err.requestOptions);
      // ignore: avoid_print
      print(
        '[Router] ERROR ${err.requestOptions.method} '
        '${SensitiveLogRedactor.redactUrl(err.requestOptions.uri.toString())} '
        'duration: ${durationMs}ms',
      );
      for (final line in RouterDioErrorDetails.formatLines(err)) {
        // ignore: avoid_print
        print('[Router] ERROR detail $line');
      }
    }
    handler.next(err);
  }

  int _elapsedMs(RequestOptions options) {
    final start = options.extra[_startTimeKey];
    if (start is! int) {
      return 0;
    }
    return DateTime.now().millisecondsSinceEpoch - start;
  }

  bool _cookieHeaderSent(RequestOptions options) {
    final headers = options.headers;
    for (final key in headers.keys) {
      if (key.toString().toLowerCase() == 'cookie') {
        return true;
      }
    }
    return false;
  }

  bool _setCookieReceived(Response<dynamic> response) {
    final values = response.headers.map['set-cookie'] ??
        response.headers.map['Set-Cookie'];
    return values != null && values.isNotEmpty;
  }

  int _responseBodyLength(Response<dynamic> response) {
    final data = response.data;
    if (data is List<int>) {
      return data.length;
    }
    if (data is String) {
      return data.length;
    }
    return 0;
  }
}
