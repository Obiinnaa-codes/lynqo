/// Confirmed AT&T WiFi Manager (Netgear AirCard) authentication contract.
/// Field names and paths only — no live session values or credentials.
abstract final class AttWifiAuthSpec {
  static const profileId = 'att_wifi';

  /// Captive hostname (phones). Desktop OS often cannot resolve it; probe [discoveryGatewayHosts].
  static const captiveHostname = 'attwifimanager';

  /// Gateway IPs used when [captiveHostname] does not resolve (common on macOS).
  static const discoveryGatewayHosts = ['192.168.1.1', '192.168.0.1'];

  /// SPA shell shown before and after login attempts.
  static const loginPagePath = '/index.html';

  /// Bootstrap: `GET /` → cookie + redirect chain ending at login page.
  static const bootstrapPath = '/';

  /// Admin login uses an HTML form POST (also used programmatically).
  static const authenticationPath = '/Forms/config';

  static const httpMethodPost = 'POST';

  static const contentTypeFormUrlEncoded = 'application/x-www-form-urlencoded';

  /// Query parameter on `/Forms/config` (browser login form action) and API calls.
  static const sessionIdQueryParameter = 'sessionId';

  /// HttpOnly cookie set during bootstrap (`sessionId=…`).
  static const sessionIdCookieName = 'sessionId';

  /// Device model + session metadata (includes [secTokenJsonKey] while guest).
  static const modelJsonPath = '/api/model.json';

  static const internalApiQueryFlag = 'internalapi';
  static const internalApiQueryValue = '1';

  /// Cache-busting query parameter on `/api/model.json` (browser `x=`).
  static const cacheBustQueryParameter = 'x';

  /// CSRF token from model JSON (`device.session.secToken` in UI).
  static const tokenFormField = 'token';
  static const secTokenJsonKey = 'secToken';

  /// Primary credential field (UI username is display-only; not submitted).
  static const passwordFormField = 'session.password';

  /// JSON redirect targets used by programmatic submit (see web `Ea.de()`).
  static const errorRedirectFormField = 'err_redirect';
  static const okRedirectFormField = 'ok_redirect';
  static const errorRedirectPath = '/error.json';
  static const successRedirectPath = '/success.json';

  /// HTML form redirect targets (browser login form defaults).
  static const htmlErrorRedirectPath = '/index.html?loginfailed';
  static const htmlOkRedirectPath = '/index.html';

  static const userRoleJsonKey = 'userRole';
  static const adminUserRole = 'Admin';
  static const guestUserRole = 'Guest';

  /// Successful `/Forms/config` response body when using JSON redirects.
  static const successResponseKey = 'success';

  /// Failed login (`session.password` validation).
  static const errorNumberKey = 'errno';
  static const errorDetailKey = 'errdetail';
  static const invalidPasswordErrno = 2;
  /// Form submit rejected: session/token mismatch (not wrong password).
  static const invalidSessionErrno = 6;
  static const invalidPasswordErrorDetail = 'session.password';

  /// Logout via empty password submit on the same endpoint.
  static const logoutPasswordValue = '';

  /// Full device reboot (web menu: Reboot Mobile Router).
  static const shutdownFormField = 'general.shutdown';

  /// Browser `deviceRestart` handler value (not `Restart` used after some form saves).
  static const rebootShutdownValue = 'restart';

  static const wifiProfileFormField = 'wifi.profile';
  static const wifiProfile24Ghz = 'WiFi24GHz';
  static const wifiProfile5Ghz = 'WiFi5GHz';

  static const smsDeleteIdFormField = 'sms.deleteId';
  static const smsDeleteAllFormField = 'sms.deleteAll';
  static const smsDeleteAllValue = '1';

  /// Builds POST fields for immediate actions (`Ea.de()` JSON redirect parity).
  static Map<String, String> jsonActionFields({
    required String secToken,
    required Map<String, String> data,
  }) {
    return {
      ...data,
      tokenFormField: secToken,
      errorRedirectFormField: errorRedirectPath,
      okRedirectFormField: successRedirectPath,
    };
  }
}
