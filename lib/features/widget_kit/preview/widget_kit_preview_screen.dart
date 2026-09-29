import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../domain/lynqo_widget_builder.dart';
import '../domain/lynqo_widget_registry.dart';
import '../domain/lynqo_widget_type.dart';
import 'lynqo_widget_mock_data.dart';
import '../layout/lynqo_widget_grid.dart';
import '../sizing/lynqo_widget_size.dart';
import '../theme/lynqo_widget_theme.dart';

class WidgetKitPreviewScreen extends StatefulWidget {
  const WidgetKitPreviewScreen({super.key});

  @override
  State<WidgetKitPreviewScreen> createState() => _WidgetKitPreviewScreenState();
}

class _WidgetKitPreviewScreenState extends State<WidgetKitPreviewScreen> {
  bool _useDarkWidgets = false;

  @override
  Widget build(BuildContext context) {
    final widgetTheme =
        _useDarkWidgets ? LynqoWidgetTheme.dark : LynqoWidgetTheme.light;

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
                'Mock data only — compare to reference images in docs/widget_kit/reference/',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
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
                      snapshot: LynqoWidgetMockData.snapshot,
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
                snapshot: LynqoWidgetMockData.snapshot,
              ),
              const SizedBox(height: AppSpacing.xxl),
              const _SectionTitle('Sample grid'),
              const SizedBox(height: AppSpacing.sm),
              LynqoWidgetGrid(
                snapshot: LynqoWidgetMockData.snapshot,
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
