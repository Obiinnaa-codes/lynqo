import 'package:flutter/material.dart';

import '../domain/models/widget_view_models.dart';
import '../primitives/lynqo_widget_header.dart';
import '../primitives/lynqo_widget_icon.dart';
import '../primitives/lynqo_widget_ring.dart';
import '../primitives/lynqo_widget_segmented_gauge.dart';
import '../primitives/lynqo_widget_surface.dart';
import '../primitives/lynqo_widget_typography.dart';
import '../sizing/lynqo_widget_dimensions.dart';
import '../sizing/lynqo_widget_size.dart';
import '../theme/lynqo_widget_theme.dart';

class SignalWidget extends StatelessWidget {
  const SignalWidget({
    super.key,
    required this.size,
    required this.data,
  });

  final LynqoWidgetSize size;
  final SignalWidgetData data;

  @override
  Widget build(BuildContext context) {
    final theme = LynqoWidgetTheme.of(context);
    final progress = data.progress ?? 0;
    final percentLabel =
        data.strengthPercent == null ? '—' : '${data.strengthPercent}%';

    return LynqoWidgetSurface(
      size: size,
      child: switch (size) {
        LynqoWidgetSize.small => _SmallSignal(
          theme: theme,
          progress: progress,
          percentLabel: percentLabel,
        ),
        LynqoWidgetSize.medium => _MediumSignal(data: data, progress: progress),
        LynqoWidgetSize.large => _LargeSignal(data: data, progress: progress),
      },
    );
  }
}

class _SmallSignal extends StatelessWidget {
  const _SmallSignal({
    required this.theme,
    required this.progress,
    required this.percentLabel,
  });

  final LynqoWidgetTheme theme;
  final double progress;
  final String percentLabel;

  @override
  Widget build(BuildContext context) {
    if (theme.isDark) {
      final ring = LynqoWidgetDimensions.ringDiameter(LynqoWidgetSize.small);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LynqoWidgetRing(
            progress: progress,
            diameter: ring,
            center: LynqoWidgetIcon(
              icon: Icons.signal_cellular_alt,
              size: 20,
            ),
          ),
          const Spacer(),
          LynqoWidgetPrimaryValue(
            text: percentLabel,
            size: LynqoWidgetSize.small,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LynqoWidgetHeader(
          category: 'Signal',
          headline: percentLabel,
          size: LynqoWidgetSize.small,
        ),
        const Spacer(),
        Align(
          alignment: Alignment.bottomLeft,
          child: LynqoWidgetSegmentedGauge(
            progress: progress,
            diameter: 72,
            center: LynqoWidgetIcon(
              icon: Icons.signal_cellular_alt,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

class _MediumSignal extends StatelessWidget {
  const _MediumSignal({required this.data, required this.progress});

  final SignalWidgetData data;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = LynqoWidgetTheme.of(context);
    final percentLabel =
        data.strengthPercent == null ? '—' : '${data.strengthPercent}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LynqoWidgetHeader(
          category: 'Signal',
          headline: percentLabel,
          description: data.qualityLabel,
          size: LynqoWidgetSize.medium,
        ),
        const Spacer(),
        Row(
          children: [
            if (theme.isDark)
              LynqoWidgetRing(
                progress: progress,
                diameter: 52,
                center: LynqoWidgetIcon(
                  icon: Icons.signal_cellular_alt,
                  size: 18,
                ),
              )
            else
              LynqoWidgetSegmentedGauge(
                progress: progress,
                diameter: 64,
                center: LynqoWidgetIcon(
                  icon: Icons.signal_cellular_alt,
                  size: 18,
                ),
              ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.networkType != null)
                  LynqoWidgetSecondaryText(text: data.networkType!),
                if (data.carrierName != null)
                  LynqoWidgetCaption(text: data.carrierName!),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _LargeSignal extends StatelessWidget {
  const _LargeSignal({required this.data, required this.progress});

  final SignalWidgetData data;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final percentLabel =
        data.strengthPercent == null ? '—' : '${data.strengthPercent}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LynqoWidgetHeader(
          category: 'Signal',
          headline: percentLabel,
          description: data.qualityLabel,
          size: LynqoWidgetSize.large,
        ),
        const Spacer(),
        LynqoWidgetSegmentedGauge(
          progress: progress,
          diameter: 88,
          center: LynqoWidgetIcon(icon: Icons.signal_cellular_alt, size: 24),
        ),
        const SizedBox(height: 12),
        if (data.networkType != null)
          LynqoWidgetSecondaryText(text: data.networkType!),
        if (data.carrierName != null)
          LynqoWidgetCaption(text: data.carrierName!),
      ],
    );
  }
}
