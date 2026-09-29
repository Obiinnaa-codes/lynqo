import 'package:flutter/material.dart';

import '../theme/lynqo_widget_theme.dart';

class LynqoWidgetHorizontalTimeline extends StatelessWidget {
  const LynqoWidgetHorizontalTimeline({
    super.key,
    this.isActive = true,
    this.timeLabels = const ['12 PM', '3 PM', '6 PM'],
  });

  final bool isActive;
  final List<String> timeLabels;

  @override
  Widget build(BuildContext context) {
    final theme = LynqoWidgetTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 36,
          child: Row(
            children: [
              _NowCapsule(theme: theme, isActive: isActive),
              const SizedBox(width: 4),
              Expanded(
                child: Row(
                  children: List.generate(
                    8,
                    (_) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: theme.chartBarInactive,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              'NOW',
              style: theme.captionStyle().copyWith(
                color: theme.primaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            for (var i = 0; i < timeLabels.length; i++) ...[
              if (i > 0) const Spacer(),
              Text(timeLabels[i], style: theme.captionStyle(fontSize: 11)),
            ],
          ],
        ),
      ],
    );
  }
}

class _NowCapsule extends StatelessWidget {
  const _NowCapsule({required this.theme, required this.isActive});

  final LynqoWidgetTheme theme;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      decoration: BoxDecoration(
        color: isActive
            ? theme.accentPositive
            : theme.chartBarInactive,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            decoration: BoxDecoration(
              color: theme.accentRing,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(8),
              ),
            ),
          ),
          const Expanded(
            child: Icon(Icons.bolt, size: 18, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
