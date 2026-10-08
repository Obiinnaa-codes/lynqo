import AppIntents
import Foundation

/// Reboots the MiFi from the home screen widget without opening Lynqo.
/// Keep paths/fields in sync with `AttWifiAuthSpec` and `AttWifiDeviceActionsService`.
@available(iOSApplicationExtension 17.0, *)
struct RebootMiFiIntent: AppIntent {
  static var title: LocalizedStringResource = "Restart MiFi"
  static var openAppWhenRun = false
  static var isDiscoverable = false

  func perform() async throws -> some IntentResult {
    try await LynqoMiFiRebooter.reboot()
    return .result()
  }
}

enum LynqoMiFiRebootError: Error, LocalizedError {
  case notSignedIn
  case unreachable
  case notAdmin
  case rejected

  var errorDescription: String? {
    switch self {
    case .notSignedIn:
      return "Open Lynqo and sign in to restart the MiFi."
    case .unreachable:
      return "Join the MiFi Wi-Fi network, then try again."
    case .notAdmin, .rejected:
      return "Could not restart the MiFi."
    }
  }
}

enum LynqoMiFiRebooter {
  // Keep in sync with LynqoHomeWidget Dart keys.
  private static let widgetGroupId = "group.com.example.lynqo"
  private static let sessionIdKey = "lynqo_widget_reboot_session_id"
  private static let hostKey = "lynqo_widget_reboot_host"
  private static let schemeKey = "lynqo_widget_reboot_scheme"
  private static let captiveHostname = "attwifimanager"
  private static let fallbackHosts = ["attwifimanager", "192.168.1.1", "192.168.0.1"]
  private static let adminUserRole = "Admin"

  static func reboot() async throws {
    guard
      let defaults = UserDefaults(suiteName: widgetGroupId),
      let sessionId = defaults.string(forKey: sessionIdKey),
      !sessionId.isEmpty
    else {
      throw LynqoMiFiRebootError.notSignedIn
    }

    let scheme = defaults.string(forKey: schemeKey) ?? "http"
    var hosts: [String] = []
    if let stored = defaults.string(forKey: hostKey), !stored.isEmpty {
      hosts.append(stored)
    }
    for host in fallbackHosts where !hosts.contains(host) {
      hosts.append(host)
    }

    var lastError: Error = LynqoMiFiRebootError.unreachable
    for host in hosts {
      do {
        try await reboot(scheme: scheme, host: host, sessionId: sessionId)
        return
      } catch LynqoMiFiRebootError.notAdmin {
        throw LynqoMiFiRebootError.notAdmin
      } catch LynqoMiFiRebootError.rejected {
        throw LynqoMiFiRebootError.rejected
      } catch {
        lastError = error
      }
    }
    throw lastError
  }

  private static func reboot(
    scheme: String,
    host: String,
    sessionId: String
  ) async throws {
    let session = makeSession()
    let model = try await fetchModel(
      session: session,
      scheme: scheme,
      host: host,
      sessionId: sessionId
    )
    guard stringValue("userRole", in: model) == adminUserRole else {
      throw LynqoMiFiRebootError.notAdmin
    }
    guard let secToken = stringValue("secToken", in: model), !secToken.isEmpty else {
      throw LynqoMiFiRebootError.rejected
    }
    try await postReboot(
      session: session,
      scheme: scheme,
      host: host,
      sessionId: sessionId,
      secToken: secToken
    )
  }

  private static func fetchModel(
    session: URLSession,
    scheme: String,
    host: String,
    sessionId: String
  ) async throws -> Any {
    guard let url = modelURL(scheme: scheme, host: host, sessionId: sessionId) else {
      throw LynqoMiFiRebootError.unreachable
    }
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    applyCommonHeaders(&request, host: host, sessionId: sessionId)
    let (data, response) = try await session.data(for: request)
    guard let http = response as? HTTPURLResponse else {
      throw LynqoMiFiRebootError.unreachable
    }
    if http.statusCode == 401 || http.statusCode == 403 {
      throw LynqoMiFiRebootError.notAdmin
    }
    guard (200..<400).contains(http.statusCode) else {
      throw LynqoMiFiRebootError.unreachable
    }
    return try JSONSerialization.jsonObject(with: data)
  }

  private static func postReboot(
    session: URLSession,
    scheme: String,
    host: String,
    sessionId: String,
    secToken: String
  ) async throws {
    guard let url = configURL(scheme: scheme, host: host, sessionId: sessionId) else {
      throw LynqoMiFiRebootError.unreachable
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue(
      "application/x-www-form-urlencoded",
      forHTTPHeaderField: "Content-Type"
    )
    request.setValue("\(scheme)://\(host)/index.html", forHTTPHeaderField: "Referer")
    applyCommonHeaders(&request, host: host, sessionId: sessionId)
    request.httpBody = formBody([
      ("general.shutdown", "restart"),
      ("token", secToken),
      ("err_redirect", "/error.json"),
      ("ok_redirect", "/success.json"),
    ])
    let (data, response) = try await session.data(for: request)
    guard let http = response as? HTTPURLResponse else {
      throw LynqoMiFiRebootError.rejected
    }
    let body = String(data: data, encoding: .utf8) ?? ""
    let urlString = http.url?.absoluteString ?? ""
    if body.range(of: #""success"\s*:\s*true"#, options: .regularExpression) != nil {
      return
    }
    if urlString.contains("/success.json") {
      return
    }
    throw LynqoMiFiRebootError.rejected
  }

  private static func applyCommonHeaders(
    _ request: inout URLRequest,
    host: String,
    sessionId: String
  ) {
    request.setValue("sessionId=\(sessionId)", forHTTPHeaderField: "Cookie")
    if host != captiveHostname {
      request.setValue(captiveHostname, forHTTPHeaderField: "Host")
    }
  }

  private static func modelURL(scheme: String, host: String, sessionId: String) -> URL? {
    var components = URLComponents()
    components.scheme = scheme
    components.host = host
    components.path = "/api/model.json"
    components.queryItems = [
      URLQueryItem(name: "internalapi", value: "1"),
      URLQueryItem(name: "x", value: cacheBust()),
      URLQueryItem(name: "sessionId", value: sessionId),
    ]
    return components.url
  }

  private static func configURL(scheme: String, host: String, sessionId: String) -> URL? {
    var components = URLComponents()
    components.scheme = scheme
    components.host = host
    components.path = "/Forms/config"
    components.queryItems = [
      URLQueryItem(name: "sessionId", value: sessionId),
    ]
    return components.url
  }

  private static func formBody(_ fields: [(String, String)]) -> Data {
    let encoded = fields.map { key, value in
      "\(percentEncode(key))=\(percentEncode(value))"
    }.joined(separator: "&")
    return Data(encoded.utf8)
  }

  private static func percentEncode(_ value: String) -> String {
    var allowed = CharacterSet.urlQueryAllowed
    allowed.remove(charactersIn: ":#[]@!$&'()*+,;=/")
    return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
  }

  private static func cacheBust() -> String {
    String(Int(Date().timeIntervalSince1970 * 1_000_000))
  }

  private static func makeSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.timeoutIntervalForRequest = 3
    config.timeoutIntervalForResource = 6
    config.httpShouldSetCookies = false
    config.httpCookieAcceptPolicy = .never
    config.waitsForConnectivity = false
    return URLSession(configuration: config)
  }

  private static func stringValue(_ key: String, in object: Any) -> String? {
    if let dict = object as? [String: Any] {
      if let value = dict[key] as? String {
        return value
      }
      for nested in dict.values {
        if let found = stringValue(key, in: nested) {
          return found
        }
      }
    } else if let array = object as? [Any] {
      for nested in array {
        if let found = stringValue(key, in: nested) {
          return found
        }
      }
    }
    return nil
  }
}
