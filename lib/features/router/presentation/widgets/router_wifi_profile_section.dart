import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../domain/router_status.dart';
import '../providers/router_dashboard_provider.dart';
import '../router_status_after_action.dart';
import 'router_wifi_bands.dart';

class RouterWifiProfileSection extends ConsumerWidget {
  const RouterWifiProfileSection({
    super.key,
    required this.status,
    this.compact = false,
    this.maxContentWidth,
  });

  final RouterStatus status;
  final bool compact;
  final double? maxContentWidth;

  Future<void> _setProfile(
    WidgetRef ref,
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      await refreshRouterStatusAfterAction(ref);
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
    final bands = wifiBandsFromStatus(status);
    final actions = ref.read(attWifiDeviceActionsServiceProvider);
    final theme = Theme.of(context);
    final contentWidth = maxContentWidth;
    final stackButtons =
        compact && (contentWidth == null || contentWidth < 200);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (bands.isEmpty)
          Text(
            'Wi‑Fi data not available.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          for (final band in bands)
            Padding(
              padding: EdgeInsets.only(bottom: compact ? 4 : AppSpacing.sm),
              child: Text(
                '${band.bandLabel} · ${band.ssid ?? '—'} · ${band.status ?? '—'}',
                style: compact
                    ? theme.textTheme.bodySmall
                    : theme.textTheme.bodyMedium,
                maxLines: compact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        SizedBox(height: compact ? AppSpacing.xs : AppSpacing.md),
        if (stackButtons)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _profileButton(
                ref: ref,
                context: context,
                label: '2.4 GHz',
                onAction: actions.setWifiProfile24Ghz,
              ),
              const SizedBox(height: AppSpacing.xs),
              _profileButton(
                ref: ref,
                context: context,
                label: '5 GHz',
                onAction: actions.setWifiProfile5Ghz,
              ),
            ],
          )
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _profileButton(
                ref: ref,
                context: context,
                label: compact ? '2.4 GHz' : 'Use 2.4 GHz profile',
                onAction: actions.setWifiProfile24Ghz,
              ),
              _profileButton(
                ref: ref,
                context: context,
                label: compact ? '5 GHz' : 'Use 5 GHz profile',
                onAction: actions.setWifiProfile5Ghz,
              ),
            ],
          ),
      ],
    );
  }

  Widget _profileButton({
    required WidgetRef ref,
    required BuildContext context,
    required String label,
    required Future<void> Function() onAction,
  }) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        visualDensity: compact ? VisualDensity.compact : null,
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 8)
            : null,
        tapTargetSize: compact ? MaterialTapTargetSize.shrinkWrap : null,
      ),
      onPressed: () => _setProfile(ref, context, onAction),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}
