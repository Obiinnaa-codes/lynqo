import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lynqo/features/router/data/auth/router_auth_service.dart';
import 'package:lynqo/features/router/data/auth/router_secure_storage.dart';
import 'package:lynqo/features/router/domain/router_authentication_state.dart';
import 'package:lynqo/features/router/domain/router_diagnostics.dart';
import 'package:lynqo/features/router/config/router_profile_catalog.dart';
import 'package:lynqo/features/router/domain/possible_api_format.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test(
    'login returns pending API identification without storing credentials',
    () async {
      final service = PendingRouterAuthService(RouterSecureStorage());
      const diagnostics = RouterDiagnostics(
        routerReachable: true,
        httpStatus: 200,
        responseContentType: 'text/html',
        likelyApiFormat: PossibleApiFormat.html,
        authenticationRequired: true,
        finalRequestUrl: 'http://192.168.0.1/',
      );

      final result = await service.login(
        username: 'admin',
        password: 'secret',
        discoveryDiagnostics: diagnostics,
        profile: RouterProfileCatalog.defaultMifi,
      );

      expect(result.state, RouterAuthenticationState.pendingApiIdentification);
      expect(result.message, 'Authentication is not available yet.');
      expect(await service.isAuthenticated(), isFalse);
    },
  );
}
