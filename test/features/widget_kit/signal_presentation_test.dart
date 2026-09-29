import 'package:flutter_test/flutter_test.dart';
import 'package:lynqo/features/widget_kit/data/signal_presentation.dart';

void main() {
  test('strengthPercentFromBars scales 0-5 to percent', () {
    expect(SignalPresentation.strengthPercentFromBars(4), 80);
    expect(SignalPresentation.strengthPercentFromBars(5), 100);
    expect(SignalPresentation.strengthPercentFromBars(null), isNull);
  });

  test('qualityLabelFromBars', () {
    expect(SignalPresentation.qualityLabelFromBars(5), 'Excellent');
    expect(SignalPresentation.qualityLabelFromBars(3), 'Good');
    expect(SignalPresentation.qualityLabelFromBars(1), 'Weak');
  });
}
