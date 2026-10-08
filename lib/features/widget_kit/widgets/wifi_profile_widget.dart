import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../router/domain/router_status.dart';
import '../../router/presentation/widgets/router_wifi_profile_section.dart';
import '../primitives/lynqo_widget_surface.dart';
import '../primitives/lynqo_widget_typography.dart';
import '../sizing/lynqo_widget_size.dart';

class WifiProfileWidget extends ConsumerWidget {
  const WifiProfileWidget({
    super.key,
    required this.size,
    required this.status,
  });

  final LynqoWidgetSize size;
  final RouterStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LynqoWidgetSurface(
      size: size,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LynqoWidgetTitle(text: 'Wi‑Fi', size: LynqoWidgetSize.medium),
              const SizedBox(height: 6),
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: RouterWifiProfileSection(
                    status: status,
                    compact: true,
                    maxContentWidth: constraints.maxWidth,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
