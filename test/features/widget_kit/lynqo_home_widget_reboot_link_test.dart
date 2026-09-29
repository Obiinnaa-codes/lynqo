import 'package:flutter_test/flutter_test.dart';
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
}
