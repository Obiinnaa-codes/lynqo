import 'package:flutter/material.dart';

import '../domain/models/widget_view_models.dart';
import '../primitives/lynqo_widget_header.dart';
import '../primitives/lynqo_widget_mini_chart.dart';
import '../primitives/lynqo_widget_progress.dart';
import '../primitives/lynqo_widget_surface.dart';
import '../primitives/lynqo_widget_typography.dart';
import '../sizing/lynqo_widget_size.dart';

class DataUsageWidget extends StatelessWidget {
  const DataUsageWidget({
    super.key,
    required this.size,
    required this.data,
  });

  final LynqoWidgetSize size;
  final DataUsageWidgetData data;

  @override
  Widget build(BuildContext context) {
    final used = data.usedSummary ?? '—';

    return LynqoWidgetSurface(
      size: size,
      child: switch (size) {
        LynqoWidgetSize.small => LynqoWidgetPrimaryValue(
          text: used,
          size: LynqoWidgetSize.small,
        ),
        LynqoWidgetSize.medium => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LynqoWidgetHeader(
              category: 'Data usage',
              headline: used,
              description: data.comparisonCaption,
              size: LynqoWidgetSize.medium,
            ),
            const Spacer(),
            if (data.remainingSummary != null)
              LynqoWidgetSecondaryText(text: data.remainingSummary!),
            if (data.progress != null) ...[
              const SizedBox(height: 12),
              LynqoWidgetProgress(progress: data.progress!),
            ],
            if (data.historyValues != null) ...[
              const SizedBox(height: 8),
              LynqoWidgetMiniChart(
                values: data.historyValues!,
                startLabel: data.chartStartLabel,
                endLabel: data.chartEndLabel,
                height: 48,
              ),
            ],
          ],
        ),
        LynqoWidgetSize.large => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LynqoWidgetHeader(
              category: 'Data usage',
              headline: used,
              description: data.limitSummary != null
                  ? 'of ${data.limitSummary}'
                  : data.remainingSummary,
              size: LynqoWidgetSize.large,
            ),
            const SizedBox(height: 8),
            if (data.remainingSummary != null)
              LynqoWidgetSecondaryText(text: data.remainingSummary!),
            if (data.billingResetLabel != null)
              LynqoWidgetCaption(text: data.billingResetLabel!),
            const Spacer(),
            if (data.progress != null)
              LynqoWidgetProgress(progress: data.progress!),
            if (data.historyValues != null) ...[
              const SizedBox(height: 16),
              LynqoWidgetMiniChart(
                values: data.historyValues!,
                startLabel: data.chartStartLabel,
                endLabel: data.chartEndLabel,
                height: 88,
              ),
            ],
          ],
        ),
      },
    );
  }
}
