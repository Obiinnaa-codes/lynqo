import 'dart:convert';
import 'dart:io';

import 'package:home_widget/home_widget.dart';

import '../domain/lynqo_router_widget_snapshot.dart';
import '../domain/lynqo_router_widget_snapshot_json.dart';

/// Shared with `ios/LynqoWidget/LynqoWidget.swift` — keep keys in sync.
abstract final class LynqoHomeWidget {
  static const appGroupId = 'group.com.example.lynqo';
  static const snapshotKey = 'lynqo_widget_snapshot_v1';
  /// Must match `kind` in ios/LynqoWidget/LynqoWidget.swift (`LynqoMiFiHomeWidget2`).
  static const iOSWidgetKind = 'LynqoMiFiHomeWidget2';
  /// `homeWidget` query param required by the home_widget iOS plugin.
  static const rebootDeepLink = 'lynqo://reboot?homeWidget';

  static Future<void> initialize() async {
    if (!Platform.isIOS) {
      return;
    }
    await HomeWidget.setAppGroupId(appGroupId);
  }

  static Future<void> publishSnapshot(LynqoRouterWidgetSnapshot snapshot) async {
    if (!Platform.isIOS) {
      return;
    }
    final json = jsonEncode(snapshot.toJson());
    await HomeWidget.saveWidgetData(snapshotKey, json);
    await HomeWidget.updateWidget(iOSName: iOSWidgetKind);
  }

  static Future<void> clearSnapshot() async {
    if (!Platform.isIOS) {
      return;
    }
    await HomeWidget.saveWidgetData<String>(snapshotKey, null);
    await HomeWidget.updateWidget(iOSName: iOSWidgetKind);
  }
}
