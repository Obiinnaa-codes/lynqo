import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: LynqoApp()));
}

/// No [ConsumerWidget] — avoids Riverpod-driven rebuilds of [MaterialApp.router].
class LynqoApp extends StatefulWidget {
  const LynqoApp({super.key});

  @override
  State<LynqoApp> createState() => _LynqoAppState();
}

class _LynqoAppState extends State<LynqoApp> {
  GoRouter? _router;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _router ??= ProviderScope.containerOf(context).read(goRouterProvider);
  }

  @override
  Widget build(BuildContext context) {
    final router = _router;
    if (router == null) {
      return const SizedBox.shrink();
    }

    return MaterialApp.router(
      title: 'MiFi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
