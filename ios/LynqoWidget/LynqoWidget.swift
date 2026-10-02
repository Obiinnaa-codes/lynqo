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
  let dataLimitSummary: String
  let dataUsagePercent: Int?
  let planUnavailable: Bool
  let deviceCount: Int?
  let deviceNames: [String]
  let updatedAt: String

  var isSynced: Bool { !updatedAt.isEmpty }

  var batteryProgress: Double {
    guard isSynced, let p = batteryPercent else { return 0 }
    return Double(min(max(p, 0), 100)) / 100
  }

  var dataProgress: Double {
    guard isSynced, let p = dataUsagePercent else { return 0 }
    return Double(min(max(p, 0), 100)) / 100
  }

  var batteryPrimaryLabel: String {
    guard isSynced, let p = batteryPercent else { return "—" }
    return "\(p)%"
  }

  var dataPrimaryLabel: String {
    guard isSynced else { return "—" }
    return dataUsed
  }

  var dataSecondaryLabel: String {
    if planUnavailable {
      return "Data unavailable"
    }
    if !dataLimitSummary.isEmpty {
      return "of \(dataLimitSummary)"
    }
    if !dataRemaining.isEmpty {
      return dataRemaining
    }
    return "Data"
  }

  var devicesPrimaryLabel: String {
    guard isSynced, let count = deviceCount else { return "—" }
    return "\(count)"
  }

  var restartSecondaryLabel: String {
    routerName.isEmpty ? "MiFi" : routerName
  }

  static let empty = LynqoSnapshot(
    routerName: "Lynqo",
    batteryPercent: nil,
    batteryCharging: false,
    batteryStatus: "",
    dataUsed: "—",
    dataRemaining: "",
    dataLimitSummary: "",
    dataUsagePercent: nil,
    planUnavailable: false,
    deviceCount: nil,
    deviceNames: [],
    updatedAt: ""
  )

  static let preview = LynqoSnapshot(
    routerName: "MiFi",
    batteryPercent: 94,
    batteryCharging: false,
    batteryStatus: "",
    dataUsed: "12.4 GB",
    dataRemaining: "",
    dataLimitSummary: "50 GB",
    dataUsagePercent: 25,
    planUnavailable: false,
    deviceCount: 3,
    deviceNames: ["iPhone", "Mac", "iPad"],
    updatedAt: "preview"
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
      dataLimitSummary: dataUsage?["limitSummary"] as? String ?? "",
      dataUsagePercent: intValue(dataUsage?["usagePercent"]),
      planUnavailable: dataUsage?["planUnavailable"] as? Bool ?? false,
      deviceCount: intValue(devices?["count"]),
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

private let ringArcFraction: CGFloat = 0.94

// Home widget typography — sync conceptually with LynqoWidgetTheme home styles in Flutter preview.
private enum LynqoHomeTypography {
  static let metricValueSize: CGFloat = 16
  static let metricLabelSize: CGFloat = 12
  static let actionLabelSize: CGFloat = 12
  static let smallBatteryPercentSize: CGFloat = 32
  static let metricValueKerning: CGFloat = -0.31
  static let smallBatteryKerning: CGFloat = 0.41
  static let ringStrokeWidth: CGFloat = 3
  static let ringToValueSpacing: CGFloat = 8
  static let valueToLabelSpacing: CGFloat = 4
  static let metricPrimaryLineHeight: CGFloat = 21
  static let metricSecondaryLineHeight: CGFloat = 32
  static let decorativeRingProgress: Double = 1
  static let mediumHomePaddingH: CGFloat = 16
  static let mediumHomePaddingV: CGFloat = 16
}

enum LynqoMetricPrimaryStyle {
  case metricValue
  case actionLabel
}

struct LynqoWidgetRing: View {
  let tokens: LynqoTokens
  let progress: Double
  let diameter: CGFloat
  let systemIcon: String
  var strokeWidth: CGFloat = LynqoHomeTypography.ringStrokeWidth
  var accentColor: Color?
  var fullCircle: Bool = false

  var body: some View {
    let clamped = CGFloat(min(max(progress, 0), 1))
    let ringColor = accentColor ?? tokens.accentRing
    let arcFraction = fullCircle ? 1 : ringArcFraction
    ZStack {
      Circle()
        .trim(from: 0, to: arcFraction)
        .stroke(
          tokens.chartTrack,
          style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
        )
        .rotationEffect(.degrees(-90))
      if clamped > 0 {
        Circle()
          .trim(from: 0, to: arcFraction * clamped)
          .stroke(
            ringColor,
            style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
          )
          .rotationEffect(.degrees(-90))
      }
      Image(systemName: systemIcon)
        .font(.system(size: diameter * 0.38, weight: .regular))
        .foregroundStyle(tokens.secondaryText)
    }
    .frame(width: diameter, height: diameter)
  }
}

struct LynqoMetricColumn: View {
  let tokens: LynqoTokens
  let progress: Double
  let systemIcon: String
  let primary: String
  let secondary: String
  var primaryStyle: LynqoMetricPrimaryStyle = .metricValue
  var ringDiameter: CGFloat = 52
  var fullCircle: Bool = false

  var body: some View {
    VStack(spacing: LynqoHomeTypography.ringToValueSpacing) {
      LynqoWidgetRing(
        tokens: tokens,
        progress: progress,
        diameter: ringDiameter,
        systemIcon: systemIcon,
        fullCircle: fullCircle
      )
      VStack(spacing: LynqoHomeTypography.valueToLabelSpacing) {
        Text(primary)
          .font(primaryFont)
          .kerning(primaryKerning)
          .foregroundStyle(tokens.primaryText)
          .lineLimit(1)
          .minimumScaleFactor(0.65)
          .frame(height: LynqoHomeTypography.metricPrimaryLineHeight)
        Text(secondary)
          .font(.system(size: LynqoHomeTypography.metricLabelSize, weight: .regular))
          .foregroundStyle(tokens.secondaryText)
          .lineLimit(2)
          .minimumScaleFactor(0.8)
          .multilineTextAlignment(.center)
          .frame(
            height: LynqoHomeTypography.metricSecondaryLineHeight,
            alignment: .top
          )
      }
    }
    .frame(maxWidth: .infinity)
  }

  private var primaryFont: Font {
    switch primaryStyle {
    case .metricValue:
      return .system(size: LynqoHomeTypography.metricValueSize, weight: .medium)
    case .actionLabel:
      return .system(size: LynqoHomeTypography.actionLabelSize, weight: .medium)
    }
  }

  private var primaryKerning: CGFloat {
    switch primaryStyle {
    case .metricValue:
      return LynqoHomeTypography.metricValueKerning
    case .actionLabel:
      return 0
    }
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
          .font(.system(size: LynqoHomeTypography.smallBatteryPercentSize, weight: .regular))
          .kerning(LynqoHomeTypography.smallBatteryKerning)
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

/// Medium: four equal ring columns — battery, data, devices, restart.
struct LynqoMediumWidgetView: View {
  let snapshot: LynqoSnapshot
  let tokens: LynqoTokens

  private let ringSize: CGFloat = 52

  var body: some View {
    VStack(spacing: 0) {
      Spacer(minLength: 0)
      HStack(alignment: .top, spacing: 0) {
        LynqoMetricColumn(
          tokens: tokens,
          progress: snapshot.batteryProgress,
          systemIcon: snapshot.batteryCharging ? "bolt.fill" : "battery.100",
          primary: snapshot.batteryPrimaryLabel,
          secondary: "Battery",
          ringDiameter: ringSize
        )
        LynqoMetricColumn(
          tokens: tokens,
          progress: snapshot.dataProgress,
          systemIcon: "arrow.up.arrow.down",
          primary: snapshot.dataPrimaryLabel,
          secondary: snapshot.dataSecondaryLabel,
          ringDiameter: ringSize
        )
        LynqoMetricColumn(
          tokens: tokens,
          progress: LynqoHomeTypography.decorativeRingProgress,
          systemIcon: "laptopcomputer.and.iphone",
          primary: snapshot.devicesPrimaryLabel,
          secondary: "Devices",
          ringDiameter: ringSize,
          fullCircle: true
        )
        restartColumn
      }
      Spacer(minLength: 0)
    }
    .padding(.horizontal, LynqoHomeTypography.mediumHomePaddingH)
    .padding(.vertical, LynqoHomeTypography.mediumHomePaddingV)
  }

  @ViewBuilder
  private var restartColumn: some View {
    if #available(iOSApplicationExtension 17.0, *) {
      Link(destination: URL(string: rebootDeepLink)!) {
        LynqoMetricColumn(
          tokens: tokens,
          progress: LynqoHomeTypography.decorativeRingProgress,
          systemIcon: "power",
          primary: "Restart",
          secondary: snapshot.restartSecondaryLabel,
          ringDiameter: ringSize,
          fullCircle: true
        )
      }
      .buttonStyle(.plain)
    } else {
      LynqoMetricColumn(
        tokens: tokens,
        progress: LynqoHomeTypography.decorativeRingProgress,
        systemIcon: "power",
        primary: "Restart",
        secondary: "Open Lynqo",
        ringDiameter: ringSize,
        fullCircle: true
      )
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
  let kind: String = "LynqoMiFiHomeWidget6"

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
    let tokens = LynqoTokens.resolve(colorScheme)
    let fill = tokens.surface.opacity(colorScheme == .dark ? 0.78 : 0.82)
    ZStack {
      if colorScheme == .dark {
        Color(red: 0.24, green: 0.27, blue: 0.27)
      } else {
        Color(red: 0.94, green: 0.96, blue: 0.98)
      }
      ContainerRelativeShape()
        .fill(fill)
    }
  }
}

private struct LynqoWidgetBackgroundLegacy: View {
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    LynqoWidgetBackground()
  }
}
