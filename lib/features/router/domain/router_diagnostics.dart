import 'possible_api_format.dart';

class RouterDiagnostics {
  const RouterDiagnostics({
    required this.routerReachable,
    this.httpStatus,
    this.responseContentType,
    this.redirectDetected = false,
    this.authenticationRequired = false,
    this.cookiesDetected = const [],
    this.likelyApiFormat = PossibleApiFormat.unknown,
    this.discoveredEndpointHints = const [],
    this.bodyPreview,
    this.needsFurtherInspection = const [],
    this.finalRequestUrl,
    this.jsonTopLevelKeys = const [],
  });

  final bool routerReachable;
  final int? httpStatus;
  final String? responseContentType;
  final bool redirectDetected;
  final bool authenticationRequired;
  final List<String> cookiesDetected;
  final PossibleApiFormat likelyApiFormat;
  final List<String> discoveredEndpointHints;
  final String? bodyPreview;
  final List<String> needsFurtherInspection;
  final String? finalRequestUrl;
  final List<String> jsonTopLevelKeys;
}
