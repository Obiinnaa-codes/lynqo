import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../data/att_wifi_device_actions_service.dart';
import '../../domain/router_sms_message.dart';
import '../../domain/router_status.dart';
import '../../domain/router_wifi_band_snapshot.dart';
import '../providers/router_dashboard_provider.dart';
import '../providers/router_providers.dart';

class RouterManageScreen extends ConsumerWidget {
  const RouterManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(routerDashboardProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage MiFi')),
      body: SafeArea(
        child: statusAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(error.toString())),
          data: (status) => ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const _SectionTitle('Wi‑Fi'),
              const SizedBox(height: AppSpacing.sm),
              _WifiSection(status: status, ref: ref),
              const SizedBox(height: AppSpacing.xl),
              const _SectionTitle('Messages'),
              const SizedBox(height: AppSpacing.sm),
              _MessagesSection(status: status),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _WifiSection extends StatelessWidget {
  const _WifiSection({required this.status, required this.ref});

  final RouterStatus status;
  final WidgetRef ref;

  List<RouterWifiBandSnapshot> get _bands {
    if (status.wifiBandSnapshots.isNotEmpty) {
      return status.wifiBandSnapshots;
    }
    if (status.wifiSsid == null) {
      return const [];
    }
    return [
      RouterWifiBandSnapshot(
        bandLabel: status.wifiBandLabel ?? 'Wi‑Fi',
        ssid: status.wifiSsid,
        status: status.wifiStatus,
      ),
    ];
  }

  Future<void> _setProfile(Future<void> Function() action) async {
    try {
      await action();
      ref.invalidate(routerDashboardProvider);
    } catch (error) {
      if (ref.context.mounted) {
        ScaffoldMessenger.of(ref.context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bands = _bands;
    final actions = ref.read(attWifiDeviceActionsServiceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (bands.isEmpty)
          Text(
            'Wi‑Fi data not available.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          )
        else
          for (final band in bands)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                '${band.bandLabel ?? 'Band'} · ${band.ssid ?? '—'} · ${band.status ?? '—'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            OutlinedButton(
              onPressed: () => _setProfile(actions.setWifiProfile24Ghz),
              child: const Text('Use 2.4 GHz profile'),
            ),
            OutlinedButton(
              onPressed: () => _setProfile(actions.setWifiProfile5Ghz),
              child: const Text('Use 5 GHz profile'),
            ),
          ],
        ),
      ],
    );
  }
}

class _MessagesSection extends ConsumerWidget {
  const _MessagesSection({required this.status});

  final RouterStatus status;

  Future<void> _runAction(
    WidgetRef ref,
    BuildContext context,
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
              Text(
                '$unread unread',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            const Spacer(),
            TextButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete all messages'),
                    content: const Text(
                      'Remove every SMS stored on the MiFi?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete all'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  await _runAction(
                    ref,
                    context,
                    () => ref
                        .read(attWifiDeviceActionsServiceProvider)
                        .deleteAllSmsMessages(),
                    'All messages deleted.',
                  );
                }
              },
              child: const Text('Delete all'),
            ),
          ],
        ),
        ...messages.take(10).map(
          (message) => _SmsTile(
            message: message,
            onDelete: () => _runAction(
              ref,
              context,
              () => ref
                  .read(attWifiDeviceActionsServiceProvider)
                  .deleteSmsMessage(message.id),
              'Message deleted.',
            ),
          ),
        ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
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
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(message.text),
                  ],
                ),
              ),
              IconButton(
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
