import 'package:flutter_test/flutter_test.dart';
import 'package:lynqo/features/widget_kit/domain/lynqo_router_widget_snapshot_json.dart';
import 'widget_snapshot_fixtures.dart';

void main() {
  test('snapshot toJson includes schema version', () {
    final json = syncedWidgetSnapshotFixture().toJson();
    expect(json['schemaVersion'], 1);
    expect(json['routerName'], 'MyHotspot');
    expect(json['battery'], isA<Map>());
    final devices = json['devices'] as Map<String, dynamic>;
    expect(devices['items'], isA<List>());
  });
}
