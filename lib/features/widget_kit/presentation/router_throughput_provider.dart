import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../router/presentation/providers/router_dashboard_provider.dart';
import '../data/router_throughput_tracker.dart';
import '../domain/models/widget_view_models.dart';

final routerThroughputTrackerProvider = Provider<RouterThroughputTracker>((ref) {
  final tracker = RouterThroughputTracker();
  ref.onDispose(tracker.reset);
  ref.listen(
    routerDashboardProvider,
    (previous, next) {
      next.whenData(tracker.ingest);
    },
    fireImmediately: true,
  );
  return tracker;
});

final routerNetworkSpeedProvider = Provider<NetworkSpeedWidgetData>((ref) {
  ref.watch(routerDashboardProvider);
  ref.watch(routerThroughputTrackerProvider);
  return ref.read(routerThroughputTrackerProvider).last;
});
