import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../router/presentation/providers/router_dashboard_provider.dart';
import '../../router/presentation/providers/router_providers.dart';
import '../data/lynqo_home_widget.dart';
import '../data/router_widget_mappers.dart';
import 'router_throughput_provider.dart';

/// Pushes dashboard snapshots to the iOS home screen widget when data updates.
final lynqoHomeWidgetSyncProvider = Provider<void>((ref) {
  if (!Platform.isIOS) {
    return;
  }

  ref.listen(routerDashboardProvider, (previous, next) {
    next.whenOrNull(
      data: (status) {
        final routerHost = ref.read(routerConfigProvider).host;
        final networkSpeed = ref.read(routerNetworkSpeedProvider);
        final snapshot = RouterWidgetMappers.fromRouterStatus(
          status,
          routerHost: routerHost,
          networkSpeed: networkSpeed,
        );
        unawaited(LynqoHomeWidget.publishSnapshot(snapshot));
      },
    );
  });
});
