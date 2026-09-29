import 'dart:io' show Platform;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

const _iosSimulatorEnvironmentKeys = [
  'SIMULATOR_DEVICE_NAME',
  'SIMULATOR_UDID',
  'SIMULATOR_MODEL_IDENTIFIER',
];

/// Whether [connectivity_plus] results should block router discovery.
bool shouldBlockForConnectivity(List<ConnectivityResult> results) {
  final envSimulator = isIosSimulatorEnvironment(Platform.environment);
  final devIosBypass = isIosDevConnectivityBypass();
  final skipOfflineBlock = shouldSkipOfflineConnectivityBlock();
  final blocked = shouldBlockWhenOnlyNone(
    results,
    skipOfflineBlock: skipOfflineBlock,
  );

  logConnectivityGateDecision(
    results: results,
    envSimulator: envSimulator,
    devIosBypass: devIosBypass,
    skipOfflineBlock: skipOfflineBlock,
    blocked: blocked,
  );

  return blocked;
}

/// Desktop + iOS simulator: [connectivity_plus] often reports [none] on local
/// MiFi Wi‑Fi; router reachability is decided by HTTP discovery instead.
@visibleForTesting
bool shouldSkipOfflineConnectivityBlock() {
  return isIosSimulator() || isDesktopPlatform();
}

@visibleForTesting
bool isDesktopPlatform() {
  if (kIsWeb) {
    return false;
  }
  return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
}

@visibleForTesting
bool shouldBlockWhenOnlyNone(
  List<ConnectivityResult> results, {
  required bool skipOfflineBlock,
}) {
  if (results.isEmpty) {
    return false;
  }
  if (!results.every((r) => r == ConnectivityResult.none)) {
    return false;
  }
  if (skipOfflineBlock) {
    return false;
  }
  return true;
}

@visibleForTesting
bool isIosSimulatorEnvironment(Map<String, String> environment) {
  for (final key in _iosSimulatorEnvironmentKeys) {
    if (environment.containsKey(key)) {
      return true;
    }
  }
  return false;
}

/// True when iOS should not be blocked on [ConnectivityResult.none] alone.
@visibleForTesting
bool isIosDevConnectivityBypass() {
  return !kIsWeb && Platform.isIOS && !kReleaseMode;
}

@visibleForTesting
bool isIosSimulator() {
  if (kIsWeb || !Platform.isIOS) {
    return false;
  }
  if (isIosSimulatorEnvironment(Platform.environment)) {
    return true;
  }
  // Simulator env vars are not always visible to Dart on iOS; non-release builds
  // still need to reach router discovery (e.g. iOS Simulator).
  return !kReleaseMode;
}

@visibleForTesting
void logConnectivityGateDecision({
  required List<ConnectivityResult> results,
  required bool envSimulator,
  required bool devIosBypass,
  required bool skipOfflineBlock,
  required bool blocked,
}) {
  if (!kDebugMode) {
    return;
  }

  debugPrint(
    '[RouterConnectivity] checkConnectivity=$results '
    'envSimulator=$envSimulator devIosBypass=$devIosBypass '
    'desktop=${isDesktopPlatform()} skipOfflineBlock=$skipOfflineBlock '
    'blocked=$blocked',
  );

  if (!Platform.isIOS) {
    return;
  }

  final matchedKeys = _iosSimulatorEnvironmentKeys
      .where(Platform.environment.containsKey)
      .toList();
  debugPrint(
    '[RouterConnectivity] iOS simulator env keys present: $matchedKeys '
    '(total Platform.environment keys: ${Platform.environment.length})',
  );

  if (blocked) {
    debugPrint(
      '[RouterConnectivity] Blocking connect: treating device as offline. '
      'If this is the iOS Simulator, use a debug build and check logs above.',
    );
  }
}
