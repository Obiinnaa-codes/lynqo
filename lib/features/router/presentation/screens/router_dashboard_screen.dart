import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../data/att_wifi_dashboard_service.dart';
import '../../domain/router_status.dart';
import '../providers/router_dashboard_provider.dart';

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
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(routerDashboardProvider),
            icon: const Icon(Icons.refresh),
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
                  title: 'Network',
                  child: _NetworkSection(status: status),
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

class _WifiSection extends StatelessWidget {
  const _WifiSection({required this.status});

  final RouterStatus status;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MetricRow(label: 'SSID', value: status.wifiSsid),
        const SizedBox(height: AppSpacing.sm),
        _MetricRow(label: 'Status', value: status.wifiStatus),
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

class _NetworkSection extends StatelessWidget {
  const _NetworkSection({required this.status});

  final RouterStatus status;

  @override
  Widget build(BuildContext context) {
    final devices = status.connectedDeviceCount;
    return _MetricRow(
      label: 'Connected devices',
      value: devices == null ? null : devices.toString(),
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
