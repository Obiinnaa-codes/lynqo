import '../domain/router_profile.dart';

abstract final class RouterProfileCatalog {
  static const defaultMifiId = 'default_mifi';
  static const attWifiId = 'att_wifi';

  static const defaultMifi = RouterProfile(
    id: defaultMifiId,
    displayName: 'MiFi',
    scheme: 'http',
    host: '192.168.0.1',
  );

  static const attWifi = RouterProfile(
    id: attWifiId,
    displayName: 'AT&T WiFi',
    scheme: 'http',
    host: 'attwifimanager',
  );

  static const List<RouterProfile> all = [defaultMifi, attWifi];

  static RouterProfile? byId(String id) {
    for (final profile in all) {
      if (profile.id == id) {
        return profile;
      }
    }
    return null;
  }
}
