import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';

/// Bouncing “pull to refresh” chip; parent removes after a few seconds.
class DashboardPullToRefreshHint extends StatefulWidget {
  const DashboardPullToRefreshHint({super.key});

  static var shownThisSession = false;

  @override
  State<DashboardPullToRefreshHint> createState() =>
      _DashboardPullToRefreshHintState();
}

class _DashboardPullToRefreshHintState extends State<DashboardPullToRefreshHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    DashboardPullToRefreshHint.shownThisSession = true;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _offset = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _offset,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _offset.value),
            child: child,
          );
        },
        child: Material(
          color: theme.colorScheme.surface.withValues(alpha: 0.92),
          elevation: 2,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.swipe_down,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Pull down to refresh',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
