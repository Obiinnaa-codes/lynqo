import 'dart:convert';

import '../../../domain/router_status.dart';

/// Maps AT&T WiFi Manager `/api/model.json` into [RouterStatus] for the dashboard.
abstract final class AttWifiModelParser {
  static RouterStatus parse(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('model.json root must be an object');
    }

    final batteryPercent = _intFromPaths(decoded, [
      ['power', 'battChargeLevel'],
    ]);
    final chargingRaw = _stringFromPaths(decoded, [
      ['power', 'charging'],
      ['power', 'battChargeStatus'],
    ]);
    final isCharging = _parseCharging(chargingRaw);

    final signalBars = _intFromPaths(decoded, [
      ['wwan', 'signalStrength', 'bars'],
    ]);
    final networkType = _stringFromPaths(decoded, [
      ['wwan', 'currentPSserviceType'],
      ['wwan', 'currentNWserviceType'],
    ]);
    final connectionState = _stringFromPaths(decoded, [
      ['wwan', 'connection'],
    ]);

    final dataUsedBytes = _intFromPaths(decoded, [
      ['wwan', 'dataUsage', 'serverDataTransferred'],
      ['wwan', 'dataUsage', 'generic', 'dataTransferred'],
    ]);
    final dataLimitBytes = _intFromPaths(decoded, [
      ['wwan', 'dataUsage', 'generic', 'billingCycleLimit'],
    ]);
    final dataRemainingBytes = _intFromPaths(decoded, [
      ['wwan', 'dataUsage', 'serverDataRemaining'],
    ]);

    final dataUsagePercent = _dataUsagePercent(
      usedBytes: dataUsedBytes,
      limitBytes: dataLimitBytes,
    );

    final billingRemainderSeconds = _intFromPaths(decoded, [
      ['wwan', 'dataUsage', 'generic', 'billingCycleRemainder'],
    ]);
    final daysRemaining = billingRemainderSeconds == null
        ? null
        : (billingRemainderSeconds / 86400).ceil();

    final planTitle = _stringFromPaths(decoded, [
      ['wwan', 'dataUsage', 'planDescription'],
      ['wwan', 'dataUsage', 'planSize'],
    ]);

    final clientList = _readPath(decoded, ['router', 'clientList']);
    final connectedDeviceCount = clientList is List ? clientList.length : null;

    return RouterStatus(
      batteryPercent: batteryPercent,
      isCharging: isCharging,
      batteryStatusLabel: chargingRaw,
      signalStrength: signalBars,
      networkType: networkType,
      connectionState: connectionState,
      dataUsageBytes: dataUsedBytes,
      dataLimitBytes: dataLimitBytes,
      dataRemainingBytes: dataRemainingBytes,
      dataUsagePercent: dataUsagePercent,
      billingDaysRemaining: daysRemaining,
      planTitle: planTitle,
      dataUsedSummary: _formatDataVolume(dataUsedBytes),
      dataLimitSummary: _formatDataVolume(dataLimitBytes),
      connectedDeviceCount: connectedDeviceCount,
    );
  }

  static bool? _parseCharging(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final lower = raw.toLowerCase();
    if (lower.contains('discharg')) {
      return false;
    }
    if (lower.contains('charg') && !lower.contains('not')) {
      return true;
    }
    if (lower.contains('not charg') || lower == 'off') {
      return false;
    }
    return null;
  }

  static int? _dataUsagePercent({
    required int? usedBytes,
    required int? limitBytes,
  }) {
    if (usedBytes == null || limitBytes == null || limitBytes <= 0) {
      return null;
    }
    return ((usedBytes / limitBytes) * 100).round().clamp(0, 999);
  }

  static String? _formatDataVolume(int? bytes) {
    if (bytes == null || bytes < 0) {
      return null;
    }
    const gb = 1024 * 1024 * 1024;
    const mb = 1024 * 1024;
    if (bytes >= gb) {
      final value = bytes / gb;
      return '${value.toStringAsFixed(value >= 10 ? 0 : 1)} GB';
    }
    if (bytes >= mb) {
      final value = bytes / mb;
      return '${value.toStringAsFixed(value >= 10 ? 0 : 1)} MB';
    }
    return '$bytes B';
  }

  static Object? _readPath(Map<String, dynamic> root, List<String> path) {
    Object? current = root;
    for (final segment in path) {
      if (current is! Map) {
        return null;
      }
      current = current[segment];
    }
    return current;
  }

  static int? _intFromPaths(
    Map<String, dynamic> root,
    List<List<String>> paths,
  ) {
    for (final path in paths) {
      final value = _readPath(root, path);
      final parsed = _coerceInt(value);
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
  }

  static String? _stringFromPaths(
    Map<String, dynamic> root,
    List<List<String>> paths,
  ) {
    for (final path in paths) {
      final value = _readPath(root, path);
      if (value == null) {
        continue;
      }
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'n/a') {
        return text;
      }
    }
    return null;
  }

  static int? _coerceInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }
}
