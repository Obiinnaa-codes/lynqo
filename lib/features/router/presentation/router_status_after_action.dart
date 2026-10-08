import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/router_dashboard_provider.dart';

Future<void> refreshRouterStatusAfterAction(WidgetRef ref) async {
  final status = await ref.read(attWifiDashboardServiceProvider).fetchStatus();
  ref.read(lastDashboardStatusProvider.notifier).setStatus(status);
}
