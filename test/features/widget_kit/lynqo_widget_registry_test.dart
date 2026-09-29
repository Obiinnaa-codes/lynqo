import 'package:flutter_test/flutter_test.dart';
import 'package:lynqo/features/widget_kit/domain/lynqo_widget_registry.dart';
import 'package:lynqo/features/widget_kit/domain/lynqo_widget_type.dart';
import 'package:lynqo/features/widget_kit/sizing/lynqo_widget_size.dart';

void main() {
  test('registry contains all widget types', () {
    final types = LynqoWidgetRegistry.all.map((d) => d.type).toSet();
    expect(types, LynqoWidgetType.values.toSet());
  });

  test('router overview supports large only', () {
    final overview = LynqoWidgetRegistry.byType(LynqoWidgetType.routerOverview)!;
    expect(overview.supportedSizes, [LynqoWidgetSize.large]);
  });
}
