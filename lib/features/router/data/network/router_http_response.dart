class RouterHttpResponse {
  const RouterHttpResponse({
    required this.statusCode,
    required this.headers,
    required this.body,
    required this.requestUrl,
    required this.redirectDetected,
    this.bodyTruncated = false,
  });

  final int statusCode;
  final Map<String, List<String>> headers;
  final String body;
  final String requestUrl;
  final bool redirectDetected;
  final bool bodyTruncated;

  String? get contentType {
    final values = headers['content-type'];
    if (values == null || values.isEmpty) {
      return null;
    }
    return values.first;
  }

  List<String> get setCookieNames {
    final cookies = headers['set-cookie'];
    if (cookies == null) {
      return const [];
    }
    final names = <String>[];
    for (final cookie in cookies) {
      final name = cookie.split('=').first.trim();
      if (name.isNotEmpty) {
        names.add(name);
      }
    }
    return names;
  }
}
