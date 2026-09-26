import 'router_authentication_type.dart';

class RouterProfile {
  const RouterProfile({
    required this.id,
    required this.displayName,
    required this.scheme,
    required this.host,
    this.port,
    this.manufacturer,
    this.model,
    this.authenticationType = RouterAuthenticationType.unknown,
  });

  final String id;
  final String displayName;
  final String scheme;
  final String host;
  final int? port;
  final String? manufacturer;
  final String? model;
  final RouterAuthenticationType authenticationType;

  String get baseUrl {
    final authority = port == null ? host : '$host:$port';
    return '$scheme://$authority/';
  }

  RouterProfile copyWith({
    String? manufacturer,
    String? model,
    RouterAuthenticationType? authenticationType,
  }) {
    return RouterProfile(
      id: id,
      displayName: displayName,
      scheme: scheme,
      host: host,
      port: port,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      authenticationType: authenticationType ?? this.authenticationType,
    );
  }
}
