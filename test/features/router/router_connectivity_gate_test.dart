import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lynqo/features/router/data/network/router_connectivity_gate.dart';

void main() {
  test('empty connectivity results do not block discovery', () {
    expect(
      shouldBlockWhenOnlyNone(const [], skipOfflineBlock: false),
      isFalse,
    );
  });

  test('wifi connectivity does not block discovery', () {
    expect(
      shouldBlockForConnectivity(const [ConnectivityResult.wifi]),
      isFalse,
    );
  });

  test('only none blocks on phone-like paths', () {
    expect(
      shouldBlockWhenOnlyNone(const [
        ConnectivityResult.none,
      ], skipOfflineBlock: false),
      isTrue,
    );
  });

  test('only none does not block when offline skip applies', () {
    expect(
      shouldBlockWhenOnlyNone(const [
        ConnectivityResult.none,
      ], skipOfflineBlock: true),
      isFalse,
    );
  });

  test('desktop platforms skip offline connectivity block', () {
    if (isDesktopPlatform()) {
      expect(shouldSkipOfflineConnectivityBlock(), isTrue);
      expect(
        shouldBlockForConnectivity(const [ConnectivityResult.none]),
        isFalse,
      );
    }
  });

  test('detects simulator via SIMULATOR_DEVICE_NAME', () {
    expect(
      isIosSimulatorEnvironment(const {'SIMULATOR_DEVICE_NAME': 'iPhone 16'}),
      isTrue,
    );
  });

  test('detects simulator via SIMULATOR_UDID fallback', () {
    expect(
      isIosSimulatorEnvironment(const {'SIMULATOR_UDID': 'test-udid'}),
      isTrue,
    );
  });

  test('host test runner is not treated as iOS simulator', () {
    expect(isIosSimulator(), isFalse);
    expect(isIosDevConnectivityBypass(), isFalse);
  });
}
