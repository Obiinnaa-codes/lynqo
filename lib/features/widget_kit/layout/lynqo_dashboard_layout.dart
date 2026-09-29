import '../domain/lynqo_widget_type.dart';
import '../sizing/lynqo_widget_size.dart';
import 'lynqo_widget_grid.dart';

/// Default dashboard composition — overview plus focused tiles (no duplicate metrics).
abstract final class LynqoDashboardLayout {
  static const List<LynqoWidgetGridEntry> entries = [
    LynqoWidgetGridEntry(
      type: LynqoWidgetType.routerOverview,
      size: LynqoWidgetSize.large,
      columnSpan: 2,
    ),
    LynqoWidgetGridEntry(
      type: LynqoWidgetType.dataUsage,
      size: LynqoWidgetSize.medium,
      columnSpan: 2,
    ),
    LynqoWidgetGridEntry(
      type: LynqoWidgetType.devices,
      size: LynqoWidgetSize.medium,
      columnSpan: 2,
    ),
    LynqoWidgetGridEntry(
      type: LynqoWidgetType.connection,
      size: LynqoWidgetSize.medium,
      columnSpan: 2,
    ),
    LynqoWidgetGridEntry(
      type: LynqoWidgetType.speed,
      size: LynqoWidgetSize.medium,
      columnSpan: 2,
    ),
  ];
}
