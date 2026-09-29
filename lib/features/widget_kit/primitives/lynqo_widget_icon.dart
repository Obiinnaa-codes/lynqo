import 'package:flutter/material.dart';

import '../theme/lynqo_widget_theme.dart';

class LynqoWidgetIcon extends StatelessWidget {
  const LynqoWidgetIcon({
    super.key,
    required this.icon,
    this.size = 22,
  });

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = LynqoWidgetTheme.of(context);
    return Icon(icon, size: size, color: theme.primaryText);
  }
}
