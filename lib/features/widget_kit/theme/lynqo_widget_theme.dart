import 'package:flutter/material.dart';

import '../sizing/lynqo_widget_dimensions.dart';
import '../sizing/lynqo_widget_size.dart';
import 'lynqo_widget_colors.dart';

class LynqoWidgetTheme extends ThemeExtension<LynqoWidgetTheme> {
  const LynqoWidgetTheme({
    required this.brightness,
    required this.surfaceColor,
    required this.scaffoldColor,
    required this.primaryText,
    required this.secondaryText,
    required this.accentRing,
    required this.accentHighlight,
    required this.accentPositive,
    required this.dividerColor,
    required this.chartBarInactive,
    required this.orbStroke,
    required this.surfaceRadius,
    required this.surfaceShadow,
  });

  final Brightness brightness;
  final Color surfaceColor;
  final Color scaffoldColor;
  final Color primaryText;
  final Color secondaryText;
  final Color accentRing;
  final Color accentHighlight;
  final Color accentPositive;
  final Color dividerColor;
  final Color chartBarInactive;
  final Color orbStroke;
  final double surfaceRadius;
  final List<BoxShadow> surfaceShadow;

  bool get isDark => brightness == Brightness.dark;

  static const LynqoWidgetTheme light = LynqoWidgetTheme(
    brightness: Brightness.light,
    surfaceColor: LynqoWidgetColors.lightSurface,
    scaffoldColor: LynqoWidgetColors.lightScaffold,
    primaryText: LynqoWidgetColors.lightPrimaryText,
    secondaryText: LynqoWidgetColors.lightSecondaryText,
    accentRing: LynqoWidgetColors.accentOrange,
    accentHighlight: LynqoWidgetColors.accentOrangeLight,
    accentPositive: LynqoWidgetColors.accentGreen,
    dividerColor: LynqoWidgetColors.chartBarInactive,
    chartBarInactive: LynqoWidgetColors.chartBarInactive,
    orbStroke: LynqoWidgetColors.chartBarInactive,
    surfaceRadius: LynqoWidgetDimensions.surfaceRadius,
    surfaceShadow: [
      BoxShadow(
        color: Color(0x14000000),
        blurRadius: 24,
        offset: Offset(0, 8),
      ),
    ],
  );

  static const LynqoWidgetTheme dark = LynqoWidgetTheme(
    brightness: Brightness.dark,
    surfaceColor: LynqoWidgetColors.darkSurface,
    scaffoldColor: LynqoWidgetColors.darkScaffold,
    primaryText: LynqoWidgetColors.darkPrimaryText,
    secondaryText: LynqoWidgetColors.darkSecondaryText,
    accentRing: LynqoWidgetColors.accentYellow,
    accentHighlight: LynqoWidgetColors.accentYellow,
    accentPositive: LynqoWidgetColors.accentYellow,
    dividerColor: LynqoWidgetColors.dividerDark,
    chartBarInactive: LynqoWidgetColors.chartBarInactiveDark,
    orbStroke: LynqoWidgetColors.orbEmptyStroke,
    surfaceRadius: LynqoWidgetDimensions.surfaceRadius,
    surfaceShadow: [],
  );

  static LynqoWidgetTheme of(BuildContext context) {
    return Theme.of(context).extension<LynqoWidgetTheme>() ?? light;
  }

  TextStyle captionStyle({double? fontSize}) {
    return TextStyle(
      fontSize: fontSize ?? 13,
      fontWeight: FontWeight.w500,
      color: secondaryText,
      height: 1.3,
    );
  }

  TextStyle primaryValueStyle(LynqoWidgetSize size) {
    return TextStyle(
      fontSize: LynqoWidgetDimensions.primaryValueFontSize(size),
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
      color: primaryText,
      height: 1.1,
    );
  }

  TextStyle headlineStyle(LynqoWidgetSize size) {
    return TextStyle(
      fontSize: LynqoWidgetDimensions.headlineFontSize(size),
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
      color: primaryText,
      height: 1.15,
    );
  }

  TextStyle secondaryStyle({double? fontSize}) {
    return TextStyle(
      fontSize: fontSize ?? 15,
      fontWeight: FontWeight.w400,
      color: secondaryText,
      height: 1.35,
    );
  }

  @override
  LynqoWidgetTheme copyWith({
    Brightness? brightness,
    Color? surfaceColor,
    Color? scaffoldColor,
    Color? primaryText,
    Color? secondaryText,
    Color? accentRing,
    Color? accentHighlight,
    Color? accentPositive,
    Color? dividerColor,
    Color? chartBarInactive,
    Color? orbStroke,
    double? surfaceRadius,
    List<BoxShadow>? surfaceShadow,
  }) {
    return LynqoWidgetTheme(
      brightness: brightness ?? this.brightness,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      scaffoldColor: scaffoldColor ?? this.scaffoldColor,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      accentRing: accentRing ?? this.accentRing,
      accentHighlight: accentHighlight ?? this.accentHighlight,
      accentPositive: accentPositive ?? this.accentPositive,
      dividerColor: dividerColor ?? this.dividerColor,
      chartBarInactive: chartBarInactive ?? this.chartBarInactive,
      orbStroke: orbStroke ?? this.orbStroke,
      surfaceRadius: surfaceRadius ?? this.surfaceRadius,
      surfaceShadow: surfaceShadow ?? this.surfaceShadow,
    );
  }

  @override
  LynqoWidgetTheme lerp(ThemeExtension<LynqoWidgetTheme>? other, double t) {
    if (other is! LynqoWidgetTheme) {
      return this;
    }
    return t < 0.5 ? this : other;
  }
}
