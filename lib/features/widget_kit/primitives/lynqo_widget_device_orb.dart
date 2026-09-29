import 'package:flutter/material.dart';

import '../theme/lynqo_widget_theme.dart';

class LynqoWidgetDeviceOrb extends StatelessWidget {
  const LynqoWidgetDeviceOrb({
    super.key,
    this.label,
    this.diameter = 40,
  });

  final String? label;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final theme = LynqoWidgetTheme.of(context);
    final filled = label != null && label!.isNotEmpty;

    return Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? theme.primaryText.withValues(alpha: 0.12) : null,
        border: Border.all(
          color: filled ? Colors.transparent : theme.orbStroke,
          width: 1.5,
        ),
      ),
      child: filled
          ? Text(
              label!.substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: theme.primaryText,
                fontWeight: FontWeight.w600,
                fontSize: diameter * 0.35,
              ),
            )
          : null,
    );
  }
}
