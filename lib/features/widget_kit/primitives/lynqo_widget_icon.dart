import 'package:flutter/material.dart';

import '../theme/lynqo_widget_theme.dart';

class LynqoWidgetIcon extends StatelessWidget {
  const LynqoWidgetIcon({
    super.key,
    required this.icon,
    this.size = 22,
    this.muted = false,
  });

  final IconData icon;
  final double size;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = LynqoWidgetTheme.of(context);
    return Icon(
      icon,
      size: size,
      color: muted ? theme.secondaryText : theme.primaryText,
    );
  }
}
