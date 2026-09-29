import 'package:flutter/material.dart';

import '../theme/lynqo_widget_theme.dart';

class LynqoWidgetDivider extends StatelessWidget {
  const LynqoWidgetDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = LynqoWidgetTheme.of(context);
    return Divider(height: 1, thickness: 1, color: theme.dividerColor);
  }
}
