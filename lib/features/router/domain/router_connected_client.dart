/// A client attached to the MiFi over Wi‑Fi (`router.clientList` entry).
class RouterConnectedClient {
  const RouterConnectedClient({
    required this.displayName,
    this.ipAddress,
    this.macAddress,
    this.ssid,
    this.bandLabel,
    this.networkLabel,
  });

  /// Host name from the router, or MAC when name is empty or `*`.
  final String displayName;
  final String? ipAddress;
  final String? macAddress;

  /// SSID of the Wi‑Fi network this client uses (from router model + AP source).
  final String? ssid;

  /// Human-readable band, e.g. `2.4 GHz` / `5 GHz`, from AP mode in model.json.
  final String? bandLabel;

  /// AP role when not main/secondary (e.g. `Guest`, `Arlo` for Aux AP).
  final String? networkLabel;
}
