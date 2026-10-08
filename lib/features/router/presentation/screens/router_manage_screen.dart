import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../providers/router_dashboard_provider.dart';
import '../widgets/router_messages_section.dart';
import '../widgets/router_wifi_profile_section.dart';

class RouterManageScreen extends ConsumerWidget {
  const RouterManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(routerDashboardProvider);
    final status = ref.watch(lastDashboardStatusProvider) ??
        (statusAsync.hasValue ? statusAsync.requireValue : null);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage MiFi')),
      body: SafeArea(
        child: status != null
            ? ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  const _SectionTitle('Wi‑Fi'),
                  const SizedBox(height: AppSpacing.sm),
                  RouterWifiProfileSection(status: status),
                  const SizedBox(height: AppSpacing.xl),
                  const _SectionTitle('Messages'),
                  const SizedBox(height: AppSpacing.sm),
                  RouterMessagesSection(status: status),
                ],
              )
            : statusAsync.hasError
            ? Center(child: Text(statusAsync.error.toString()))
            : const Center(child: CircularProgressIndicator()),
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
