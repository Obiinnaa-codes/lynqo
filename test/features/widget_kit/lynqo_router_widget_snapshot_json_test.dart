import 'package:flutter_test/flutter_test.dart';
import 'package:lynqo/features/widget_kit/domain/lynqo_router_widget_snapshot_json.dart';
import 'package:lynqo/features/widget_kit/preview/lynqo_widget_mock_data.dart';

void main() {
  test('snapshot toJson includes schema version', () {
    final json = LynqoWidgetMockData.snapshot.toJson();
    expect(json['schemaVersion'], 1);
    expect(json['routerName'], 'MyHotspot');
    expect(json['battery'], isA<Map>());
  });
}
