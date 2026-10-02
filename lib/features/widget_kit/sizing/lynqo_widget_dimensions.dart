import 'package:flutter/widgets.dart';

import 'lynqo_widget_size.dart';

/// Single source of truth for widget kit layout metrics.
abstract final class LynqoWidgetDimensions {
  static const double surfaceRadius = 26;

  /// Medium home composite — keep in sync with `LynqoMediumWidgetView` in LynqoWidget.swift.
  static const EdgeInsets mediumHomeContentPadding = EdgeInsets.all(16);
  static const double mediumHomeMetricRingSpacing = 8;
  static const double mediumHomeMetricLabelSpacing = 4;
  /// Fixed slots so primary/secondary lines align across medium home columns.
  static const double mediumHomeMetricPrimaryLineHeight = 21;
  static const double mediumHomeMetricSecondaryLineHeight = 32;
  /// Decorative full rings (devices, restart) — sync with medium home Swift widget.
  static const double mediumHomeDecorativeRingProgress = 1;
  /// Keep in sync with `LynqoHomeTypography.ringStrokeWidth` in LynqoWidget.swift.
  static const double homeMetricRingStrokeWidth = 3;

  static double internalPadding(LynqoWidgetSize size) {
    switch (size) {
      case LynqoWidgetSize.small:
        return 16;
      case LynqoWidgetSize.medium:
        return 20;
      case LynqoWidgetSize.large:
        return 24;
    }
  }

  static double minHeight(LynqoWidgetSize size) {
    switch (size) {
      case LynqoWidgetSize.small:
        return 148;
      case LynqoWidgetSize.medium:
        return 220;
      case LynqoWidgetSize.large:
        return 320;
    }
  }

  static double ringDiameter(LynqoWidgetSize size) {
    switch (size) {
      case LynqoWidgetSize.small:
        return 56;
      case LynqoWidgetSize.medium:
        return 52;
      case LynqoWidgetSize.large:
        return 72;
    }
  }

  static double primaryValueFontSize(LynqoWidgetSize size) {
    switch (size) {
      case LynqoWidgetSize.small:
        return 36;
      case LynqoWidgetSize.medium:
        return 28;
      case LynqoWidgetSize.large:
        return 32;
    }
  }

  static double headlineFontSize(LynqoWidgetSize size) {
    switch (size) {
      case LynqoWidgetSize.small:
        return 22;
      case LynqoWidgetSize.medium:
        return 24;
      case LynqoWidgetSize.large:
        return 20;
    }
  }

  static int gridColumnsForWidth(double width) {
    if (width >= 600) {
      return 3;
    }
    return 2;
  }
}
