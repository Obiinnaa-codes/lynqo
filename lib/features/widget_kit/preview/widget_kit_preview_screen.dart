import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_spacing.dart';
import '../../router/presentation/providers/router_dashboard_provider.dart';
import '../../router/presentation/providers/router_providers.dart';
import '../data/router_widget_mappers.dart';
import '../domain/lynqo_router_widget_snapshot.dart';
import '../domain/lynqo_widget_builder.dart';
import '../domain/lynqo_widget_registry.dart';
import '../domain/lynqo_widget_type.dart';
import '../layout/lynqo_widget_grid.dart';
import '../presentation/router_throughput_provider.dart';
import '../sizing/lynqo_widget_size.dart';
import '../theme/lynqo_widget_theme.dart';
import '../widgets/lynqo_large_devices_home_widget.dart';
import '../widgets/lynqo_medium_mifi_widget.dart';

class WidgetKitPreviewScreen extends ConsumerStatefulWidget {
  const WidgetKitPreviewScreen({super.key});

  @override
  ConsumerState<WidgetKitPreviewScreen> createState() =>
      _WidgetKitPreviewScreenState();
}

class _WidgetKitPreviewScreenState extends ConsumerState<WidgetKitPreviewScreen> {
  bool _useDarkWidgets = false;

  LynqoRouterWidgetSnapshot? _liveSnapshot(WidgetRef ref) {
    final status = ref.watch(routerDashboardProvider).whenOrNull(
          data: (value) => value,
        );
    if (status == null) {
      return null;
    }
    final routerHost = ref.watch(routerConfigProvider).host;
    final networkSpeed = ref.watch(routerNetworkSpeedProvider);
    return RouterWidgetMappers.fromRouterStatus(
      status,
      routerHost: routerHost,
      networkSpeed: networkSpeed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final widgetTheme =
        _useDarkWidgets ? LynqoWidgetTheme.dark : LynqoWidgetTheme.light;
    final liveSnapshot = _liveSnapshot(ref);
    final unsynced = LynqoRouterWidgetSnapshot.unsynced();

    return Theme(
      data: Theme.of(context).copyWith(
        extensions: [widgetTheme],
        scaffoldBackgroundColor: widgetTheme.scaffoldColor,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Widget Kit Preview'),
          actions: [
            IconButton(
              tooltip: _useDarkWidgets ? 'Light widgets' : 'Dark widgets',
              onPressed: () => setState(() => _useDarkWidgets = !_useDarkWidgets),
              icon: Icon(_useDarkWidgets ? Icons.light_mode : Icons.dark_mode),
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                liveSnapshot == null
                    ? 'No live router data — open the dashboard while on the MiFi network. '
                        'Compare layout to docs/widget_kit/reference/.'
                    : 'Live data from the dashboard (same payload as the iOS home widget).',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              const _SectionTitle('iOS Medium (home)'),
              const SizedBox(height: AppSpacing.sm),
              if (liveSnapshot != null) ...[
                const Text('Live', style: TextStyle(fontSize: 12)),
                const SizedBox(height: AppSpacing.xs),
                LynqoMediumMiFiWidget(snapshot: liveSnapshot),
                const SizedBox(height: AppSpacing.md),
              ],
              const Text('Unsynced', style: TextStyle(fontSize: 12)),
              const SizedBox(height: AppSpacing.xs),
              LynqoMediumMiFiWidget(snapshot: unsynced),
              const SizedBox(height: AppSpacing.xxl),
              const _SectionTitle('iOS Large (devices only)'),
              const SizedBox(height: AppSpacing.sm),
              if (liveSnapshot != null) ...[
                const Text('Live', style: TextStyle(fontSize: 12)),
                const SizedBox(height: AppSpacing.xs),
                LynqoLargeDevicesHomeWidget(snapshot: liveSnapshot),
                const SizedBox(height: AppSpacing.md),
              ],
              const Text('Unsynced', style: TextStyle(fontSize: 12)),
              const SizedBox(height: AppSpacing.xs),
              LynqoLargeDevicesHomeWidget(snapshot: unsynced),
              if (liveSnapshot != null) ...[
                const SizedBox(height: AppSpacing.xxl),
                for (final def in LynqoWidgetRegistry.all) ...[
                  if (def.type != LynqoWidgetType.routerOverview) ...[
                    _SectionTitle(def.displayName),
                    const SizedBox(height: AppSpacing.sm),
                    for (final size in def.supportedSizes) ...[
                      _SizeLabel(size),
                      const SizedBox(height: AppSpacing.xs),
                      LynqoWidgetBuilder.build(
                        type: def.type,
                        size: size,
                        snapshot: liveSnapshot,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ],
                const _SectionTitle('Router overview'),
                const SizedBox(height: AppSpacing.sm),
                const _SizeLabel(LynqoWidgetSize.large),
                LynqoWidgetBuilder.build(
                  type: LynqoWidgetType.routerOverview,
                  size: LynqoWidgetSize.large,
                  snapshot: liveSnapshot,
                ),
                const SizedBox(height: AppSpacing.xxl),
                const _SectionTitle('Sample grid'),
                const SizedBox(height: AppSpacing.sm),
                LynqoWidgetGrid(
                  snapshot: liveSnapshot,
                  entries: const [
                    LynqoWidgetGridEntry(
                      type: LynqoWidgetType.battery,
                      size: LynqoWidgetSize.small,
                    ),
                    LynqoWidgetGridEntry(
                      type: LynqoWidgetType.dataUsage,
                      size: LynqoWidgetSize.medium,
                      columnSpan: 2,
                    ),
                    LynqoWidgetGridEntry(
                      type: LynqoWidgetType.signal,
                      size: LynqoWidgetSize.small,
                    ),
                    LynqoWidgetGridEntry(
                      type: LynqoWidgetType.connection,
                      size: LynqoWidgetSize.small,
                    ),
                    LynqoWidgetGridEntry(
                      type: LynqoWidgetType.routerOverview,
                      size: LynqoWidgetSize.large,
                      columnSpan: 2,
                    ),
                  ],
                ),
              ],
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
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        letterSpacing: 0.8,
      ),
    );
  }
}

class _SizeLabel extends StatelessWidget {
  const _SizeLabel(this.size);

  final LynqoWidgetSize size;

  @override
  Widget build(BuildContext context) {
    return Text(
      size.name,
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}
