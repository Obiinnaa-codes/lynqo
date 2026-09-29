import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/router/presentation/providers/router_auth_gate_provider.dart';
import '../../features/router/presentation/screens/router_dashboard_screen.dart';
import '../../features/router/presentation/screens/router_connection_test_screen.dart';
import '../../features/router/presentation/screens/router_manage_screen.dart';
import '../../features/widget_kit/presentation/lynqo_home_widget_reboot_link.dart';
import '../../features/widget_kit/preview/widget_kit_preview_screen.dart';
import 'app_routes.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(goRouterRefreshProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: refresh,
    redirect: (context, state) {
      final uri = state.uri;
      if (uri.scheme == 'lynqo') {
        if (isLynqoRebootDeepLink(uri)) {
          ref.read(pendingHomeWidgetRebootProvider.notifier).setPending(true);
        }
        final gate = ref.read(routerAuthGateProvider);
        if (gate.isAuthenticated) {
          return AppRoutes.routerDashboard;
        }
        return AppRoutes.login;
      }

      final gate = ref.read(routerAuthGateProvider);
      if (gate.isLoading) {
        return null;
      }

      final location = state.matchedLocation;
      final onLogin = location == AppRoutes.login;
      final onDashboard = location == AppRoutes.routerDashboard;
      final onWidgetPreview = location == AppRoutes.widgetKitPreview;
      final onManage = location == AppRoutes.routerManage;

      if (onWidgetPreview && kDebugMode) {
        return null;
      }
      if (onWidgetPreview && !kDebugMode) {
        return AppRoutes.login;
      }

      if (!gate.isAuthenticated && onManage) {
        return AppRoutes.login;
      }

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
      GoRoute(
        path: AppRoutes.routerManage,
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const RouterManageScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.widgetKitPreview,
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const WidgetKitPreviewScreen(),
        ),
      ),
    ],
  );
});
