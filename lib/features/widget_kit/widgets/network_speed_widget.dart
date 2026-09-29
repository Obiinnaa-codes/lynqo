import 'package:flutter/material.dart';

import '../domain/models/widget_view_models.dart';
import '../primitives/lynqo_widget_header.dart';
import '../primitives/lynqo_widget_metric.dart';
import '../primitives/lynqo_widget_surface.dart';
import '../sizing/lynqo_widget_size.dart';

class NetworkSpeedWidget extends StatelessWidget {
  const NetworkSpeedWidget({
    super.key,
    required this.size,
    required this.data,
  });

  final LynqoWidgetSize size;
  final NetworkSpeedWidgetData data;

  @override
  Widget build(BuildContext context) {
    return LynqoWidgetSurface(
      size: size,
      child: switch (size) {
        LynqoWidgetSize.small => LynqoWidgetMetric(
          label: 'Download',
          value: data.downloadMbps ?? '—',
          size: LynqoWidgetSize.small,
        ),
        LynqoWidgetSize.medium => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LynqoWidgetHeader(
              category: 'Network speed',
              headline: 'Live',
              size: LynqoWidgetSize.medium,
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: LynqoWidgetMetric(
                    label: 'Download',
                    value: data.downloadMbps ?? '—',
                    size: LynqoWidgetSize.small,
                  ),
                ),
                Expanded(
                  child: LynqoWidgetMetric(
                    label: 'Upload',
                    value: data.uploadMbps ?? '—',
                    size: LynqoWidgetSize.small,
                  ),
                ),
              ],
            ),
          ],
        ),
        LynqoWidgetSize.large => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LynqoWidgetHeader(
              category: 'Network speed',
              headline: 'Live',
              size: LynqoWidgetSize.medium,
            ),
            const Spacer(),
            LynqoWidgetMetric(
              label: 'Download',
              value: data.downloadMbps ?? '—',
              size: LynqoWidgetSize.medium,
            ),
            const SizedBox(height: 16),
            LynqoWidgetMetric(
              label: 'Upload',
              value: data.uploadMbps ?? '—',
              size: LynqoWidgetSize.medium,
            ),
          ],
        ),
      },
    );
  }
}
