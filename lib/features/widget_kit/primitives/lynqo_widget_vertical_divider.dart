import 'package:flutter/material.dart';

import '../theme/lynqo_widget_theme.dart';

class LynqoWidgetVerticalDivider extends StatelessWidget {
  const LynqoWidgetVerticalDivider({
    super.key,
    this.height = 72,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = LynqoWidgetTheme.of(context);
    return SizedBox(
      height: height,
      child: Center(
        child: Container(
          width: 1,
          height: height,
          color: theme.dividerColor.withValues(alpha: theme.isDark ? 0.4 : 0.9),
        ),
      ),
    );
  }
}
