import 'package:flutter_test/flutter_test.dart';
import 'package:lynqo/features/router/config/router_profile_catalog.dart';
import 'package:lynqo/features/router/domain/router_profile.dart';

void main() {
  test('default MiFi profile builds 192.168.0.1 base URL', () {
    final profile = RouterProfileCatalog.defaultMifi;

    expect(profile.id, 'default_mifi');
    expect(profile.host, '192.168.0.1');
    expect(profile.baseUrl, 'http://192.168.0.1/');
  });

  test('AT&T WiFi profile builds attwifimanager base URL', () {
    final profile = RouterProfileCatalog.attWifi;

    expect(profile.id, 'att_wifi');
    expect(profile.host, 'attwifimanager');
    expect(profile.baseUrl, 'http://attwifimanager/');
  });

  test('catalog lists both known profiles', () {
    expect(RouterProfileCatalog.all, hasLength(2));
    expect(RouterProfileCatalog.all.map((p) => p.id), [
      'default_mifi',
      'att_wifi',
    ]);
  });

  test('base URL includes port when set', () {
    const profile = RouterProfile(
      id: 'custom',
      displayName: 'Custom',
      scheme: 'https',
      host: 'router.local',
      port: 8443,
    );

    expect(profile.baseUrl, 'https://router.local:8443/');
  });
}
