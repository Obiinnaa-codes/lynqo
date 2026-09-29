import SwiftUI
import WidgetKit

private let widgetGroupId = "group.com.example.lynqo"
private let snapshotKey = "lynqo_widget_snapshot_v1"
// home_widget iOS only forwards URLs that include a `homeWidget` query item.
private let rebootDeepLink = "lynqo://reboot?homeWidget"

// Sync with lib/features/widget_kit/theme/lynqo_widget_colors.dart + lynqo_widget_dimensions.dart
struct LynqoTokens {
  let surface: Color
  let primaryText: Color
  let secondaryText: Color
  let accentRing: Color
  let accentHighlight: Color
  let chartTrack: Color
  let orbStroke: Color

  static func resolve(_ colorScheme: ColorScheme) -> LynqoTokens {
    if colorScheme == .dark {
      return LynqoTokens(
        surface: Color(red: 0.35, green: 0.40, blue: 0.40),
        primaryText: .white,
        secondaryText: Color.white.opacity(0.7),
        accentRing: Color(red: 1, green: 0.84, blue: 0.04),
        accentHighlight: Color(red: 1, green: 0.84, blue: 0.04),
        chartTrack: Color.white.opacity(0.3),
        orbStroke: Color.white.opacity(0.2)
      )
    }
    return LynqoTokens(
      surface: .white,
      primaryText: Color(red: 0.11, green: 0.11, blue: 0.12),
      secondaryText: Color(red: 0.43, green: 0.43, blue: 0.45),
      accentRing: Color(red: 1, green: 0.58, blue: 0),
      accentHighlight: Color(red: 1, green: 0.8, blue: 0),
      chartTrack: Color(red: 0.90, green: 0.90, blue: 0.92),
      orbStroke: Color(red: 0.90, green: 0.90, blue: 0.92)
    )
  }
}

struct LynqoSnapshot {
  let routerName: String
  let batteryPercent: Int?
  let batteryCharging: Bool
  let batteryStatus: String
  let dataUsed: String
  let dataRemaining: String
  let dataUsagePercent: Int?
  let deviceCount: Int
  let deviceNames: [String]
  let updatedAt: String

  var batteryProgress: Double {
    guard let p = batteryPercent else { return 0 }
    return Double(min(max(p, 0), 100)) / 100
  }

  var dataProgress: Double? {
    guard let p = dataUsagePercent else { return nil }
    return Double(min(max(p, 0), 100)) / 100
  }

  static let empty = LynqoSnapshot(
    routerName: "Lynqo",
    batteryPercent: nil,
    batteryCharging: false,
    batteryStatus: "",
    dataUsed: "—",
    dataRemaining: "",
    dataUsagePercent: nil,
    deviceCount: 0,
    deviceNames: [],
    updatedAt: ""
  )

  static let preview = LynqoSnapshot(
    routerName: "MiFi",
    batteryPercent: 72,
    batteryCharging: false,
    batteryStatus: "Good",
    dataUsed: "12.4 GB",
    dataRemaining: "37.6 GB left",
    dataUsagePercent: 24,
    deviceCount: 3,
    deviceNames: ["iPhone", "Mac", "iPad"],
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
    let devices = root["devices"] as? [String: Any]
    let dataUsage = root["dataUsage"] as? [String: Any]
    let names = devices?["names"] as? [String] ?? []

    return LynqoSnapshot(
      routerName: root["routerName"] as? String ?? "MiFi",
      batteryPercent: intValue(battery?["percent"]),
      batteryCharging: battery?["isCharging"] as? Bool ?? false,
      batteryStatus: battery?["statusLabel"] as? String ?? "",
      dataUsed: dataUsage?["usedSummary"] as? String ?? "—",
      dataRemaining: dataUsage?["remainingSummary"] as? String ?? "",
      dataUsagePercent: intValue(dataUsage?["usagePercent"]),
      deviceCount: devices?["count"] as? Int ?? 0,
      deviceNames: names,
      updatedAt: root["updatedAt"] as? String ?? ""
    )
  }

  private static func intValue(_ value: Any?) -> Int? {
    if let i = value as? Int { return i }
    if let d = value as? Double { return Int(d) }
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

// MARK: - Primitives (Flutter Widget Kit parity)

struct LynqoWidgetHeader: View {
  let tokens: LynqoTokens
  let category: String
  let headline: String
  let description: String?
  var compact: Bool = false

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(category)
        .font(.system(size: compact ? 11 : 13, weight: .medium))
        .foregroundStyle(tokens.secondaryText)
        .lineLimit(1)
      Text(headline)
        .font(.system(size: compact ? 22 : 28, weight: .semibold))
        .foregroundStyle(tokens.primaryText)
        .lineLimit(1)
        .minimumScaleFactor(0.65)
      if let description, !description.isEmpty {
        Text(description)
          .font(.system(size: 15, weight: .regular))
          .foregroundStyle(tokens.secondaryText)
          .lineLimit(2)
          .minimumScaleFactor(0.8)
      }
    }
  }
}

struct LynqoWidgetRing: View {
  let tokens: LynqoTokens
  let progress: Double
  let diameter: CGFloat
  let systemIcon: String

  var body: some View {
    ZStack {
      Circle()
        .stroke(tokens.chartTrack, lineWidth: 5)
      Circle()
        .trim(from: 0, to: CGFloat(min(max(progress, 0), 1)))
        .stroke(
          tokens.accentRing,
          style: StrokeStyle(lineWidth: 5, lineCap: .round)
        )
        .rotationEffect(.degrees(-90))
      Image(systemName: systemIcon)
        .font(.system(size: diameter * 0.38, weight: .medium))
        .foregroundStyle(tokens.secondaryText)
    }
    .frame(width: diameter, height: diameter)
  }
}

struct LynqoWidgetProgressBar: View {
  let tokens: LynqoTokens
  let progress: Double

  var body: some View {
    GeometryReader { geo in
      ZStack(alignment: .leading) {
        Capsule()
          .fill(tokens.chartTrack)
        Capsule()
          .fill(tokens.accentHighlight)
          .frame(width: geo.size.width * CGFloat(min(max(progress, 0), 1)))
      }
    }
    .frame(height: 6)
  }
}

struct LynqoDeviceOrb: View {
  let tokens: LynqoTokens
  let label: String?

  var body: some View {
    Circle()
      .strokeBorder(tokens.orbStroke, lineWidth: 1)
      .background(Circle().fill(tokens.surface.opacity(0.5)))
      .frame(width: 28, height: 28)
      .overlay {
        if let label, let initial = label.first {
          Text(String(initial).uppercased())
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(tokens.secondaryText)
        }
      }
  }
}

// MARK: - Widget layouts

struct LynqoWidgetEntryView: View {
  @Environment(\.widgetFamily) var family
  @Environment(\.colorScheme) var colorScheme
  var entry: LynqoProvider.Entry

  var body: some View {
    let tokens = LynqoTokens.resolve(colorScheme)
    Group {
      switch family {
      case .systemMedium:
        LynqoMediumWidgetView(snapshot: entry.snapshot, tokens: tokens)
      default:
        LynqoSmallWidgetView(snapshot: entry.snapshot, tokens: tokens)
      }
    }
    .foregroundStyle(tokens.primaryText)
  }
}

/// Small: [LynqoWidgetRing] + primary value below (battery_widget small).
struct LynqoSmallWidgetView: View {
  let snapshot: LynqoSnapshot
  let tokens: LynqoTokens

  private let ringSize: CGFloat = 56

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      if snapshot.batteryPercent != nil {
        LynqoWidgetRing(
          tokens: tokens,
          progress: snapshot.batteryProgress,
          diameter: ringSize,
          systemIcon: snapshot.batteryCharging ? "bolt.fill" : "battery.100"
        )
        Spacer(minLength: 8)
        Text(percentLabel)
          .font(.system(size: 36, weight: .semibold))
          .foregroundStyle(tokens.primaryText)
          .lineLimit(1)
          .minimumScaleFactor(0.7)
      } else {
        LynqoWidgetHeader(
          tokens: tokens,
          category: "Battery",
          headline: "—",
          description: "Open Lynqo and open the dashboard to sync."
        )
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .padding(16)
  }

  private var percentLabel: String {
    guard let p = snapshot.batteryPercent else { return "—" }
    return "\(p)%"
  }
}

/// Medium: battery | data usage | devices + restart.
struct LynqoMediumWidgetView: View {
  let snapshot: LynqoSnapshot
  let tokens: LynqoTokens

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .top, spacing: 8) {
        batterySection
          .frame(maxWidth: .infinity, alignment: .leading)
        dataSection
          .frame(maxWidth: .infinity, alignment: .leading)
        devicesSection
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      restartControl
    }
    .padding(16)
  }

  private var batterySection: some View {
    VStack(alignment: .leading, spacing: 8) {
      LynqoWidgetRing(
        tokens: tokens,
        progress: snapshot.batteryProgress,
        diameter: 52,
        systemIcon: snapshot.batteryCharging ? "bolt.fill" : "battery.100"
      )
      Text(percentLabel)
        .font(.system(size: 28, weight: .semibold))
        .foregroundStyle(tokens.primaryText)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
      if !snapshot.batteryStatus.isEmpty {
        Text(snapshot.batteryStatus)
          .font(.system(size: 13, weight: .regular))
          .foregroundStyle(tokens.secondaryText)
          .lineLimit(1)
      }
    }
  }

  private var dataSection: some View {
    VStack(alignment: .leading, spacing: 6) {
      LynqoWidgetHeader(
        tokens: tokens,
        category: "Data usage",
        headline: snapshot.dataUsed,
        description: dataDescription,
        compact: true
      )
      if let progress = snapshot.dataProgress {
        LynqoWidgetProgressBar(tokens: tokens, progress: progress)
      }
    }
  }

  private var devicesSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      LynqoWidgetHeader(
        tokens: tokens,
        category: "Connected devices",
        headline: "\(snapshot.deviceCount)",
        description: "devices connected",
        compact: true
      )
      if colorSchemeIsDark {
        HStack(spacing: 6) {
          ForEach(0..<3, id: \.self) { index in
            LynqoDeviceOrb(
              tokens: tokens,
              label: index < snapshot.deviceNames.count ? snapshot.deviceNames[index] : nil
            )
          }
        }
      }
    }
  }

  @Environment(\.colorScheme) private var colorScheme
  private var colorSchemeIsDark: Bool { colorScheme == .dark }

  private var dataDescription: String? {
    if !snapshot.dataRemaining.isEmpty {
      return snapshot.dataRemaining
    }
    return nil
  }

  private var percentLabel: String {
    guard let p = snapshot.batteryPercent else { return "—" }
    return "\(p)%"
  }

  @ViewBuilder
  private var restartControl: some View {
    if #available(iOSApplicationExtension 17.0, *) {
      Link(destination: URL(string: rebootDeepLink)!) {
        HStack(spacing: 6) {
          Image(systemName: "arrow.clockwise")
            .font(.system(size: 14, weight: .semibold))
          Text("Restart MiFi")
            .font(.system(size: 15, weight: .semibold))
        }
        .foregroundStyle(tokens.accentRing)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
      }
      .buttonStyle(.plain)
    } else {
      Text("Restart: open Lynqo")
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(tokens.secondaryText)
        .frame(maxWidth: .infinity)
    }
  }
}

struct LynqoWidgetRootView: View {
  @Environment(\.colorScheme) private var colorScheme
  let entry: LynqoProvider.Entry

  var body: some View {
    LynqoWidgetEntryView(entry: entry)
  }
}

// WidgetKit caches aggressively; bump [kind] when layouts change so the gallery picks up new binaries.
@main
struct LynqoWidget: Widget {
  let kind: String = "LynqoMiFiHomeWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: LynqoProvider()) { entry in
      if #available(iOSApplicationExtension 17.0, *) {
        LynqoWidgetRootView(entry: entry)
          .containerBackground(for: .widget) {
            LynqoWidgetBackground()
          }
      } else {
        LynqoWidgetRootView(entry: entry)
          .padding()
          .background(LynqoWidgetBackgroundLegacy())
      }
    }
    .configurationDisplayName("MiFi")
    .description("Small: battery %. Medium: battery, data, devices, restart.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

private struct LynqoWidgetBackground: View {
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    ContainerRelativeShape()
      .fill(LynqoTokens.resolve(colorScheme).surface)
  }
}

private struct LynqoWidgetBackgroundLegacy: View {
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    LynqoTokens.resolve(colorScheme).surface
  }
}
