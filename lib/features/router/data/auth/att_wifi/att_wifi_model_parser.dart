import 'dart:convert';

import '../../../domain/router_connected_client.dart';
import '../../../domain/router_sms_message.dart';
import '../../../domain/router_status.dart';
import '../../../domain/router_wifi_band_snapshot.dart';

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
    final batteryStatusLabel =
        _stringFromPaths(decoded, _batteryStatusLabelPaths);
    final isCharging = _resolveIsCharging(decoded);

    final signalBars = _intFromPaths(decoded, _signalBarsPaths);
    final signalRsrp = _intFromPaths(decoded, _signalRsrpPaths);
    final networkType = _stringFromPaths(decoded, _networkTypePaths);
    final connectionState = _stringFromPaths(decoded, _connectionPaths);
    final carrierName = _stringFromPaths(decoded, _carrierPaths);
    final accountType = _stringFromPaths(decoded, _accountTypePaths);
    final roaming = _parseBool(_readFirst(decoded, _roamingPaths));

    final dataLimitValid = _dataLimitValid(decoded);
    final sessionTransferredTotal = _sessionTransferredTotal(decoded);
    final dataUsedBytes = _resolveDataUsedBytes(
      decoded,
      dataLimitValid: dataLimitValid,
      sessionTransferredTotal: sessionTransferredTotal,
    );
    final dataLimitBytes = _resolveDataLimitBytes(decoded);
    final dataRemainingBytes = _intFromPaths(decoded, _dataRemainingPaths);

    final dataUsagePercent = dataLimitValid == false
        ? _intFromPaths(decoded, _dataUsagePercentPaths)
        : _intFromPaths(decoded, _dataUsagePercentPaths) ??
            _dataUsagePercent(
              usedBytes: dataUsedBytes,
              limitBytes: dataLimitBytes,
            );

    final billingDaysRemaining = _intFromPaths(decoded, _billingDaysLeftPaths);

    final planTitle = _stringFromPaths(decoded, _planTitlePaths);
    final dataValidState = _stringFromPaths(decoded, _dataValidStatePaths);
    final wifiSsid = _stringFromPaths(decoded, _wifiSsidPaths);
    final wifiPrimaryMode = _stringFromPaths(decoded, _wifiPrimaryModePaths);
    final wifiSecondaryMode = _stringFromPaths(decoded, _wifiSecondaryModePaths);
    final wifiGuestApSsid = _stringFromPaths(decoded, _wifiGuestApSsidPaths);
    final wifiGuestApMode = _stringFromPaths(decoded, _wifiGuestApModePaths);
    final wifiGuestApAuxMode = _stringFromPaths(decoded, _wifiGuestApAuxModePaths);
    final wifiStatus = _stringFromPaths(decoded, _wifiStatusPaths);
    final wifiProfile = _stringFromPaths(decoded, _wifiProfilePaths);
    final wifiMode = _stringFromPaths(decoded, _wifiModePaths);
    final wifiBandLabel = _wifiBandLabel(
      profile: wifiProfile,
      mode: wifiMode,
    );
    final wifiSecondarySsid = _stringFromPaths(decoded, _wifiSecondarySsidPaths);
    final wifiBandSnapshots = _wifiBandSnapshots(
      profile: wifiProfile,
      mode: wifiMode,
      primarySsid: wifiSsid,
      primaryStatus: wifiStatus,
      secondarySsid: wifiSecondarySsid,
      secondaryStatus: _stringFromPaths(decoded, _wifiSecondaryStatusPaths),
    );

    final clientListRaw = _readFirst(decoded, _clientListPaths);
    final wifiConnectedClients = clientListRaw is List
        ? _parseWifiConnectedClients(
            clientListRaw,
            primarySsid: wifiSsid,
            secondarySsid: wifiSecondarySsid,
            primaryMode: wifiPrimaryMode ?? wifiMode,
            secondaryMode: wifiSecondaryMode,
            guestApSsid: wifiGuestApSsid,
            guestApMode: wifiGuestApMode,
            guestApAuxMode: wifiGuestApAuxMode,
          )
        : const <RouterConnectedClient>[];
    final connectedDeviceCount = clientListRaw is List
        ? wifiConnectedClients.length
        : null;

    final smsMessages = parseSmsMessages(decoded);
    final unreadSmsCount =
        _intFromPaths(decoded, _smsUnreadPaths) ??
        smsMessages.where((m) => !m.read).length;

    final sessionRxBytes = _intFromPaths(decoded, _sessionRxBytesPaths);
    final sessionTxBytes = _intFromPaths(decoded, _sessionTxBytesPaths);

    return RouterStatus(
      batteryPercent: batteryPercent,
      isCharging: isCharging,
      batteryStatusLabel: batteryStatusLabel,
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
      dataUsedSummary: formatDataVolume(
        dataUsedBytes,
        oneDecimalMb: dataLimitValid == false,
      ),
      dataLimitSummary: formatDataVolume(dataLimitBytes),
      dataRemainingSummary: formatDataVolume(dataRemainingBytes),
      nextBillingDateLabel: null,
      dataValidState: dataValidState,
      dataLimitValid: dataLimitValid,
      wifiSsid: wifiSsid,
      wifiStatus: wifiStatus,
      wifiProfile: wifiProfile,
      wifiBandLabel: wifiBandLabel,
      wifiBandSnapshots: wifiBandSnapshots,
      sessionRxBytes: sessionRxBytes,
      sessionTxBytes: sessionTxBytes,
      connectedDeviceCount: connectedDeviceCount,
      wifiConnectedClients: wifiConnectedClients,
      smsMessages: smsMessages,
      unreadSmsCount: smsMessages.isEmpty ? null : unreadSmsCount,
    );
  }

  static String? _wifiBandLabel({
    required String? profile,
    required String? mode,
  }) {
    if (profile != null) {
      if (profile.contains('24') || profile == 'WiFi24GHz') {
        return '2.4 GHz';
      }
      if (profile.contains('5') || profile == 'WiFi5GHz') {
        return '5 GHz';
      }
      if (profile == 'Dual' || profile == 'DualGuest') {
        return 'Dual band';
      }
    }
    if (mode == null) {
      return null;
    }
    if (mode.contains('BGN') || mode.contains('BG')) {
      return '2.4 GHz';
    }
    if (mode.contains('ANAC') || mode.contains('AC')) {
      return '5 GHz';
    }
    return null;
  }

  static List<RouterWifiBandSnapshot> _wifiBandSnapshots({
    required String? profile,
    required String? mode,
    required String? primarySsid,
    required String? primaryStatus,
    required String? secondarySsid,
    required String? secondaryStatus,
  }) {
    if (profile == 'Dual' || profile == 'DualGuest') {
      return [
        RouterWifiBandSnapshot(
          bandLabel: '2.4 GHz',
          ssid: primarySsid,
          status: primaryStatus,
        ),
        RouterWifiBandSnapshot(
          bandLabel: '5 GHz',
          ssid: secondarySsid ?? _guess5GhzSsid(primarySsid),
          status: secondaryStatus ?? primaryStatus,
        ),
      ];
    }

    if (profile == 'WiFi5GHz' || profile == 'WiFi5GHzGuest') {
      return [
        RouterWifiBandSnapshot(
          bandLabel: '5 GHz',
          ssid: primarySsid,
          status: primaryStatus,
        ),
      ];
    }

    if (profile == 'WiFi24GHz' || profile == 'WiFi24GHzGuest') {
      return [
        RouterWifiBandSnapshot(
          bandLabel: '2.4 GHz',
          ssid: primarySsid,
          status: primaryStatus,
        ),
      ];
    }

    if (secondarySsid != null && secondarySsid.isNotEmpty) {
      return [
        RouterWifiBandSnapshot(
          bandLabel: '2.4 GHz',
          ssid: primarySsid,
          status: primaryStatus,
        ),
        RouterWifiBandSnapshot(
          bandLabel: '5 GHz',
          ssid: secondarySsid,
          status: secondaryStatus ?? primaryStatus,
        ),
      ];
    }

    final label = _wifiBandLabel(profile: profile, mode: mode) ?? 'Wi‑Fi';
    if (primarySsid == null && primaryStatus == null) {
      return const [];
    }
    return [
      RouterWifiBandSnapshot(
        bandLabel: label,
        ssid: primarySsid,
        status: primaryStatus,
      ),
    ];
  }

  static List<RouterConnectedClient> _parseWifiConnectedClients(
    List<dynamic> clientList, {
    required String? primarySsid,
    required String? secondarySsid,
    required String? primaryMode,
    required String? secondaryMode,
    required String? guestApSsid,
    required String? guestApMode,
    required String? guestApAuxMode,
  }) {
    final clients = <RouterConnectedClient>[];
    for (final item in clientList) {
      if (item is! Map) {
        continue;
      }
      final map = item.cast<String, dynamic>();
      final source = map['source']?.toString();
      if (source == null || source.isEmpty) {
        continue;
      }
      if (source == 'USB' || source == 'Ethernet') {
        continue;
      }

      final mac = map['MAC']?.toString();
      final ip = map['IP']?.toString();
      final rawName = map['name']?.toString();
      final hasUsableName =
          rawName != null && rawName.isNotEmpty && rawName != '*';
      final displayName = hasUsableName ? rawName : mac;
      if (displayName == null || displayName.isEmpty) {
        continue;
      }

      String? ssid;
      String? bandLabel;
      String? networkLabel;

      switch (source) {
        case 'PrimaryAP':
          ssid = primarySsid;
          bandLabel = _bandLabelFromMode(primaryMode);
        case 'GuestAP':
          ssid = secondarySsid;
          bandLabel = _bandLabelFromMode(secondaryMode);
        case 'AuxAP':
          networkLabel = guestApAuxMode == 'Arlo' ? 'Arlo' : 'Guest';
          ssid = guestApSsid;
          bandLabel = _bandLabelFromMode(guestApMode);
        default:
          continue;
      }

      clients.add(
        RouterConnectedClient(
          displayName: displayName,
          ipAddress: ip,
          macAddress: mac,
          ssid: ssid,
          bandLabel: bandLabel,
          networkLabel: networkLabel,
        ),
      );
    }
    return clients;
  }

  static String? _bandLabelFromMode(String? mode) {
    if (mode == null || mode.isEmpty) {
      return null;
    }
    if (mode.contains('ANAC') || mode.contains('AC')) {
      return '5 GHz';
    }
    if (mode.contains('BGN') || mode.contains('BG')) {
      return '2.4 GHz';
    }
    return null;
  }

  static String? _guess5GhzSsid(String? primarySsid) {
    if (primarySsid == null || primarySsid.isEmpty) {
      return null;
    }
    if (primarySsid.endsWith('_5G')) {
      return primarySsid;
    }
    if (primarySsid.length <= 29) {
      return '${primarySsid}_5G';
    }
    return '${primarySsid.substring(0, 28)}_5G';
  }

  static List<RouterSmsMessage> parseSmsMessages(Map<String, dynamic> root) {
    final raw = _readFirst(root, _smsMessagesPaths);
    if (raw is! List) {
      return const [];
    }
    final messages = <RouterSmsMessage>[];
    for (final item in raw) {
      if (item is! Map) {
        continue;
      }
      final map = Map<String, dynamic>.from(item);
      final id = map['id']?.toString();
      final text = map['text']?.toString();
      if (id == null || id.isEmpty || text == null) {
        continue;
      }
      messages.add(
        RouterSmsMessage(
          id: id,
          sender: map['sender']?.toString() ?? 'Unknown',
          text: text.trim(),
          read: _parseBool(map['read']) ?? false,
          receivedEpochSeconds: _coerceInt(map['rxTime']),
        ),
      );
    }
    messages.sort(
      (a, b) => (b.receivedEpochSeconds ?? 0).compareTo(
        a.receivedEpochSeconds ?? 0,
      ),
    );
    return messages;
  }

  static String? formatDataVolume(
    int? bytes, {
    bool oneDecimalMb = false,
  }) {
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
      final decimals = oneDecimalMb ? 1 : (value >= 10 ? 0 : 1);
      return '${value.toStringAsFixed(decimals)} MB';
    }
    return '$bytes B';
  }

  static bool? _dataLimitValid(Map<String, dynamic> root) {
    final state = _stringFromPaths(root, _dataValidStatePaths);
    if (state == null) {
      return null;
    }
    return state == 'Valid';
  }

  static int? _resolveDataLimitBytes(Map<String, dynamic> root) {
    final planSize = _intFromPaths(root, _dataLimitPaths);
    if (planSize != null && planSize > 0) {
      return planSize;
    }

    final transferred = _intFromPaths(root, [
      ['wwan', 'dataUsage', 'serverDataTransferred'],
    ]);
    final remaining = _intFromPaths(root, _dataRemainingPaths);
    if (transferred != null && remaining != null) {
      return transferred + remaining;
    }
    return null;
  }

  /// Session WAN total (`sessTransferredTotal` in AT&T web UI).
  static int? _sessionTransferredTotal(Map<String, dynamic> root) {
    final scalar = _intFromPaths(root, [
      ['wwan', 'dataTransferred'],
    ]);
    if (scalar != null) {
      return scalar;
    }

    final rx = _intFromPaths(root, _sessionRxBytesPaths);
    final tx = _intFromPaths(root, _sessionTxBytesPaths);
    if (rx == null && tx == null) {
      return null;
    }
    return (rx ?? 0) + (tx ?? 0);
  }

  static int? _resolveDataUsedBytes(
    Map<String, dynamic> root, {
    required bool? dataLimitValid,
    required int? sessionTransferredTotal,
  }) {
    if (dataLimitValid == false) {
      return sessionTransferredTotal;
    }

    final serverTransferred = _intFromPaths(root, [
      ['wwan', 'dataUsage', 'serverDataTransferred'],
    ]);

    var used = serverTransferred ?? sessionTransferredTotal;
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

  /// Matches Netgear AirCard UI: `power.charging`, status strings, then
  /// `power.battChargeSource` (`None` = on battery, anything else = plugged in).
  static bool? _resolveIsCharging(Map<String, dynamic> decoded) {
    final fromFlag = _parseChargingField(
      _readPath(decoded, _chargingFlagPaths.first),
    );
    if (fromFlag != null) {
      return fromFlag;
    }

    for (final path in const [
      ['power', 'battChargeStatus'],
      ['power', 'batteryState'],
    ]) {
      final parsed = _parseCharging(_stringFromPaths(decoded, [path]));
      if (parsed != null) {
        return parsed;
      }
    }

    return _parseChargingFromSource(
      _stringFromPaths(decoded, _batteryChargeSourcePaths),
    );
  }

  static bool? _parseChargingField(Object? value) {
    if (value == null) {
      return null;
    }
    final asBool = _parseBool(value);
    if (asBool != null) {
      return asBool;
    }
    return _parseCharging(value.toString());
  }

  static bool? _parseChargingFromSource(String? source) {
    if (source == null || source.isEmpty) {
      return null;
    }
    final lower = source.trim().toLowerCase();
    if (lower == 'none' || lower == 'off' || lower == 'no') {
      return false;
    }
    if (lower == 'unknown') {
      return null;
    }
    return true;
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
    if (lower == 'none') {
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

  static const _batteryStatusLabelPaths = [
    ['power', 'battChargeStatus'],
    ['power', 'batteryState'],
    ['power', 'battChargeSource'],
  ];

  static const _batteryChargeSourcePaths = [
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

  static const _sessionRxBytesPaths = [
    ['wwan', 'dataTransferred', 'rx'],
    ['wwan', 'dataTransferredRx'],
  ];

  static const _sessionTxBytesPaths = [
    ['wwan', 'dataTransferred', 'tx'],
    ['wwan', 'dataTransferredTx'],
  ];

  static const _dataLimitPaths = [
    ['wwan', 'dataUsage', 'planSize'],
  ];

  static const _dataRemainingPaths = [
    ['wwan', 'dataUsage', 'serverDataRemaining'],
  ];

  static const _dataUsagePercentPaths = [
    ['wwan', 'dataUsage', 'dataUsagePercentage'],
  ];

  static const _billingDaysLeftPaths = [
    ['wwan', 'dataUsage', 'serverDaysLeft'],
  ];

  static const _planTitlePaths = [
    ['wwan', 'dataUsage', 'planDescription'],
    ['wwan', 'dataUsage', 'planSize'],
  ];

  static const _dataValidStatePaths = [
    ['wwan', 'dataUsage', 'serverDataValidState'],
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

  static const _wifiProfilePaths = [
    ['wifi', 'profile'],
  ];

  static const _wifiModePaths = [
    ['wifi', 'mode'],
    ['wifi', 'primary', 'mode'],
  ];

  static const _wifiSecondarySsidPaths = [
    ['wifi', 'secondary', 'SSID'],
    ['wifi', 'guest', 'SSID'],
  ];

  static const _wifiSecondaryStatusPaths = [
    ['wifi', 'secondary', 'status'],
    ['wifi', 'guest', 'status'],
  ];

  static const _wifiPrimaryModePaths = [
    ['wifi', 'primary', 'mode'],
    ['wifi', 'mode'],
  ];

  static const _wifiSecondaryModePaths = [
    ['wifi', 'secondary', 'mode'],
    ['wifi', 'guest', 'mode'],
  ];

  static const _wifiGuestApSsidPaths = [
    ['wifi', 'guestAP', 'SSID'],
    ['wifi', 'aux', 'SSID'],
  ];

  static const _wifiGuestApModePaths = [
    ['wifi', 'guestAP', 'mode'],
    ['wifi', 'aux', 'mode'],
  ];

  static const _wifiGuestApAuxModePaths = [
    ['wifi', 'guestAP', 'AuxMode'],
    ['wifi', 'aux', 'AuxMode'],
  ];

  static const _smsMessagesPaths = [
    ['sms', 'msgs'],
  ];

  static const _smsUnreadPaths = [
    ['sms', 'unreadMsgs'],
  ];
}
