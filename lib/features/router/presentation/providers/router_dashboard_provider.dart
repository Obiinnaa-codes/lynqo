import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/router_status.dart';
import '../../data/att_wifi_dashboard_service.dart';
import '../../data/att_wifi_device_actions_service.dart';
import 'router_providers.dart';

final attWifiDashboardServiceProvider = Provider<AttWifiDashboardService>((ref) {
  return AttWifiDashboardService(
    clientFactory: ref.watch(routerClientFactoryProvider),
    secureStorage: ref.watch(routerSecureStorageProvider),
    authService: ref.watch(routerAuthServiceProvider),
  );
});

final attWifiDeviceActionsServiceProvider =
    Provider<AttWifiDeviceActionsService>((ref) {
  return AttWifiDeviceActionsService(
    clientFactory: ref.watch(routerClientFactoryProvider),
    secureStorage: ref.watch(routerSecureStorageProvider),
    authService: ref.watch(routerAuthServiceProvider),
  );
});

class LastDashboardStatus extends Notifier<RouterStatus?> {
  @override
  RouterStatus? build() => null;

  void setStatus(RouterStatus status) => state = status;

  void clear() => state = null;
}

final lastDashboardStatusProvider =
    NotifierProvider<LastDashboardStatus, RouterStatus?>(
      LastDashboardStatus.new,
    );

final routerDashboardProvider = StreamProvider<RouterStatus>((ref) async* {
  final service = ref.read(attWifiDashboardServiceProvider);
  await for (final status in service.watchStatus()) {
    ref.read(lastDashboardStatusProvider.notifier).setStatus(status);
    yield status;
  }
});

class DashboardAwaitingMiFi extends Notifier<bool> {
  @override
  bool build() => false;

  void setAwaiting(bool value) => state = value;
}

/// True after Restart until the dashboard poll succeeds again.
final dashboardAwaitingMiFiProvider =
    NotifierProvider<DashboardAwaitingMiFi, bool>(DashboardAwaitingMiFi.new);
