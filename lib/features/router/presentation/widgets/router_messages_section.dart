import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/router_sms_message.dart';
import '../../domain/router_status.dart';
import '../providers/router_dashboard_provider.dart';
import '../router_status_after_action.dart';

class RouterMessagesSection extends ConsumerWidget {
  const RouterMessagesSection({
    super.key,
    required this.status,
    this.compact = false,
    this.maxVisible = 10,
  });

  final RouterStatus status;
  final bool compact;
  final int maxVisible;

  Future<void> _runAction(
    WidgetRef ref,
    BuildContext context,
    Future<void> Function() action,
    String successMessage,
  ) async {
    try {
      await action();
      await refreshRouterStatusAfterAction(ref);
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
    final theme = Theme.of(context);
    final limit = compact ? maxVisible.clamp(1, 3) : maxVisible;

    if (messages.isEmpty) {
      return Text(
        'No messages on the MiFi.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact)
          Row(
            children: [
              if (unread != null && unread > 0)
                Text(
                  '$unread unread',
                  style: theme.textTheme.labelLarge,
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
        if (compact) ...[
          Row(
            children: [
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
                child: const Text('Clear all'),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const ClampingScrollPhysics(),
              children: [
                for (final message in messages.take(limit))
                  _SmsTile(
                    message: message,
                    compact: true,
                    onDelete: () => _runAction(
                      ref,
                      context,
                      () => ref
                          .read(attWifiDeviceActionsServiceProvider)
                          .deleteSmsMessage(message.id),
                      'Message deleted.',
                    ),
                  ),
              ],
            ),
          ),
        ] else
          ...messages.take(limit).map(
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
  const _SmsTile({
    required this.message,
    required this.onDelete,
    this.compact = false,
  });

  final RouterSmsMessage message;
  final VoidCallback onDelete;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 4 : AppSpacing.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Padding(
          padding: EdgeInsets.all(compact ? AppSpacing.xs : AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.sender,
                      style: compact
                          ? Theme.of(context).textTheme.labelLarge
                          : Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: compact ? 2 : AppSpacing.xs),
                    Text(
                      message.text,
                      maxLines: compact ? 2 : null,
                      overflow: compact ? TextOverflow.ellipsis : null,
                      style: compact
                          ? Theme.of(context).textTheme.bodySmall
                          : null,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                iconSize: compact ? 18 : 20,
                padding: compact ? EdgeInsets.zero : null,
                constraints: compact
                    ? const BoxConstraints(minWidth: 32, minHeight: 32)
                    : null,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
