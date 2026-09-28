import 'dart:convert';

import '../../../domain/router_status.dart';

/// Maps AT&T WiFi Manager `/api/model.json` into [RouterStatus] for the dashboard.
///
/// Field paths align with Netgear AirCard web UI bindings in `script.js`
/// (`power.*`, `wwan.*`, `wwan.dataUsage.*`, `wifi.*`, `router.*`).
abstract final class AttWifiModelParser {
  static RouterStatus parse(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('model.json root must be an object');
    }

    final batteryPercent = _intFromPaths(decoded, _batteryPercentPaths);
    final chargingRaw = _stringFromPaths(decoded, _batteryStatusPaths);
    final isCharging = _parseCharging(
      _stringFromPaths(decoded, _chargingFlagPaths) ?? chargingRaw,
    );

    final signalBars = _intFromPaths(decoded, _signalBarsPaths);
    final signalRsrp = _intFromPaths(decoded, _signalRsrpPaths);
    final networkType = _stringFromPaths(decoded, _networkTypePaths);
    final connectionState = _stringFromPaths(decoded, _connectionPaths);
    final carrierName = _stringFromPaths(decoded, _carrierPaths);
    final accountType = _stringFromPaths(decoded, _accountTypePaths);
    final roaming = _parseBool(_readFirst(decoded, _roamingPaths));

    final dataUsedBytes = _resolveDataUsedBytes(decoded);
    final dataLimitBytes = _intFromPaths(decoded, _dataLimitPaths);
    final dataRemainingBytes = _intFromPaths(decoded, _dataRemainingPaths);

    final dataUsagePercent =
        _intFromPaths(decoded, _dataUsagePercentPaths) ??
        _dataUsagePercent(usedBytes: dataUsedBytes, limitBytes: dataLimitBytes);

    final billingDaysRemaining =
        _intFromPaths(decoded, _billingDaysLeftPaths) ??
        _daysFromBillingRemainder(
          _intFromPaths(decoded, _billingRemainderSecondsPaths),
        );

    final planTitle = _stringFromPaths(decoded, _planTitlePaths);
    final dataValidState = _stringFromPaths(decoded, _dataValidStatePaths);
    final nextBillingDateLabel = _formatEpochLabel(
      _intFromPaths(decoded, _nextBillingDatePaths),
    );

    final clientList = _readFirst(decoded, _clientListPaths);
    final connectedDeviceCount = clientList is List ? clientList.length : null;

    final wifiSsid = _stringFromPaths(decoded, _wifiSsidPaths);
    final wifiStatus = _stringFromPaths(decoded, _wifiStatusPaths);

    return RouterStatus(
      batteryPercent: batteryPercent,
      isCharging: isCharging,
      batteryStatusLabel: chargingRaw,
      powerState: _stringFromPaths(decoded, _powerStatePaths),
      batteryTemperatureC: _intFromPaths(decoded, _batteryTemperaturePaths),
      signalStrength: signalBars,
      signalRsrp: signalRsrp,
      networkType: networkType,
      connectionState: connectionState,
      carrierName: carrierName,
      accountType: accountType,
      roaming: roaming,
      dataUsageBytes: dataUsedBytes,
      dataLimitBytes: dataLimitBytes,
      dataRemainingBytes: dataRemainingBytes,
      dataUsagePercent: dataUsagePercent,
      billingDaysRemaining: billingDaysRemaining,
      planTitle: planTitle,
      dataUsedSummary: formatDataVolume(dataUsedBytes),
      dataLimitSummary: formatDataVolume(dataLimitBytes),
      dataRemainingSummary: formatDataVolume(dataRemainingBytes),
      nextBillingDateLabel: nextBillingDateLabel,
      dataValidState: dataValidState,
      wifiSsid: wifiSsid,
      wifiStatus: wifiStatus,
      connectedDeviceCount: connectedDeviceCount,
    );
  }

  static String? formatDataVolume(int? bytes) {
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

  static int? _resolveDataUsedBytes(Map<String, dynamic> root) {
    final serverTransferred = _intFromPaths(root, [
      ['wwan', 'dataUsage', 'serverDataTransferred'],
    ]);
    final genericTransferred = _intFromPaths(root, [
      ['wwan', 'dataUsage', 'generic', 'dataTransferred'],
    ]);
    final sessionTotal = _intFromPaths(root, [
      ['wwan', 'dataTransferred'],
    ]);

    var used = genericTransferred ?? serverTransferred ?? sessionTotal;
    if (used == null) {
      return null;
    }

    final shareEnabled = _parseBool(_readFirst(root, _dataShareEnabledPaths));
    final dataCountAll = _intFromPaths(root, [
      ['wwan', 'dataUsage', 'share', 'dataCountAll'],
    ]);
    if (shareEnabled == true &&
        dataCountAll != null &&
        serverTransferred != null) {
      final others = dataCountAll - serverTransferred;
      if (others > 0) {
        used = used + others;
      }
    } else if (shareEnabled == true && dataCountAll != null) {
      used = dataCountAll;
    }

    return used;
  }

  static bool? _parseCharging(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final lower = raw.toLowerCase();
    if (lower.contains('discharg')) {
      return false;
    }
    if (lower == 'true' || lower == '1') {
      return true;
    }
    if (lower == 'false' || lower == '0') {
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

  static bool? _parseBool(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is bool) {
      return value;
    }
    final text = value.toString().trim().toLowerCase();
    if (text == 'true' || text == '1') {
      return true;
    }
    if (text == 'false' || text == '0') {
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

  static int? _daysFromBillingRemainder(int? seconds) {
    if (seconds == null) {
      return null;
    }
    return (seconds / 86400).ceil();
  }

  static String? _formatEpochLabel(int? epochSeconds) {
    if (epochSeconds == null || epochSeconds <= 0) {
      return null;
    }
    final date = DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static Object? _readFirst(
    Map<String, dynamic> root,
    List<List<String>> paths,
  ) {
    for (final path in paths) {
      final value = _readPath(root, path);
      if (value != null) {
        return value;
      }
    }
    return null;
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

  static const _batteryPercentPaths = [
    ['power', 'battChargeLevel'],
  ];

  static const _batteryStatusPaths = [
    ['power', 'battChargeStatus'],
    ['power', 'batteryState'],
    ['power', 'battChargeSource'],
  ];

  static const _chargingFlagPaths = [
    ['power', 'charging'],
  ];

  static const _powerStatePaths = [
    ['power', 'PMState'],
    ['power', 'SmState'],
  ];

  static const _batteryTemperaturePaths = [
    ['power', 'batteryTemperature'],
  ];

  static const _signalBarsPaths = [
    ['wwan', 'signalStrength', 'bars'],
  ];

  static const _signalRsrpPaths = [
    ['wwan', 'signalStrength', 'rsrp'],
    ['wwan', 'signalStrength', 'rssi'],
  ];

  static const _networkTypePaths = [
    ['wwan', 'currentPSserviceType'],
    ['wwan', 'currentNWserviceType'],
  ];

  static const _connectionPaths = [
    ['wwan', 'connection'],
  ];

  static const _carrierPaths = [
    ['wwan', 'registerNetworkDisplay'],
    ['wwan', 'carrier'],
  ];

  static const _accountTypePaths = [
    ['wwan', 'dataUsage', 'accountType'],
    ['wwan', 'dataUsage', 'server', 'accountType'],
  ];

  static const _roamingPaths = [
    ['wwan', 'roaming'],
  ];

  static const _dataLimitPaths = [
    ['wwan', 'dataUsage', 'generic', 'billingCycleLimit'],
    ['wwan', 'dataUsage', 'planSize'],
  ];

  static const _dataRemainingPaths = [
    ['wwan', 'dataUsage', 'serverDataRemaining'],
  ];

  static const _dataUsagePercentPaths = [
    ['wwan', 'dataUsage', 'dataUsagePercentage'],
    ['wwan', 'dataUsage', 'generic', 'dataUsagePercentage'],
  ];

  static const _billingDaysLeftPaths = [
    ['wwan', 'dataUsage', 'serverDaysLeft'],
  ];

  static const _billingRemainderSecondsPaths = [
    ['wwan', 'dataUsage', 'generic', 'billingCycleRemainder'],
  ];

  static const _planTitlePaths = [
    ['wwan', 'dataUsage', 'planDescription'],
    ['wwan', 'dataUsage', 'planSize'],
  ];

  static const _dataValidStatePaths = [
    ['wwan', 'dataUsage', 'serverDataValidState'],
  ];

  static const _nextBillingDatePaths = [
    ['wwan', 'dataUsage', 'generic', 'nextBillingDate'],
  ];

  static const _dataShareEnabledPaths = [
    ['wwan', 'dataUsage', 'share', 'enabled'],
  ];

  static const _clientListPaths = [
    ['router', 'clientList'],
  ];

  static const _wifiSsidPaths = [
    ['wifi', 'SSID'],
    ['wifi', 'primary', 'SSID'],
  ];

  static const _wifiStatusPaths = [
    ['wifi', 'primary', 'status'],
    ['wifi', 'status'],
  ];
}
