import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../domain/lynqo_router_widget_snapshot.dart';
import '../domain/lynqo_widget_builder.dart';
import '../domain/lynqo_widget_registry.dart';
import '../domain/lynqo_widget_type.dart';
import '../sizing/lynqo_widget_dimensions.dart';
import '../sizing/lynqo_widget_size.dart';

class LynqoWidgetGridEntry {
  const LynqoWidgetGridEntry({
    required this.type,
    required this.size,
    this.columnSpan = 1,
  });

  final LynqoWidgetType type;
  final LynqoWidgetSize size;
  final int columnSpan;
}

class LynqoWidgetGrid extends StatelessWidget {
  const LynqoWidgetGrid({
    super.key,
    required this.snapshot,
    required this.entries,
  });

  final LynqoRouterWidgetSnapshot snapshot;
  final List<LynqoWidgetGridEntry> entries;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = LynqoWidgetDimensions.gridColumnsForWidth(
          constraints.maxWidth,
        );
        final gap = AppSpacing.md;
        final totalGap = gap * (columns - 1);
        final columnWidth = (constraints.maxWidth - totalGap) / columns;

        double widthForSpan(int span) {
          if (span >= columns) {
            return constraints.maxWidth;
          }
          return columnWidth * span + gap * (span - 1);
        }

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final entry in entries)
              SizedBox(
                width: widthForSpan(entry.columnSpan),
                height: LynqoWidgetDimensions.minHeight(entry.size),
                child: _buildEntry(entry),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEntry(LynqoWidgetGridEntry entry) {
    final def = LynqoWidgetRegistry.byType(entry.type);
    if (def == null) {
      return const SizedBox.shrink();
    }
    if (!def.supportedSizes.contains(entry.size)) {
      return const SizedBox.shrink();
    }
    return LynqoWidgetBuilder.build(
      type: entry.type,
      size: entry.size,
      snapshot: snapshot,
    );
  }
}
