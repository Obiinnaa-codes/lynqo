import 'package:flutter_test/flutter_test.dart';
import 'package:lynqo/features/router/data/discovery/router_api_analyzer.dart';
import 'package:lynqo/features/router/domain/possible_api_format.dart';

void main() {
  final analyzer = RouterApiAnalyzer();

  test('detects JSON and top-level keys', () {
    final analysis = analyzer.analyze(
      body: '{"status":"ok","battery":80}',
      contentType: 'application/json',
    );

    expect(analysis.likelyApiFormat, PossibleApiFormat.json);
    expect(analysis.jsonTopLevelKeys, ['status', 'battery']);
  });

  test('extracts HTML script and endpoint hints', () {
    final analysis = analyzer.analyze(
      body: '''
        <html><head><title>MiFi</title></head>
        <body>
          <form action="/goform/login" method="post">
            <input type="password" name="password" />
          </form>
          <script src="/js/app.js"></script>
          <script>fetch("/api/status")</script>
        </body></html>
      ''',
      contentType: 'text/html',
      statusCode: 200,
    );

    expect(analysis.likelyApiFormat, PossibleApiFormat.html);
    expect(analysis.pageTitle, 'MiFi');
    expect(analysis.scriptSources, ['/js/app.js']);
    expect(analysis.endpointHints, contains('/goform/login'));
    expect(analysis.endpointHints, contains('/api/status'));
    expect(analysis.authenticationRequired, isTrue);
  });

  test('detects XML format', () {
    final analysis = analyzer.analyze(
      body: '<?xml version="1.0"?><response><ok/></response>',
      contentType: 'application/xml',
    );

    expect(analysis.likelyApiFormat, PossibleApiFormat.xml);
  });
}
