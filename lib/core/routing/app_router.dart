import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/router/presentation/screens/router_dashboard_screen.dart';
import '../../features/router/presentation/screens/router_connection_test_screen.dart';
import 'app_routes.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  ref.keepAlive();
  return GoRouter(
    initialLocation: AppRoutes.login,
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
