import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Restrained palette for in-app Lynqo widgets (light + dark reference targets).
abstract final class LynqoWidgetColors {
  static const Color lightSurface = AppColors.surface;
  static const Color lightScaffold = AppColors.background;
  static const Color lightPrimaryText = AppColors.textPrimary;
  static const Color lightSecondaryText = AppColors.textSecondary;

  static const Color darkSurface = Color(0xFF5A6767);
  static const Color darkScaffold = Color(0xFF3D4545);
  static const Color darkPrimaryText = Color(0xFFFFFFFF);
  static const Color darkSecondaryText = Color(0xB3FFFFFF);

  static const Color accentYellow = Color(0xFFFFD60A);
  static const Color accentOrange = Color(0xFFFF9500);
  static const Color accentOrangeLight = Color(0xFFFFCC00);
  static const Color accentGreen = Color(0xFF34C759);

  static const Color chartBarInactive = Color(0xFFE5E5EA);
  static const Color chartBarInactiveDark = Color(0x4DFFFFFF);
  static const Color dividerDark = Color(0x33FFFFFF);
  static const Color orbEmptyStroke = Color(0x33FFFFFF);
}
