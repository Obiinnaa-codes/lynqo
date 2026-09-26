/// Confirmed AT&T WiFi Manager (Netgear AirCard) authentication contract.
/// Field names and paths only — no live session values or credentials.
abstract final class AttWifiAuthSpec {
  static const profileId = 'att_wifi';

  /// SPA shell shown before and after login attempts.
  static const loginPagePath = '/index.html';

  /// Bootstrap: `GET /` → cookie + redirect chain ending at login page.
  static const bootstrapPath = '/';

  /// Admin login uses an HTML form POST (also used programmatically).
  static const authenticationPath = '/Forms/config';

  static const httpMethodPost = 'POST';

  static const contentTypeFormUrlEncoded = 'application/x-www-form-urlencoded';

  /// Query parameter appended to `/Forms/config` and internal API calls.
  static const sessionIdQueryParameter = 'sessionId';

  /// HttpOnly cookie set during bootstrap (`sessionId=…`).
  static const sessionIdCookieName = 'sessionId';

  /// Device model + session metadata (includes [secTokenJsonKey] while guest).
  static const modelJsonPath = '/api/model.json';

  static const internalApiQueryFlag = 'internalapi';
  static const internalApiQueryValue = '1';

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
  static const invalidPasswordErrorDetail = 'session.password';

  /// Logout via empty password submit on the same endpoint.
  static const logoutPasswordValue = '';
}
