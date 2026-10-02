import 'dart:ui';

import 'package:flutter/material.dart';

import '../sizing/lynqo_widget_dimensions.dart';
import '../theme/lynqo_widget_theme.dart';

/// Frosted card for the medium home-widget composite.
class LynqoGlassContainer extends StatelessWidget {
  const LynqoGlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    EdgeInsetsGeometry? padding,
  }) : padding = padding ?? const EdgeInsets.all(16);

  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = LynqoWidgetTheme.of(context);
    final radius = LynqoWidgetDimensions.surfaceRadius;
    final fill = theme.surfaceColor.withValues(
      alpha: theme.isDark ? 0.78 : 0.82,
    );
    final borderColor = theme.dividerColor.withValues(
      alpha: theme.isDark ? 0.35 : 0.55,
    );

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: theme.surfaceShadow,
        border: Border.all(color: borderColor, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: child,
        ),
      ),
    );
  }
}
