import SwiftUI
import WidgetKit

private let widgetGroupId = "group.com.example.lynqo"
private let snapshotKey = "lynqo_widget_snapshot_v1"

// Keep in sync with lib/features/widget_kit/theme/lynqo_widget_colors.dart (light).
private enum LynqoPalette {
  static let surface = Color(red: 1, green: 1, blue: 1)
  static let scaffold = Color(red: 0.96, green: 0.96, blue: 0.97)
  static let primaryText = Color(red: 0.11, green: 0.11, blue: 0.12)
  static let secondaryText = Color(red: 0.43, green: 0.43, blue: 0.45)
  static let accentGreen = Color(red: 0.20, green: 0.78, blue: 0.35)
  static let accentYellow = Color(red: 1, green: 0.84, blue: 0.04)
}

struct LynqoSnapshot {
  let routerName: String
  let batteryPercent: Int?
  let batteryStatus: String
  let connectionHeadline: String
  let connectionStatus: String
  let signalPercent: Int?
  let signalLabel: String
  let dataUsed: String
  let dataRemaining: String
  let downloadMbps: String
  let uploadMbps: String
  let deviceCount: Int
  let updatedAt: String

  static let empty = LynqoSnapshot(
    routerName: "Lynqo",
    batteryPercent: nil,
    batteryStatus: "",
    connectionHeadline: "Open Lynqo to sync",
    connectionStatus: "Sign in and open the dashboard",
    signalPercent: nil,
    signalLabel: "—",
    dataUsed: "—",
    dataRemaining: "",
    downloadMbps: "—",
    uploadMbps: "—",
    deviceCount: 0,
    updatedAt: ""
  )

  static let preview = LynqoSnapshot(
    routerName: "MiFi",
    batteryPercent: 72,
    batteryStatus: "Good",
    connectionHeadline: "Connected",
    connectionStatus: "Online",
    signalPercent: 85,
    signalLabel: "Excellent",
    dataUsed: "12.4 GB",
    dataRemaining: "37.6 GB left",
    downloadMbps: "24 Mbps",
    uploadMbps: "8 Mbps",
    deviceCount: 3,
    updatedAt: ""
  )

  static func load() -> LynqoSnapshot {
    guard
      let defaults = UserDefaults(suiteName: widgetGroupId),
      let json = defaults.string(forKey: snapshotKey),
      let data = json.data(using: .utf8),
      let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else {
      return .empty
    }

    let battery = root["battery"] as? [String: Any]
    let connection = root["connection"] as? [String: Any]
    let signal = root["signal"] as? [String: Any]
    let devices = root["devices"] as? [String: Any]
    let networkSpeed = root["networkSpeed"] as? [String: Any]
    let dataUsage = root["dataUsage"] as? [String: Any]

    let batteryPercent = intValue(battery?["percent"])
    let signalPercent = intValue(signal?["strengthPercent"])
    let download = stringValue(networkSpeed?["downloadMbps"]) ?? "—"
    let upload = stringValue(networkSpeed?["uploadMbps"]) ?? "—"

    return LynqoSnapshot(
      routerName: root["routerName"] as? String ?? "MiFi",
      batteryPercent: batteryPercent,
      batteryStatus: battery?["statusLabel"] as? String ?? "",
      connectionHeadline: connection?["headline"] as? String ?? "—",
      connectionStatus: connection?["statusLabel"] as? String ?? "",
      signalPercent: signalPercent,
      signalLabel: signal?["qualityLabel"] as? String ?? "—",
      dataUsed: dataUsage?["usedSummary"] as? String ?? "—",
      dataRemaining: dataUsage?["remainingSummary"] as? String ?? "",
      downloadMbps: download,
      uploadMbps: upload,
      deviceCount: devices?["count"] as? Int ?? 0,
      updatedAt: root["updatedAt"] as? String ?? ""
    )
  }

  private static func intValue(_ value: Any?) -> Int? {
    if let i = value as? Int { return i }
    if let d = value as? Double { return Int(d) }
    return nil
  }

  private static func stringValue(_ value: Any?) -> String? {
    if let s = value as? String { return s }
    if let n = value as? NSNumber { return n.stringValue }
    return nil
  }
}

struct LynqoEntry: TimelineEntry {
  let date: Date
  let snapshot: LynqoSnapshot
}

struct LynqoProvider: TimelineProvider {
  func placeholder(in context: Context) -> LynqoEntry {
    LynqoEntry(date: Date(), snapshot: .preview)
  }

  func getSnapshot(in context: Context, completion: @escaping (LynqoEntry) -> Void) {
    let loaded = LynqoSnapshot.load()
    let snapshot =
      context.isPreview && loaded.updatedAt.isEmpty ? LynqoSnapshot.preview : loaded
    completion(LynqoEntry(date: Date(), snapshot: snapshot))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<LynqoEntry>) -> Void) {
    getSnapshot(in: context) { entry in
      let refresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
      completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
  }
}

struct LynqoWidgetEntryView: View {
  @Environment(\.widgetFamily) var family
  var entry: LynqoProvider.Entry

  var body: some View {
    Group {
      switch family {
      case .systemMedium:
        LynqoMediumWidgetView(snapshot: entry.snapshot)
      default:
        LynqoSmallWidgetView(snapshot: entry.snapshot)
      }
    }
    .foregroundStyle(LynqoPalette.primaryText)
  }
}

struct LynqoSmallWidgetView: View {
  let snapshot: LynqoSnapshot

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 6) {
        Image(systemName: "router")
          .font(.caption)
          .foregroundStyle(LynqoPalette.secondaryText)
        Text(snapshot.routerName)
          .font(.caption)
          .foregroundStyle(LynqoPalette.secondaryText)
          .lineLimit(1)
      }
      Text(snapshot.connectionHeadline)
        .font(.title3.weight(.semibold))
        .lineLimit(1)
      if !snapshot.connectionStatus.isEmpty {
        Text(snapshot.connectionStatus)
          .font(.caption)
          .foregroundStyle(LynqoPalette.secondaryText)
          .lineLimit(1)
      }
      Spacer(minLength: 0)
      HStack(alignment: .bottom) {
        if let percent = snapshot.batteryPercent {
          BatteryRingView(percent: percent)
        }
        Spacer()
        VStack(alignment: .trailing, spacing: 2) {
          Text(snapshot.downloadMbps)
            .font(.subheadline.weight(.semibold))
          Text("↓ download")
            .font(.caption2)
            .foregroundStyle(LynqoPalette.secondaryText)
        }
      }
    }
    .padding(16)
  }
}

struct LynqoMediumWidgetView: View {
  let snapshot: LynqoSnapshot

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 4) {
          Text("MiFi")
            .font(.caption)
            .foregroundStyle(LynqoPalette.secondaryText)
          Text(snapshot.routerName)
            .font(.headline)
            .lineLimit(1)
        }
        Spacer()
        if let percent = snapshot.batteryPercent {
          HStack(spacing: 6) {
            Text("\(percent)%")
              .font(.caption.weight(.medium))
            BatteryRingView(percent: percent, diameter: 28)
          }
        }
      }
      HStack(spacing: 8) {
        MetricPill(title: "Signal", value: signalValue)
        MetricPill(title: "Data", value: snapshot.dataUsed)
        MetricPill(title: "Devices", value: "\(snapshot.deviceCount)")
      }
      HStack {
        Label(snapshot.downloadMbps, systemImage: "arrow.down")
          .font(.caption)
        Spacer()
        Label(snapshot.uploadMbps, systemImage: "arrow.up")
          .font(.caption)
      }
      .foregroundStyle(LynqoPalette.secondaryText)
    }
    .padding(16)
  }

  private var signalValue: String {
    if let p = snapshot.signalPercent {
      return "\(p)%"
    }
    return snapshot.signalLabel
  }
}

struct MetricPill: View {
  let title: String
  let value: String

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(title)
        .font(.caption2)
        .foregroundStyle(LynqoPalette.secondaryText)
      Text(value)
        .font(.subheadline.weight(.semibold))
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, 8)
    .padding(.horizontal, 10)
    .background(LynqoPalette.scaffold)
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
  }
}

struct BatteryRingView: View {
  let percent: Int
  var diameter: CGFloat = 40

  var body: some View {
    ZStack {
      Circle()
        .stroke(LynqoPalette.scaffold, lineWidth: 4)
      Circle()
        .trim(from: 0, to: CGFloat(min(max(percent, 0), 100)) / 100)
        .stroke(
          percent > 20 ? LynqoPalette.accentGreen : LynqoPalette.accentYellow,
          style: StrokeStyle(lineWidth: 4, lineCap: .round)
        )
        .rotationEffect(.degrees(-90))
      Text("\(percent)")
        .font(.system(size: diameter * 0.28, weight: .semibold, design: .rounded))
    }
    .frame(width: diameter, height: diameter)
  }
}

@main
struct LynqoWidget: Widget {
  let kind: String = "LynqoWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: LynqoProvider()) { entry in
      if #available(iOSApplicationExtension 17.0, *) {
        LynqoWidgetEntryView(entry: entry)
          .containerBackground(for: .widget) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
              .fill(LynqoPalette.surface)
          }
      } else {
        LynqoWidgetEntryView(entry: entry)
          .padding()
          .background(LynqoPalette.surface)
      }
    }
    .configurationDisplayName("MiFi status")
    .description("Router overview styled like the Lynqo dashboard.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
