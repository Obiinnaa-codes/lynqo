import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/routing/app_routes.dart';
import '../../router/presentation/providers/router_auth_gate_provider.dart';
import 'lynqo_home_widget_reboot_link.dart';

/// Forwards `lynqo://reboot?homeWidget` widget taps into the app.
class LynqoHomeWidgetLinkListener extends ConsumerStatefulWidget {
  const LynqoHomeWidgetLinkListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LynqoHomeWidgetLinkListener> createState() =>
      _LynqoHomeWidgetLinkListenerState();
}

class _LynqoHomeWidgetLinkListenerState
    extends ConsumerState<LynqoHomeWidgetLinkListener> {
  StreamSubscription<Uri?>? _subscription;

  @override
  void initState() {
    super.initState();
    if (!Platform.isIOS) {
      return;
    }
    _subscription = HomeWidget.widgetClicked.listen(_handleUri);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final initial = await HomeWidget.initiallyLaunchedFromHomeWidget();
      await _handleUri(initial);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _handleUri(Uri? uri) async {
    if (uri == null || !isLynqoRebootDeepLink(uri)) {
      return;
    }

    ref.read(pendingHomeWidgetRebootProvider.notifier).setPending(true);

    // Session restore can still be in flight when the app opens from a widget.
    for (var attempt = 0; attempt < 60; attempt++) {
      final gate = ref.read(routerAuthGateProvider);
      if (!gate.isLoading) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    if (!mounted) {
      return;
    }

    final gate = ref.read(routerAuthGateProvider);
    final router = ref.read(goRouterProvider);
    if (gate.isAuthenticated) {
      router.go(AppRoutes.routerDashboard);
    } else {
      router.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
