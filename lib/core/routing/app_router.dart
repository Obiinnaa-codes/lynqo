import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/router/presentation/providers/router_auth_gate_provider.dart';
import '../../features/router/presentation/screens/router_dashboard_screen.dart';
import '../../features/router/presentation/screens/router_connection_test_screen.dart';
import 'app_routes.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(goRouterRefreshProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: refresh,
    redirect: (context, state) {
      final gate = ref.read(routerAuthGateProvider);
      if (gate.isLoading) {
        return null;
      }

      final location = state.matchedLocation;
      final onLogin = location == AppRoutes.login;
      final onDashboard = location == AppRoutes.routerDashboard;

      if (gate.isAuthenticated && onLogin) {
        return AppRoutes.routerDashboard;
      }
      if (!gate.isAuthenticated && onDashboard) {
        return AppRoutes.login;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) =>
            NoTransitionPage(key: state.pageKey, child: const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.routerDashboard,
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const RouterDashboardScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.routerConnectionTest,
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const RouterConnectionTestScreen(),
        ),
      ),
    ],
  );
});
