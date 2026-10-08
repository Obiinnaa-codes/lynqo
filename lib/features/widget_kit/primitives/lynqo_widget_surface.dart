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
    this.fitContent = false,
  });

  final LynqoWidgetSize size;
  final Widget child;
  final double? width;
  final double? height;
  final bool fitContent;

  @override
  Widget build(BuildContext context) {
    final theme = LynqoWidgetTheme.of(context);
    final padding = LynqoWidgetDimensions.internalPadding(size);
    final minH = LynqoWidgetDimensions.minHeight(size);

    return LayoutBuilder(
      builder: (context, constraints) {
        final boundedHeight = constraints.maxHeight.isFinite;
        final double? resolvedHeight;
        if (height != null) {
          resolvedHeight = height;
        } else if (fitContent) {
          resolvedHeight = null;
        } else if (boundedHeight) {
          resolvedHeight = constraints.maxHeight;
        } else {
          resolvedHeight = minH;
        }
        final resolvedWidth = width ??
            (constraints.maxWidth.isFinite ? constraints.maxWidth : null);
        final inner = resolvedHeight == null
            ? child
            : SizedBox(
                height: resolvedHeight - padding * 2,
                width: double.infinity,
                child: child,
              );

        return Container(
          width: resolvedWidth,
          height: resolvedHeight,
          constraints: BoxConstraints(minHeight: minH),
          decoration: BoxDecoration(
            color: theme.surfaceColor,
            borderRadius: BorderRadius.circular(theme.surfaceRadius),
            boxShadow: theme.surfaceShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: inner,
          ),
        );
      },
    );
  }
}
