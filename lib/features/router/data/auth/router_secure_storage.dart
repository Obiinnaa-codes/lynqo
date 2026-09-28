import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'att_wifi/att_wifi_auth_spec.dart';

class RouterSecureStorage {
  RouterSecureStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const sessionActiveKey = 'router_session_active';
  static const sessionProfileKey = 'router_session_profile';
  static const attSessionIdKey = 'router_att_session_id';
  static const rememberPasswordEnabledKey = 'router_remember_password_enabled';
  static const rememberedPasswordKey = 'router_remembered_password';

  final FlutterSecureStorage _storage;

  Future<bool> isSessionActive() async {
    final value = await _storage.read(key: sessionActiveKey);
    return value == 'true';
  }

  /// Reserved for Step 3 once the real authentication flow is confirmed.
  Future<void> markSessionActive(bool active) async {
    await _storage.write(
      key: sessionActiveKey,
      value: active ? 'true' : 'false',
    );
  }

  Future<void> saveAttWifiSession({required String sessionId}) async {
    await _storage.write(key: attSessionIdKey, value: sessionId);
    await _storage.write(
      key: sessionProfileKey,
      value: AttWifiAuthSpec.profileId,
    );
    await markSessionActive(true);
  }

  Future<String?> readAttWifiSessionId() => _storage.read(key: attSessionIdKey);

  Future<String?> readSessionProfileId() =>
      _storage.read(key: sessionProfileKey);

  Future<void> clearSession() async {
    await _storage.delete(key: sessionActiveKey);
    await _storage.delete(key: attSessionIdKey);
    await _storage.delete(key: sessionProfileKey);
  }

  Future<bool> isRememberPasswordEnabled() async {
    return await _storage.read(key: rememberPasswordEnabledKey) == 'true';
  }

  Future<String?> readRememberedPassword() async {
    if (!await isRememberPasswordEnabled()) {
      return null;
    }
    return _storage.read(key: rememberedPasswordKey);
  }

  Future<void> saveRememberedPassword(String password) async {
    await _storage.write(key: rememberPasswordEnabledKey, value: 'true');
    await _storage.write(key: rememberedPasswordKey, value: password);
  }

  Future<void> clearRememberedPassword() async {
    await _storage.delete(key: rememberPasswordEnabledKey);
    await _storage.delete(key: rememberedPasswordKey);
  }
}
