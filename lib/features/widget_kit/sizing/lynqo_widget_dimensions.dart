import 'package:flutter/widgets.dart';

import 'lynqo_widget_size.dart';

/// Single source of truth for widget kit layout metrics.
abstract final class LynqoWidgetDimensions {
  static const double surfaceRadius = 28;

  /// Medium home composite — keep in sync with `LynqoMediumWidgetView` in LynqoWidget.swift.
  static const EdgeInsets mediumHomeContentPadding =
      EdgeInsets.fromLTRB(12, 14, 12, 14);
  static const double mediumHomeDividerHeight = 72;
  static const double mediumHomeMetricRingSpacing = 8;

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
