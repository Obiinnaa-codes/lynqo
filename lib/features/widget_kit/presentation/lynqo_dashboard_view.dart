import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_spacing.dart';
import '../../router/data/att_wifi_dashboard_service.dart';
import '../../router/domain/router_status.dart';
import '../domain/lynqo_router_widget_snapshot.dart';
import '../layout/lynqo_dashboard_layout.dart';
import '../layout/lynqo_widget_grid.dart';
import '../theme/lynqo_widget_theme.dart';
import 'dashboard_pull_to_refresh_hint.dart';

class LynqoDashboardView extends StatefulWidget {
  const LynqoDashboardView({
    super.key,
    required this.snapshot,
    required this.routerStatus,
    required this.onRefresh,
    this.awaitingMiFi = false,
  });

  final LynqoRouterWidgetSnapshot snapshot;
  final RouterStatus routerStatus;
  final Future<void> Function() onRefresh;
  final bool awaitingMiFi;

  @override
  State<LynqoDashboardView> createState() => _LynqoDashboardViewState();
}

class _LynqoDashboardViewState extends State<LynqoDashboardView> {
  var _showPullHint = !DashboardPullToRefreshHint.shownThisSession;

  @override
  void initState() {
    super.initState();
    if (_showPullHint) {
      Future<void>.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() => _showPullHint = false);
        }
      });
    }
  }

  LynqoWidgetTheme _widgetTheme(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    return brightness == Brightness.dark
        ? LynqoWidgetTheme.dark
        : LynqoWidgetTheme.light;
  }

  Future<void> _handleRefresh() async {
    if (_showPullHint) {
      setState(() => _showPullHint = false);
    }
    await widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final widgetTheme = _widgetTheme(context);
    final updatedLabel = DateFormat.jm().format(
      widget.snapshot.updatedAt.toLocal(),
    );
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final padding = wide ? AppSpacing.lg : AppSpacing.md;

    return Theme(
      data: Theme.of(context).copyWith(
        extensions: [widgetTheme],
        scaffoldBackgroundColor: widgetTheme.scaffoldColor,
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          RefreshIndicator(
            onRefresh: _handleRefresh,
            child: ListView(
              padding: EdgeInsets.all(padding),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (widget.awaitingMiFi) ...[
                  Text(
                    'Waiting for the MiFi to come back…',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                LynqoWidgetGrid(
                  snapshot: widget.snapshot,
                  routerStatus: widget.routerStatus,
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
          if (_showPullHint)
            Padding(
              padding: EdgeInsets.only(top: padding),
              child: const DashboardPullToRefreshHint(),
            ),
        ],
      ),
    );
  }
}
