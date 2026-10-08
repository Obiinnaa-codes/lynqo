import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../router/domain/router_status.dart';
import '../../router/presentation/widgets/router_messages_section.dart';
import '../primitives/lynqo_widget_header.dart';
import '../primitives/lynqo_widget_surface.dart';
import '../sizing/lynqo_widget_size.dart';

class SmsMessagesWidget extends ConsumerWidget {
  const SmsMessagesWidget({
    super.key,
    required this.size,
    required this.status,
  });

  final LynqoWidgetSize size;
  final RouterStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = status.unreadSmsCount;
    final headline = unread != null && unread > 0
        ? '$unread unread'
        : '${status.smsMessages.length}';

    return LynqoWidgetSurface(
      size: size,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LynqoWidgetHeader(
            category: 'Messages',
            headline: headline,
            description: 'on the MiFi',
            size: LynqoWidgetSize.medium,
          ),
          const SizedBox(height: 4),
          Expanded(
            child: RouterMessagesSection(
              status: status,
              compact: true,
            ),
          ),
        ],
      ),
    );
  }
}
