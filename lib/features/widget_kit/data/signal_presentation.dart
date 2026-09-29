/// Maps router signal bars (0–5) to widget display values.
abstract final class SignalPresentation {
  static int? strengthPercentFromBars(int? bars) {
    if (bars == null) {
      return null;
    }
    final clamped = bars.clamp(0, 5);
    return (clamped / 5 * 100).round();
  }

  static String? qualityLabelFromBars(int? bars) {
    if (bars == null) {
      return null;
    }
    if (bars >= 4) {
      return 'Excellent';
    }
    if (bars == 3) {
      return 'Good';
    }
    if (bars == 2) {
      return 'Fair';
    }
    return 'Weak';
  }
}
