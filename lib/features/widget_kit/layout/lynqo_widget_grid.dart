import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../domain/lynqo_router_widget_snapshot.dart';
import '../domain/lynqo_widget_builder.dart';
import '../domain/lynqo_widget_registry.dart';
import '../../router/domain/router_status.dart';
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
    this.routerStatus,
  });

  final LynqoRouterWidgetSnapshot snapshot;
  final List<LynqoWidgetGridEntry> entries;
  final RouterStatus? routerStatus;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = LynqoWidgetDimensions.gridColumnsForWidth(
          constraints.maxWidth,
        );
        final gap = AppSpacing.md;
        final rows = _rowsForColumns(entries, columns);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) SizedBox(height: gap),
              _GridRow(
                entries: rows[i],
                columns: columns,
                gap: gap,
                snapshot: snapshot,
                routerStatus: routerStatus,
              ),
            ],
          ],
        );
      },
    );
  }

  static List<List<LynqoWidgetGridEntry>> _rowsForColumns(
    List<LynqoWidgetGridEntry> entries,
    int columns,
  ) {
    final rows = <List<LynqoWidgetGridEntry>>[];
    var row = <LynqoWidgetGridEntry>[];
    var used = 0;
    for (final entry in entries) {
      final span = entry.columnSpan.clamp(1, columns);
      if (used + span > columns && row.isNotEmpty) {
        rows.add(row);
        row = [];
        used = 0;
      }
      row.add(entry);
      used += span;
      if (used >= columns) {
        rows.add(row);
        row = [];
        used = 0;
      }
    }
    if (row.isNotEmpty) {
      rows.add(row);
    }
    return rows;
  }
}

class _GridRow extends StatelessWidget {
  const _GridRow({
    required this.entries,
    required this.columns,
    required this.gap,
    required this.snapshot,
    this.routerStatus,
  });

  final List<LynqoWidgetGridEntry> entries;
  final int columns;
  final double gap;
  final LynqoRouterWidgetSnapshot snapshot;
  final RouterStatus? routerStatus;

  static const _messagesTileHeight = 280.0;
  static const _wifiTileHeight = 200.0;

  @override
  Widget build(BuildContext context) {
    final fitContent = entries.length == 1 &&
        entries.first.size == LynqoWidgetSize.large;
    final rowHeight = fitContent ? null : _rowHeight(entries);

    return SizedBox(
      height: rowHeight,
      child: Row(
        crossAxisAlignment: fitContent
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) SizedBox(width: gap),
            Expanded(
              flex: entries[i].columnSpan.clamp(1, columns),
              child: _buildEntry(entries[i]),
            ),
          ],
        ],
      ),
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
      routerStatus: routerStatus,
    );
  }

  static double _rowHeight(List<LynqoWidgetGridEntry> entries) {
    var maxHeight = 0.0;
    for (final entry in entries) {
      var height = LynqoWidgetDimensions.minHeight(entry.size);
      if (entry.type == LynqoWidgetType.smsMessages) {
        height = _messagesTileHeight;
      } else if (entry.type == LynqoWidgetType.wifiProfile) {
        height = _wifiTileHeight;
      }
      if (height > maxHeight) {
        maxHeight = height;
      }
    }
    return maxHeight;
  }
}
