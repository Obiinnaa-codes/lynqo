import 'package:flutter/material.dart' show Color, IconData, Icons;

import '../domain/lynqo_router_widget_snapshot.dart';
import '../domain/models/widget_view_models.dart';
import '../theme/lynqo_widget_colors.dart';

/// View-model helpers for the medium home widget (no fake metrics).
abstract final class LynqoMediumMiFiPresentation {
  /// Epoch [updatedAt] means the home widget has not received a sync yet.
  static bool isSynced(LynqoRouterWidgetSnapshot snapshot) {
    return snapshot.updatedAt.millisecondsSinceEpoch != 0;
  }

  static String batteryPrimary(LynqoRouterWidgetSnapshot snapshot) {
    if (!isSynced(snapshot)) {
      return '—';
    }
    final percent = snapshot.battery.percent;
    if (percent == null) {
      return '—';
    }
    return '$percent%';
  }

  static double? batteryProgress(LynqoRouterWidgetSnapshot snapshot) {
    if (!isSynced(snapshot)) {
      return null;
    }
    return snapshot.battery.progress;
  }

  static String dataPrimary(LynqoRouterWidgetSnapshot snapshot) {
    if (!isSynced(snapshot)) {
      return '—';
    }
    return snapshot.dataUsage.usedSummary ?? '—';
  }

  static String dataSecondary(LynqoRouterWidgetSnapshot snapshot) {
    if (snapshot.dataUsage.planUnavailable) {
      return 'Data unavailable';
    }
    final limit = snapshot.dataUsage.limitSummary;
    if (limit != null && limit.isNotEmpty) {
      return 'of $limit';
    }
    final remaining = snapshot.dataUsage.remainingSummary;
    if (remaining != null && remaining.isNotEmpty) {
      return remaining;
    }
    return 'Data';
  }

  static double? dataProgress(LynqoRouterWidgetSnapshot snapshot) {
    if (!isSynced(snapshot)) {
      return null;
    }
    return snapshot.dataUsage.progress;
  }

  static String devicesPrimary(LynqoRouterWidgetSnapshot snapshot) {
    if (!isSynced(snapshot)) {
      return '—';
    }
    final count = snapshot.devices.count;
    if (count == null) {
      return '—';
    }
    return '$count';
  }

  /// Full battery uses system green (reference home widget).
  static Color? batteryProgressColor(LynqoRouterWidgetSnapshot snapshot) {
    if (!isSynced(snapshot)) {
      return null;
    }
    if (snapshot.battery.percent == 100) {
      return LynqoWidgetColors.accentGreen;
    }
    return null;
  }

  static IconData batteryIcon(BatteryWidgetData battery) {
    if (battery.isCharging == true) {
      return Icons.battery_charging_full;
    }
    return Icons.battery_std_outlined;
  }
}
