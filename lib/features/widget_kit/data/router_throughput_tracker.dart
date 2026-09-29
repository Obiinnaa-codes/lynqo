import '../../router/domain/router_status.dart';
import '../domain/models/widget_view_models.dart';
import 'router_widget_mappers.dart';

/// Estimates WAN throughput from cumulative `wwan.dataTransferred` counters between polls.
class RouterThroughputTracker {
  int? _prevRx;
  int? _prevTx;
  DateTime? _prevAt;
  NetworkSpeedWidgetData _last = const NetworkSpeedWidgetData();

  NetworkSpeedWidgetData get last => _last;

  NetworkSpeedWidgetData ingest(RouterStatus status) {
    final rx = status.sessionRxBytes;
    final tx = status.sessionTxBytes;
    final now = DateTime.now();

    NetworkSpeedWidgetData result = const NetworkSpeedWidgetData();

    if (_prevRx != null &&
        _prevTx != null &&
        _prevAt != null &&
        rx != null &&
        tx != null) {
      final elapsedMs = now.difference(_prevAt!).inMilliseconds;
      if (elapsedMs > 0) {
        final downloadBps = ((rx - _prevRx!).clamp(0, rx) * 8000) / elapsedMs;
        final uploadBps = ((tx - _prevTx!).clamp(0, tx) * 8000) / elapsedMs;
        result = NetworkSpeedWidgetData(
          downloadMbps: RouterWidgetMappers.formatMbps(downloadBps.round()),
          uploadMbps: RouterWidgetMappers.formatMbps(uploadBps.round()),
        );
      }
    }

    if (rx != null) {
      _prevRx = rx;
    }
    if (tx != null) {
      _prevTx = tx;
    }
    _prevAt = now;

    _last = result;
    return _last;
  }

  void reset() {
    _prevRx = null;
    _prevTx = null;
    _prevAt = null;
    _last = const NetworkSpeedWidgetData();
  }
}
