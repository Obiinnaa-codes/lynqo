import SwiftUI
import WidgetKit

private enum LynqoDevicesListTypography {
  static let contentPadding: CGFloat = 16
  static let headerBottom: CGFloat = 12
  static let rowVertical: CGFloat = 9
  static let rowTitleSize: CGFloat = 15
  static let rowSubtitleSize: CGFloat = 13
  static let headerTitleSize: CGFloat = 17
  static let maxVisibleRows = 6
}

/// Large-only list of Wi‑Fi clients (Batteries large–style rows).
struct LynqoLargeDevicesWidgetView: View {
  let snapshot: LynqoSnapshot
  let tokens: LynqoTokens

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      header
      if snapshot.isSynced {
        if visibleRows.isEmpty {
          unsyncedOrEmptyMessage("No devices connected")
        } else {
          ForEach(Array(visibleRows.enumerated()), id: \.offset) { index, row in
            if index > 0 {
              LynqoListDivider(tokens: tokens)
            }
            deviceRow(row)
          }
          if overflowCount > 0 {
            LynqoListDivider(tokens: tokens)
            Text("+\(overflowCount) more")
              .font(.system(size: LynqoDevicesListTypography.rowSubtitleSize))
              .foregroundStyle(tokens.secondaryText)
              .padding(.top, LynqoDevicesListTypography.rowVertical)
          }
        }
      } else {
        unsyncedOrEmptyMessage("Open Lynqo on the MiFi network to sync devices.")
      }
      Spacer(minLength: 0)
    }
    .padding(LynqoDevicesListTypography.contentPadding)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }

  private var header: some View {
    HStack(alignment: .center, spacing: 10) {
      Image(systemName: "wifi")
        .font(.system(size: 18, weight: .regular))
        .foregroundStyle(tokens.secondaryText)
      Text(snapshot.routerName)
        .font(.system(size: LynqoDevicesListTypography.headerTitleSize, weight: .semibold))
        .foregroundStyle(tokens.primaryText)
        .lineLimit(1)
        .minimumScaleFactor(0.75)
      Spacer(minLength: 8)
      Text(headerCountLabel)
        .font(.system(size: LynqoDevicesListTypography.rowSubtitleSize, weight: .medium))
        .foregroundStyle(tokens.secondaryText)
        .lineLimit(1)
    }
    .padding(.bottom, LynqoDevicesListTypography.headerBottom)
  }

  private var headerCountLabel: String {
    guard snapshot.isSynced, let count = snapshot.deviceCount else { return "—" }
    return count == 1 ? "1 device" : "\(count) devices"
  }

  private var visibleRows: [LynqoDeviceRow] {
    Array(snapshot.deviceRows.prefix(LynqoDevicesListTypography.maxVisibleRows))
  }

  private var overflowCount: Int {
    max(0, snapshot.deviceRows.count - LynqoDevicesListTypography.maxVisibleRows)
  }

  private func deviceRow(_ row: LynqoDeviceRow) -> some View {
    HStack(alignment: .center, spacing: 12) {
      Image(systemName: "iphone")
        .font(.system(size: 16, weight: .regular))
        .foregroundStyle(tokens.secondaryText)
        .frame(width: 22, alignment: .center)
      Text(row.name)
        .font(.system(size: LynqoDevicesListTypography.rowTitleSize, weight: .regular))
        .foregroundStyle(tokens.primaryText)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
      Spacer(minLength: 8)
      if !row.subtitle.isEmpty {
        Text(row.subtitle)
          .font(.system(size: LynqoDevicesListTypography.rowSubtitleSize))
          .foregroundStyle(tokens.secondaryText)
          .lineLimit(1)
          .minimumScaleFactor(0.8)
      }
    }
    .padding(.vertical, LynqoDevicesListTypography.rowVertical)
  }

  private func unsyncedOrEmptyMessage(_ message: String) -> some View {
    Text(message)
      .font(.system(size: LynqoDevicesListTypography.rowSubtitleSize))
      .foregroundStyle(tokens.secondaryText)
      .lineLimit(3)
      .minimumScaleFactor(0.85)
      .padding(.top, 4)
  }
}

private struct LynqoListDivider: View {
  let tokens: LynqoTokens

  var body: some View {
    Rectangle()
      .fill(tokens.chartTrack)
      .frame(height: 1)
  }
}

struct LynqoDevicesWidgetRootView: View {
  @Environment(\.colorScheme) private var colorScheme
  let entry: LynqoProvider.Entry

  var body: some View {
    let tokens = LynqoTokens.resolve(colorScheme)
    LynqoLargeDevicesWidgetView(snapshot: entry.snapshot, tokens: tokens)
      .foregroundStyle(tokens.primaryText)
  }
}

/// Large home screen widget — connected clients list only.
struct LynqoMiFiDevicesWidget: Widget {
  let kind: String = "LynqoMiFiDevicesWidget1"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: LynqoProvider()) { entry in
      if #available(iOSApplicationExtension 17.0, *) {
        LynqoDevicesWidgetRootView(entry: entry)
          .containerBackground(for: .widget) {
            LynqoWidgetBackground()
          }
      } else {
        LynqoDevicesWidgetRootView(entry: entry)
          .padding()
          .background(LynqoWidgetBackgroundLegacy())
      }
    }
    .configurationDisplayName("MiFi devices")
    .description("Connected Wi‑Fi clients on your MiFi.")
    .supportedFamilies([.systemLarge])
  }
}
