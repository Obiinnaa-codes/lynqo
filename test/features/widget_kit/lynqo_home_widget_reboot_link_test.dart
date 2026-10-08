import 'package:flutter_test/flutter_test.dart';
import 'package:lynqo/features/router/config/router_profile_catalog.dart';
import 'package:lynqo/features/widget_kit/data/lynqo_home_widget.dart';
import 'package:lynqo/features/widget_kit/presentation/lynqo_home_widget_reboot_link.dart';

void main() {
  test('isLynqoRebootDeepLink accepts widget and platform URL forms', () {
    expect(isLynqoRebootDeepLink(Uri.parse('lynqo://reboot')), isTrue);
    expect(isLynqoRebootDeepLink(Uri.parse('lynqo://reboot/')), isTrue);
    expect(
      isLynqoRebootDeepLink(Uri.parse('lynqo://reboot?homeWidget')),
      isTrue,
    );
    expect(isLynqoRebootDeepLink(Uri.parse('/login')), isFalse);
  });

  test('widget reboot App Group keys stay aligned with Swift', () {
    expect(LynqoHomeWidget.appGroupId, 'group.com.example.lynqo');
    expect(
      LynqoHomeWidget.rebootSessionIdKey,
      'lynqo_widget_reboot_session_id',
    );
    expect(LynqoHomeWidget.rebootHostKey, 'lynqo_widget_reboot_host');
    expect(LynqoHomeWidget.rebootSchemeKey, 'lynqo_widget_reboot_scheme');
    expect(RouterProfileCatalog.attWifi.host, 'attwifimanager');
    expect(RouterProfileCatalog.attWifi.scheme, 'http');
  });
}
