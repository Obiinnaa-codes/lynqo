import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../providers/router_connection_status_provider.dart';

class RouterConnectionTestScreen extends ConsumerWidget {
  const RouterConnectionTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(routerConnectionStatusProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Router connection')),
      body: SafeArea(
        child: statusAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text(
              'Could not load connection status.',
              style: textTheme.bodyLarge,
            ),
          ),
          data: (status) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    status.isFullyConnected ? 'Connected' : 'Not connected',
                    style: textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  _StatusRow(label: 'Router', value: status.host),
                  const SizedBox(height: AppSpacing.lg),
                  _StatusRow(
                    label: 'Authentication',
                    value: status.authenticationLabel,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _StatusRow(label: 'Role', value: status.roleLabel),
                  const SizedBox(height: AppSpacing.lg),
                  _StatusRow(
                    label: 'Connection',
                    value: status.connectionLabel,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            '$label:',
            style: textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(flex: 3, child: Text(value, style: textTheme.titleMedium)),
      ],
    );
  }
}
