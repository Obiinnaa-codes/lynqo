import '../../domain/router_status.dart';
import '../../domain/router_wifi_band_snapshot.dart';

List<RouterWifiBandSnapshot> wifiBandsFromStatus(RouterStatus status) {
  if (status.wifiBandSnapshots.isNotEmpty) {
    return status.wifiBandSnapshots;
  }
  if (status.wifiSsid == null) {
    return const [];
  }
  return [
    RouterWifiBandSnapshot(
      bandLabel: status.wifiBandLabel ?? 'Wi‑Fi',
      ssid: status.wifiSsid,
      status: status.wifiStatus,
    ),
  ];
}
