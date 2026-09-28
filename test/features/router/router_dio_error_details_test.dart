import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lynqo/features/router/data/network/router_dio_error_details.dart';

void main() {
  test('formatLines redacts cookie in response headers', () {
    final err = DioException(
      requestOptions: RequestOptions(path: '/success.json'),
      type: DioExceptionType.unknown,
      message: 'test failure',
      response: Response(
        requestOptions: RequestOptions(path: '/success.json'),
        statusCode: 500,
        headers: Headers.fromMap({
          'set-cookie': ['sessionId=secret-value; Path=/'],
          'content-type': ['text/plain'],
        }),
        data: '{"success": true}',
      ),
    );

    final joined = RouterDioErrorDetails.formatLines(err).join('\n');
    expect(joined, isNot(contains('secret-value')));
    expect(joined, contains('[REDACTED]'));
    expect(joined, contains('dioType: unknown'));
  });
}
