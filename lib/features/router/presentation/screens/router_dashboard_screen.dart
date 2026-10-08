import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../widget_kit/data/router_widget_mappers.dart';
import '../../../widget_kit/data/lynqo_home_widget.dart';
import '../../../widget_kit/presentation/lynqo_dashboard_view.dart';
import '../../../widget_kit/presentation/lynqo_home_widget_reboot_link.dart';
import '../../../widget_kit/presentation/lynqo_home_widget_sync_provider.dart';
import '../../../widget_kit/presentation/router_throughput_provider.dart';
import '../../domain/router_status.dart';
import '../providers/router_auth_gate_provider.dart';
import '../providers/router_dashboard_provider.dart';
import '../providers/router_providers.dart';

Future<void> _confirmAndRebootMiFi(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Reboot MiFi'),
      content: const Text(
        'Internet connectivity will be lost while the mobile router reboots. '
        'Are you sure you want to continue?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Reboot'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) {
    return;
  }

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => const PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: AppSpacing.md),
            Expanded(child: Text('Sending reboot request…')),
          ],
        ),
      ),
    ),
  );

  try {
    await ref.read(attWifiDeviceActionsServiceProvider).rebootRouter();
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Rebooting. The dashboard will refresh when the MiFi is back.',
        ),
      ),
    );
    ref.read(dashboardAwaitingMiFiProvider.notifier).setAwaiting(true);
    ref.read(attWifiDashboardServiceProvider).pauseForReboot();
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString())),
    );
  }
}

Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Log out'),
      content: const Text(
        'You will need to sign in again to manage your MiFi.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Log out'),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    await _logout(context, ref);
  }
}

Future<void> _logout(BuildContext context, WidgetRef ref) async {
  await ref.read(routerAuthServiceProvider).logout();
  await LynqoHomeWidget.clearSnapshot();
  ref.read(dashboardAwaitingMiFiProvider.notifier).setAwaiting(false);
  ref.read(lastDashboardStatusProvider.notifier).clear();
  ref.read(routerAuthGateProvider.notifier).markLoggedOut();
  ref.invalidate(routerDashboardProvider);
  if (context.mounted) {
    context.go(AppRoutes.login);
  }
}

class RouterDashboardScreen extends ConsumerStatefulWidget {
  const RouterDashboardScreen({super.key});

  @override
  ConsumerState<RouterDashboardScreen> createState() =>
      _RouterDashboardScreenState();
}

class _RouterDashboardScreenState extends ConsumerState<RouterDashboardScreen>
    with WidgetsBindingObserver {
  Object? _fetchError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeRebootFromWidget();
      unawaited(_refreshDashboard());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }
    unawaited(_refreshDashboard());
  }

  Future<void> _refreshDashboard() async {
    try {
      final status = await ref
          .read(attWifiDashboardServiceProvider)
          .fetchStatus();
      ref.read(lastDashboardStatusProvider.notifier).setStatus(status);
      ref.read(dashboardAwaitingMiFiProvider.notifier).setAwaiting(false);
      if (mounted) {
        setState(() => _fetchError = null);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _fetchError = error);
      if (ref.read(lastDashboardStatusProvider) != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  void _maybeRebootFromWidget() {
    final pending = ref.read(pendingHomeWidgetRebootProvider);
    if (!pending || !mounted) {
      return;
    }
    ref.read(pendingHomeWidgetRebootProvider.notifier).setPending(false);
    _confirmAndRebootMiFi(context, ref);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(pendingHomeWidgetRebootProvider, (previous, next) {
      if (next) {
        _maybeRebootFromWidget();
      }
    });
    ref.listen(routerDashboardProvider, (previous, next) {
      if (next.hasValue) {
        ref.read(dashboardAwaitingMiFiProvider.notifier).setAwaiting(false);
      }
    });
    ref.watch(lynqoHomeWidgetSyncProvider);
    final statusAsync = ref.watch(routerDashboardProvider);
    final lastStatus = ref.watch(lastDashboardStatusProvider);
    final awaitingMiFi = ref.watch(dashboardAwaitingMiFiProvider);
    final routerHost = ref.watch(routerConfigProvider).host;
    final status = lastStatus ??
        (statusAsync.hasValue ? statusAsync.requireValue : null);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('MiFi dashboard'),
        actions: [
          IconButton(
            tooltip: 'Manage MiFi',
            onPressed: () => context.push(AppRoutes.routerManage),
            icon: const Icon(Icons.settings_outlined),
          ),
          IconButton(
            tooltip: 'Reboot MiFi',
            onPressed: () => _confirmAndRebootMiFi(context, ref),
            icon: const Icon(Icons.restart_alt),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => unawaited(_refreshDashboard()),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: () => _confirmLogout(context, ref),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: status != null
            ? _dashboardFromStatus(
                status,
                routerHost: routerHost,
                awaitingMiFi: awaitingMiFi,
              )
            : _fetchError != null
            ? _ErrorState(
                message: _fetchError.toString(),
                onRetry: () => unawaited(_refreshDashboard()),
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _dashboardFromStatus(
    RouterStatus status, {
    required String routerHost,
    required bool awaitingMiFi,
  }) {
    final networkSpeed = ref.watch(routerNetworkSpeedProvider);
    final snapshot = RouterWidgetMappers.fromRouterStatus(
      status,
      routerHost: routerHost,
      networkSpeed: networkSpeed,
    );
    return LynqoDashboardView(
      snapshot: snapshot,
      awaitingMiFi: awaitingMiFi,
      onRefresh: _refreshDashboard,
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Could not load dashboard',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
