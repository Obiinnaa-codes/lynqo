import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/routing/app_routes.dart';
import '../../data/att_wifi_dashboard_service.dart';
import '../../data/att_wifi_device_actions_service.dart';
import '../../domain/router_connected_client.dart';
import '../../domain/router_sms_message.dart';
import '../../domain/router_status.dart';
import '../../domain/router_wifi_band_snapshot.dart';
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
          'Rebooting. Reconnect to the MiFi Wi‑Fi when it comes back online.',
        ),
      ),
    );
    ref.invalidate(routerDashboardProvider);
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
  ref.read(routerAuthGateProvider.notifier).markLoggedOut();
  ref.invalidate(routerDashboardProvider);
  if (context.mounted) {
    context.go(AppRoutes.login);
  }
}

class RouterDashboardScreen extends ConsumerWidget {
  const RouterDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(routerDashboardProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('MiFi dashboard'),
        actions: [
          IconButton(
            tooltip: 'Reboot MiFi',
            onPressed: () => _confirmAndRebootMiFi(context, ref),
            icon: const Icon(Icons.restart_alt),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(routerDashboardProvider),
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
        child: statusAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorState(
            message: error.toString(),
            onRetry: () => ref.invalidate(routerDashboardProvider),
          ),
          data: (status) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(routerDashboardProvider);
              await ref.read(routerDashboardProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _DashboardCard(
                  title: 'Battery',
                  child: _BatterySection(status: status),
                ),
                const SizedBox(height: AppSpacing.md),
                _DashboardCard(
                  title: 'Data plan',
                  child: _DataUsageSection(status: status),
                ),
                const SizedBox(height: AppSpacing.md),
                _DashboardCard(
                  title: 'Wi‑Fi',
                  child: _WifiSection(status: status),
                ),
                const SizedBox(height: AppSpacing.md),
                _DashboardCard(
                  title: 'Cellular',
                  child: _CellularSection(status: status),
                ),
                const SizedBox(height: AppSpacing.md),
                _DashboardCard(
                  title: 'Connected devices',
                  child: _ConnectedDevicesSection(status: status),
                ),
                const SizedBox(height: AppSpacing.md),
                _DashboardCard(
                  title: 'Messages',
                  child: _MessagesSection(status: status),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Updates every ${AttWifiDashboardService.refreshInterval.inSeconds}s',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
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

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class _BatterySection extends StatelessWidget {
  const _BatterySection({required this.status});

  final RouterStatus status;

  @override
  Widget build(BuildContext context) {
    final percent = status.batteryPercent;
    final label = percent == null ? '—' : '$percent%';
    final subtitle = status.batteryStatusLabel ??
        switch (status.isCharging) {
          true => 'Charging',
          false => 'On battery',
          null => null,
        };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Icon(
              _batteryIcon(percent, status.isCharging),
              size: 32,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
        if (percent != null) ...[
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent.clamp(0, 100) / 100,
              minHeight: 8,
              backgroundColor: AppColors.border,
              color: _batteryColor(percent),
            ),
          ),
        ],
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
        if (status.powerState != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Power state: ${status.powerState}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
        if (status.batteryTemperatureC != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Temperature: ${status.batteryTemperatureC}°C',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  static IconData _batteryIcon(int? percent, bool? charging) {
    if (charging == true) {
      return Icons.battery_charging_full;
    }
    if (percent == null) {
      return Icons.battery_unknown;
    }
    if (percent <= 15) {
      return Icons.battery_alert;
    }
    if (percent <= 40) {
      return Icons.battery_3_bar;
    }
    if (percent <= 70) {
      return Icons.battery_5_bar;
    }
    return Icons.battery_full;
  }

  static Color _batteryColor(int percent) {
    if (percent <= 15) {
      return AppColors.error;
    }
    if (percent <= 30) {
      return Colors.orange;
    }
    return AppColors.primary;
  }
}

class _DataUsageSection extends StatelessWidget {
  const _DataUsageSection({required this.status});

  final RouterStatus status;

  @override
  Widget build(BuildContext context) {
    final used = status.dataUsedSummary;
    final limit = status.dataLimitSummary;
    final percent = status.dataUsagePercent;
    final plan = status.planTitle;
    final remaining = status.dataRemainingSummary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (plan != null) ...[
          Text(plan, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
        ],
        if (status.accountType != null) ...[
          Text(
            status.accountType!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        Text(
          _usageHeadline(used, limit, percent),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        if (percent != null && limit != null) ...[
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent.clamp(0, 100) / 100,
              minHeight: 8,
              backgroundColor: AppColors.border,
              color: percent >= 100 ? AppColors.error : AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$percent% of plan used',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
        if (remaining != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Remaining: $remaining',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
        if (status.nextBillingDateLabel != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Next billing date: ${status.nextBillingDateLabel}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
        if (status.dataValidState != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Carrier usage status: ${status.dataValidState}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
        if (status.billingDaysRemaining != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Billing cycle: ${status.billingDaysRemaining} day(s) left',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
        if (used == null && limit == null) ...[
          Text(
            'Usage data not available from the router.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  static String _usageHeadline(String? used, String? limit, int? percent) {
    if (used != null && limit != null) {
      return '$used of $limit';
    }
    if (used != null) {
      return used;
    }
    if (percent != null) {
      return '$percent% used';
    }
    return '—';
  }
}

class _WifiSection extends StatefulWidget {
  const _WifiSection({required this.status});

  final RouterStatus status;

  @override
  State<_WifiSection> createState() => _WifiSectionState();
}

class _WifiSectionState extends State<_WifiSection> {
  static const _pageAnimationDuration = Duration(milliseconds: 280);

  late final PageController _pageController;
  var _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<RouterWifiBandSnapshot> get _bands {
    if (widget.status.wifiBandSnapshots.isNotEmpty) {
      return widget.status.wifiBandSnapshots;
    }
    if (widget.status.wifiSsid == null && widget.status.wifiStatus == null) {
      return const [];
    }
    return [
      RouterWifiBandSnapshot(
        bandLabel: widget.status.wifiBandLabel ?? 'Wi‑Fi',
        ssid: widget.status.wifiSsid,
        status: widget.status.wifiStatus,
      ),
    ];
  }

  void _goToPage(int index) {
    if (index < 0 || index >= _bands.length) {
      return;
    }
    _pageController.animateToPage(
      index,
      duration: _pageAnimationDuration,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bands = _bands;
    if (bands.isEmpty) {
      return Text(
        'Wi‑Fi data not available from the router.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
      );
    }

    final multipleBands = bands.length > 1;
    final theme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (multipleBands)
          Row(
            children: [
              IconButton(
                tooltip: 'Previous band',
                onPressed: _pageIndex > 0 ? () => _goToPage(_pageIndex - 1) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < bands.length; i++) ...[
                      if (i > 0) const SizedBox(width: AppSpacing.sm),
                      GestureDetector(
                        onTap: () => _goToPage(i),
                        child: AnimatedContainer(
                          duration: _pageAnimationDuration,
                          width: _pageIndex == i ? 10 : 8,
                          height: _pageIndex == i ? 10 : 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _pageIndex == i
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Next band',
                onPressed: _pageIndex < bands.length - 1
                    ? () => _goToPage(_pageIndex + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        SizedBox(
          height: multipleBands ? 132 : 112,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _pageIndex = index),
            itemCount: bands.length,
            itemBuilder: (context, index) {
              final band = bands[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    band.bandLabel,
                    style: theme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _MetricRow(label: 'SSID', value: band.ssid),
                  const SizedBox(height: AppSpacing.sm),
                  _MetricRow(label: 'Status', value: band.status),
                ],
              );
            },
          ),
        ),
        if (widget.status.wifiProfile != null) ...[
          const SizedBox(height: AppSpacing.xs),
          _MetricRow(label: 'Profile', value: widget.status.wifiProfile),
        ],
        if (multipleBands) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Swipe or use arrows to view each band',
            textAlign: TextAlign.center,
            style: theme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}

class _CellularSection extends StatelessWidget {
  const _CellularSection({required this.status});

  final RouterStatus status;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MetricRow(label: 'Carrier', value: status.carrierName),
        const SizedBox(height: AppSpacing.sm),
        _MetricRow(label: 'Connection', value: status.connectionState),
        const SizedBox(height: AppSpacing.sm),
        _MetricRow(label: 'Network type', value: status.networkType),
        const SizedBox(height: AppSpacing.sm),
        _MetricRow(
          label: 'Signal',
          value: status.signalStrength == null
              ? null
              : '${status.signalStrength} bars',
        ),
        if (status.signalRsrp != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _MetricRow(label: 'RSRP', value: '${status.signalRsrp} dBm'),
        ],
        if (status.roaming != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _MetricRow(
            label: 'Roaming',
            value: status.roaming! ? 'Yes' : 'No',
          ),
        ],
      ],
    );
  }
}

class _ConnectedDevicesSection extends StatelessWidget {
  const _ConnectedDevicesSection({required this.status});

  final RouterStatus status;

  String _networkSubtitle(RouterConnectedClient client) {
    final parts = <String>[];
    if (client.ssid != null && client.ssid!.isNotEmpty) {
      parts.add(client.ssid!);
    }
    if (client.bandLabel != null) {
      parts.add(client.bandLabel!);
    }
    if (client.networkLabel != null) {
      parts.add(client.networkLabel!);
    }
    return parts.isEmpty ? 'Wi‑Fi' : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final clients = status.wifiConnectedClients;
    final theme = Theme.of(context).textTheme;

    if (status.connectedDeviceCount == null) {
      return Text(
        'Connected device data is not available from the router.',
        style: theme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      );
    }

    if (clients.isEmpty) {
      return Text(
        'No devices connected over Wi‑Fi.',
        style: theme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${clients.length} on Wi‑Fi',
          style: theme.labelLarge?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...clients.map(
          (client) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.devices_other_outlined,
                  size: 22,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.displayName,
                        style: theme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _networkSubtitle(client),
                        style: theme.bodySmall?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      if (client.ipAddress != null &&
                          client.ipAddress!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          client.ipAddress!,
                          style: theme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MessagesSection extends ConsumerWidget {
  const _MessagesSection({required this.status});

  final RouterStatus status;

  Future<void> _confirmDeleteAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete all messages'),
        content: const Text(
          'Remove every SMS stored on the MiFi? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete all'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    await _runMessageAction(
      context,
      ref,
      () => ref.read(attWifiDeviceActionsServiceProvider).deleteAllSmsMessages(),
      'All messages deleted.',
    );
  }

  Future<void> _confirmDeleteOne(
    BuildContext context,
    WidgetRef ref,
    RouterSmsMessage message,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete message'),
        content: Text('Delete message from ${message.sender}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    await _runMessageAction(
      context,
      ref,
      () => ref
          .read(attWifiDeviceActionsServiceProvider)
          .deleteSmsMessage(message.id),
      'Message deleted.',
    );
  }

  Future<void> _runMessageAction(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
    String successMessage,
  ) async {
    try {
      await action();
      ref.invalidate(routerDashboardProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = status.smsMessages;
    final unread = status.unreadSmsCount;

    if (messages.isEmpty) {
      return Text(
        'No messages on the MiFi.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (unread != null && unread > 0)
              Expanded(
                child: Text(
                  '$unread unread',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              )
            else
              const Spacer(),
            TextButton(
              onPressed: () => _confirmDeleteAll(context, ref),
              child: const Text('Delete all'),
            ),
          ],
        ),
        if (unread != null && unread > 0) const SizedBox(height: AppSpacing.sm),
        ...messages.take(10).map(
          (message) => _SmsTile(
            message: message,
            onDelete: () => _confirmDeleteOne(context, ref, message),
          ),
        ),
        if (messages.length > 10) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${messages.length - 10} more on the router',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _SmsTile extends StatelessWidget {
  const _SmsTile({required this.message, required this.onDelete});

  final RouterSmsMessage message;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: message.read ? null : AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.sender,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight:
                            message.read ? FontWeight.normal : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(message.text, style: textTheme.bodyMedium),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Delete message',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value ?? '—',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
