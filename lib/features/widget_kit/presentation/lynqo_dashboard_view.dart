import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_spacing.dart';
import '../../router/data/att_wifi_dashboard_service.dart';
import '../domain/lynqo_router_widget_snapshot.dart';
import '../layout/lynqo_dashboard_layout.dart';
import '../layout/lynqo_widget_grid.dart';
import '../theme/lynqo_widget_theme.dart';

class LynqoDashboardView extends StatelessWidget {
  const LynqoDashboardView({
    super.key,
    required this.snapshot,
    required this.onRefresh,
  });

  final LynqoRouterWidgetSnapshot snapshot;
  final Future<void> Function() onRefresh;

  LynqoWidgetTheme _widgetTheme(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    return brightness == Brightness.dark
        ? LynqoWidgetTheme.dark
        : LynqoWidgetTheme.light;
  }

  @override
  Widget build(BuildContext context) {
    final widgetTheme = _widgetTheme(context);
    final updatedLabel = DateFormat.jm().format(snapshot.updatedAt.toLocal());

    return Theme(
      data: Theme.of(context).copyWith(
        extensions: [widgetTheme],
        scaffoldBackgroundColor: widgetTheme.scaffoldColor,
      ),
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            LynqoWidgetGrid(
              snapshot: snapshot,
              entries: LynqoDashboardLayout.entries,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Updated $updatedLabel · refreshes every '
              '${AttWifiDashboardService.refreshInterval.inSeconds}s',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
