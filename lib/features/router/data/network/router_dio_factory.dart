import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

import '../../config/router_config.dart';
import 'router_log_interceptor.dart';

Dio createRouterDio(RouterConfig config, {CookieJar? cookieJar}) {
  final jar = cookieJar ?? CookieJar();
  final dio = Dio(
    BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: config.connectTimeout,
      receiveTimeout: config.receiveTimeout,
      headers: const {
        'Accept': '*/*',
        'User-Agent': 'Lynqo/1.0 (MiFi; development)',
      },
      validateStatus: (_) => true,
      followRedirects: true,
      maxRedirects: 5,
    ),
  );

  dio.interceptors.add(CookieManager(jar));
  dio.interceptors.add(
    RouterLogInterceptor(enabled: config.enableDevelopmentLogging),
  );

  return dio;
}
