import 'package:schttp/schttp.dart';
import 'package:test/test.dart';

typedef Future<Null> testCase();

testCase getCase(String url) => () async {
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

testCase postCase(String url, String body) => () async {
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

List<testCase> testCases = [
  getCase('https://example.com/'),
  postCase('https://example.com/', 'this is a test'),
];

void main() {
  var i = 1;
  for (final testCase in testCases) test('case ${i++}', testCase);
}
