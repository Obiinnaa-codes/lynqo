import '../../config/router_profile_catalog.dart';
import '../../domain/router_failure.dart';
import '../../domain/router_profile.dart';
import '../auth/router_auth_service.dart';
import '../network/router_client_factory.dart';
import 'generic_router_adapter.dart';
import 'router_adapter.dart';

class RouterAdapterFactory {
  RouterAdapterFactory({
    required this._clientFactory,
    required this._authService,
  });

  final RouterClientFactory _clientFactory;
  final RouterAuthService _authService;

  RouterAdapter create(RouterProfile profile) {
    if (RouterProfileCatalog.byId(profile.id) == null) {
      throw const UnsupportedRouter('Unknown router profile.');
    }

    final bundle = _clientFactory.createForProfile(profile);
    return GenericRouterAdapter(
      profile: profile,
      networkService: bundle.networkService,
      discoveryService: bundle.discoveryService,
      authService: _authService,
    );
  }
}
