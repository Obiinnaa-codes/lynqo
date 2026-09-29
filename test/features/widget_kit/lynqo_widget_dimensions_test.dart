import 'package:flutter_test/flutter_test.dart';
import 'package:lynqo/features/widget_kit/sizing/lynqo_widget_dimensions.dart';
import 'package:lynqo/features/widget_kit/sizing/lynqo_widget_size.dart';

void main() {
  test('sizes increase min height', () {
    expect(
      LynqoWidgetDimensions.minHeight(LynqoWidgetSize.small),
      lessThan(LynqoWidgetDimensions.minHeight(LynqoWidgetSize.large)),
    );
  });

  test('grid columns respond to width', () {
    expect(LynqoWidgetDimensions.gridColumnsForWidth(400), 2);
    expect(LynqoWidgetDimensions.gridColumnsForWidth(800), 3);
  });
}
