import 'dart:typed_data';

import 'package:dio/dio.dart';

// Test mock HTTP adapter for Dio-based router network tests.
class MockHttpAdapter implements HttpClientAdapter {
  MockHttpAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }
}

ResponseBody mockResponse({
  required int statusCode,
  String body = '',
  Map<String, List<String>> headers = const {},
}) {
  return ResponseBody.fromString(body, statusCode, headers: headers);
}
