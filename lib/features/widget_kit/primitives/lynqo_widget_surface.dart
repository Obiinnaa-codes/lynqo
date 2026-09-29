import 'package:flutter/material.dart';

import '../sizing/lynqo_widget_dimensions.dart';
import '../sizing/lynqo_widget_size.dart';
import '../theme/lynqo_widget_theme.dart';

class LynqoWidgetSurface extends StatelessWidget {
  const LynqoWidgetSurface({
    super.key,
    required this.size,
    required this.child,
    this.width,
    this.height,
  });

  final LynqoWidgetSize size;
  final Widget child;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final theme = LynqoWidgetTheme.of(context);
    final padding = LynqoWidgetDimensions.internalPadding(size);
    final minH = LynqoWidgetDimensions.minHeight(size);
    // Fixed height so inner [Column] + [Spacer] layouts are valid inside [Wrap].
    final resolvedHeight = height ?? minH;

    return Container(
      width: width,
      height: resolvedHeight,
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(theme.surfaceRadius),
        boxShadow: theme.surfaceShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: SizedBox(
          height: resolvedHeight - padding * 2,
          width: double.infinity,
          child: child,
        ),
      ),
    );
  }
}
