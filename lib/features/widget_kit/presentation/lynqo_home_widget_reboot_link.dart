import 'package:flutter_riverpod/flutter_riverpod.dart';

class PendingHomeWidgetReboot extends Notifier<bool> {
  @override
  bool build() => false;

  void setPending(bool value) => state = value;
}

/// Set when the user taps Restart on the iOS home screen widget.
final pendingHomeWidgetRebootProvider =
    NotifierProvider<PendingHomeWidgetReboot, bool>(PendingHomeWidgetReboot.new);

/// Matches `lynqo://reboot`, `lynqo://reboot/`, and `lynqo://reboot?homeWidget`.
bool isLynqoRebootDeepLink(Uri uri) {
  if (uri.scheme != 'lynqo') {
    return false;
  }
  if (uri.host == 'reboot') {
    return true;
  }
  return uri.path == '/reboot' || uri.path == 'reboot';
}
