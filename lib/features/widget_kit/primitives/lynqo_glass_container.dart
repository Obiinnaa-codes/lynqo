import 'package:flutter/material.dart';

import '../sizing/lynqo_widget_dimensions.dart';
import '../theme/lynqo_widget_theme.dart';

/// Opaque widget surface for medium home layout (iOS Batteries-style card).
class LynqoGlassContainer extends StatelessWidget {
  const LynqoGlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    EdgeInsetsGeometry? padding,
  }) : padding = padding ?? LynqoWidgetDimensions.mediumHomeContentPadding;

  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = LynqoWidgetTheme.of(context);
    final radius = LynqoWidgetDimensions.surfaceRadius;

    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
