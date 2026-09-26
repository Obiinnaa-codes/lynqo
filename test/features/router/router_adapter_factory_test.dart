import 'package:flutter_test/flutter_test.dart';
import 'package:lynqo/features/router/config/router_config.dart';
import 'package:lynqo/features/router/config/router_profile_catalog.dart';
import 'package:lynqo/features/router/data/adapters/generic_router_adapter.dart';
import 'package:lynqo/features/router/data/adapters/router_adapter_factory.dart';
import 'package:lynqo/features/router/data/auth/router_auth_service.dart';
import 'package:lynqo/features/router/data/auth/router_secure_storage.dart';
import 'package:lynqo/features/router/data/network/router_client_factory.dart';
import 'package:lynqo/features/router/domain/router_failure.dart';
import 'package:lynqo/features/router/domain/router_profile.dart';

void main() {
  late RouterAdapterFactory factory;

  setUp(() {
    factory = RouterAdapterFactory(
      clientFactory: RouterClientFactory(
        transportConfig: RouterConfig.development(),
      ),
      authService: PendingRouterAuthService(RouterSecureStorage()),
    );
  });

  test('creates adapter for known default_mifi profile', () {
    final adapter = factory.create(RouterProfileCatalog.defaultMifi);

    expect(adapter, isA<GenericRouterAdapter>());
    expect(adapter.profile.id, 'default_mifi');
  });

  test('creates adapter for known att_wifi profile', () {
    final adapter = factory.create(RouterProfileCatalog.attWifi);

    expect(adapter.profile.id, 'att_wifi');
    expect(adapter.profile.host, 'attwifimanager');
  });

  test('throws UnsupportedRouter for unknown profile id', () {
    const unknown = RouterProfile(
      id: 'unknown_router',
      displayName: 'Unknown',
      scheme: 'http',
      host: '10.0.0.99',
    );

    expect(() => factory.create(unknown), throwsA(isA<UnsupportedRouter>()));
  });
}
