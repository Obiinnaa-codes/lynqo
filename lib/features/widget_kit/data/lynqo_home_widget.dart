import 'dart:convert';
import 'dart:io';

import 'package:home_widget/home_widget.dart';

import '../domain/lynqo_router_widget_snapshot.dart';
import '../domain/lynqo_router_widget_snapshot_json.dart';

/// Shared with `ios/LynqoWidget/LynqoWidget.swift` — keep keys in sync.
abstract final class LynqoHomeWidget {
  static const appGroupId = 'group.com.example.lynqo';
  static const snapshotKey = 'lynqo_widget_snapshot_v1';
  /// Session id for the widget Restart App Intent — keep in sync with Swift.
  static const rebootSessionIdKey = 'lynqo_widget_reboot_session_id';
  static const rebootHostKey = 'lynqo_widget_reboot_host';
  static const rebootSchemeKey = 'lynqo_widget_reboot_scheme';
  /// Must match `kind` on `LynqoMiFiHomeWidget` in ios/LynqoWidget/LynqoWidget.swift.
  static const iOSHomeWidgetKind = 'LynqoMiFiHomeWidget11';
  /// Must match `kind` on `LynqoMiFiDevicesWidget` in ios/LynqoWidget/LynqoDevicesWidget.swift.
  static const iOSDevicesWidgetKind = 'LynqoMiFiDevicesWidget1';
  /// `homeWidget` query param required by the home_widget iOS plugin.
  static const rebootDeepLink = 'lynqo://reboot?homeWidget';

  static Future<void> initialize() async {
    if (!Platform.isIOS) {
      return;
    }
    await HomeWidget.setAppGroupId(appGroupId);
  }

  static Future<void> publishSnapshot(
    LynqoRouterWidgetSnapshot snapshot, {
    String? rebootSessionId,
    String? rebootHost,
    String? rebootScheme,
  }) async {
    if (!Platform.isIOS) {
      return;
    }
    final json = jsonEncode(snapshot.toJson());
    await HomeWidget.saveWidgetData(snapshotKey, json);
    if (rebootSessionId != null &&
        rebootSessionId.isNotEmpty &&
        rebootHost != null &&
        rebootHost.isNotEmpty) {
      await HomeWidget.saveWidgetData(rebootSessionIdKey, rebootSessionId);
      await HomeWidget.saveWidgetData(rebootHostKey, rebootHost);
      await HomeWidget.saveWidgetData(
        rebootSchemeKey,
        rebootScheme ?? 'http',
      );
    }
    await HomeWidget.updateWidget(iOSName: iOSHomeWidgetKind);
    await HomeWidget.updateWidget(iOSName: iOSDevicesWidgetKind);
  }

  static Future<void> clearSnapshot() async {
    if (!Platform.isIOS) {
      return;
    }
    await HomeWidget.saveWidgetData<String>(snapshotKey, null);
    await HomeWidget.saveWidgetData<String>(rebootSessionIdKey, null);
    await HomeWidget.saveWidgetData<String>(rebootHostKey, null);
    await HomeWidget.saveWidgetData<String>(rebootSchemeKey, null);
    await HomeWidget.updateWidget(iOSName: iOSHomeWidgetKind);
    await HomeWidget.updateWidget(iOSName: iOSDevicesWidgetKind);
  }
}
