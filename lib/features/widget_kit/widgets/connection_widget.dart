import 'package:flutter/material.dart';

import '../domain/models/widget_view_models.dart';
import '../primitives/lynqo_widget_header.dart';
import '../primitives/lynqo_widget_horizontal_timeline.dart';
import '../primitives/lynqo_widget_surface.dart';
import '../primitives/lynqo_widget_typography.dart';
import '../sizing/lynqo_widget_size.dart';

bool _isConnected(ConnectionWidgetData data) {
  final headline = data.headline?.toLowerCase();
  if (headline == 'connected') {
    return true;
  }
  final status = data.statusLabel?.toLowerCase();
  return status == 'online' || status == 'connected';
}

class ConnectionWidget extends StatelessWidget {
  const ConnectionWidget({
    super.key,
    required this.size,
    required this.data,
  });

  final LynqoWidgetSize size;
  final ConnectionWidgetData data;

  @override
  Widget build(BuildContext context) {
    final headline = data.headline ?? '—';

    return LynqoWidgetSurface(
      size: size,
      child: switch (size) {
        LynqoWidgetSize.small => LynqoWidgetHeader(
          category: 'Connection',
          headline: headline,
          size: LynqoWidgetSize.small,
        ),
        LynqoWidgetSize.medium => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LynqoWidgetHeader(
              category: 'Connection',
              headline: headline,
              description: data.hostLabel,
              size: LynqoWidgetSize.medium,
            ),
            if (data.statusLabel != null) ...[
              const SizedBox(height: 8),
              LynqoWidgetSecondaryText(text: data.statusLabel!),
            ],
          ],
        ),
        LynqoWidgetSize.large => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LynqoWidgetHeader(
              category: 'Connection',
              headline: headline,
              description: data.wifiSsid ?? data.hostLabel,
              size: LynqoWidgetSize.large,
            ),
            const Spacer(),
            LynqoWidgetHorizontalTimeline(
              isActive: _isConnected(data),
            ),
          ],
        ),
      },
    );
  }
}
