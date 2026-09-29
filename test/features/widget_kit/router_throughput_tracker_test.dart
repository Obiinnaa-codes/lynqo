import 'package:flutter_test/flutter_test.dart';
import 'package:lynqo/features/router/domain/router_status.dart';
import 'package:lynqo/features/widget_kit/data/router_throughput_tracker.dart';

void main() {
  test('estimates throughput from session byte counters', () async {
    final tracker = RouterThroughputTracker();
    tracker.ingest(const RouterStatus(sessionRxBytes: 0, sessionTxBytes: 0));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final speed = tracker.ingest(
      const RouterStatus(sessionRxBytes: 1_000_000, sessionTxBytes: 500_000),
    );

    expect(speed.downloadMbps, isNotNull);
    expect(speed.uploadMbps, isNotNull);
  });
}
