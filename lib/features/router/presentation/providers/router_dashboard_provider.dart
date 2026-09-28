import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/router_status.dart';
import '../../data/att_wifi_dashboard_service.dart';
import 'router_providers.dart';

final attWifiDashboardServiceProvider = Provider<AttWifiDashboardService>((ref) {
  return AttWifiDashboardService(
    clientFactory: ref.watch(routerClientFactoryProvider),
    secureStorage: ref.watch(routerSecureStorageProvider),
  );
});

final routerDashboardProvider = StreamProvider<RouterStatus>((ref) {
  final service = ref.watch(attWifiDashboardServiceProvider);
  return service.watchStatus();
});
