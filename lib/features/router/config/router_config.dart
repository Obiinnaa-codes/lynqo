import 'package:flutter/foundation.dart';

import '../domain/router_profile.dart';
import 'router_profile_catalog.dart';

class RouterConfig {
  const RouterConfig({
    required this.profile,
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 15),
    this.enableDevelopmentLogging = kDebugMode,
    this.maxResponseBodyBytes = 512 * 1024,
  });

  final RouterProfile profile;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final bool enableDevelopmentLogging;
  final int maxResponseBodyBytes;

  String get host => profile.host;

  String get scheme => profile.scheme;

  String get baseUrl => profile.baseUrl;

  factory RouterConfig.development() {
    return RouterConfig(profile: RouterProfileCatalog.defaultMifi);
  }

  RouterConfig forProfile(RouterProfile profile) {
    return RouterConfig(
      profile: profile,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      enableDevelopmentLogging: enableDevelopmentLogging,
      maxResponseBodyBytes: maxResponseBodyBytes,
    );
  }
}
