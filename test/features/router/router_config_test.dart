import 'package:flutter_test/flutter_test.dart';
import 'package:lynqo/features/router/config/router_config.dart';
import 'package:lynqo/features/router/config/router_profile_catalog.dart';
import 'package:lynqo/features/router/domain/router_profile.dart';

void main() {
  test('development config uses default MiFi profile and builds base URL', () {
    final config = RouterConfig.development();

    expect(config.profile, RouterProfileCatalog.defaultMifi);
    expect(config.host, '192.168.0.1');
    expect(config.baseUrl, 'http://192.168.0.1/');
    expect(config.scheme, 'http');
  });

  test('base URL is derived from profile scheme and host', () {
    const profile = RouterProfile(
      id: 'test',
      displayName: 'Test',
      scheme: 'https',
      host: '10.0.0.1',
    );
    final config = RouterConfig(profile: profile);

    expect(config.baseUrl, 'https://10.0.0.1/');
  });

  test('forProfile swaps endpoint while keeping transport settings', () {
    final base = RouterConfig.development();
    final attConfig = base.forProfile(RouterProfileCatalog.attWifi);

    expect(attConfig.host, 'attwifimanager');
    expect(attConfig.baseUrl, 'http://attwifimanager/');
    expect(attConfig.connectTimeout, base.connectTimeout);
  });
}
