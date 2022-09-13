import 'package:schttp/schttp.dart';
import 'package:test/test.dart';

typedef TestCase = Future<void> Function();

TestCase getCase(String url) => () async {
      var setCacheCalled = false, getCacheCalled = false;
      final http = ScHttpClient(
        getCache: (_) {
          getCacheCalled = true;
          return null;
        },
        setCache: (_, __, ___) => setCacheCalled = true,
      );
      await http.get(url);
      assert(getCacheCalled);
      assert(setCacheCalled);
    };

TestCase postCase(String url, String body) => () async {
      var setCacheCalled = false, getCacheCalled = false;
      final http = ScHttpClient(
        getPostCache: (_, __) {
          getCacheCalled = true;
          return null;
        },
        setPostCache: (_, __, ___, ____) => setCacheCalled = true,
      );
      await http.post(url, body);
      assert(getCacheCalled);
      assert(setCacheCalled);
    };

List<TestCase> testCases = [
  getCase('https://example.com/'),
  postCase('https://example.com/', 'this is a test'),
];

void main() {
  var i = 1;
  for (final testCase in testCases) {
    test('case ${i++}', testCase);
  }
}
