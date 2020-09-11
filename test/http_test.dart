import 'package:schttp/schttp.dart';
import 'package:test/test.dart';

typedef Future<Null> testCase();

enum HttpMethod {
  GET,
  POST,
}

testCase httpTestCase(String url, HttpMethod method, Object body,
        Map<String, String> headers) =>
    () async {
      var setCacheCalled = false;
      var getCacheCalled = false;
      var testClient = ScHttpClient(
        (_) {
          getCacheCalled = true;
          return null;
        },
        (_, __, ___) => setCacheCalled = true,
      );
      if (method == HttpMethod.GET)
        await testClient.get(Uri.parse(url));
      else if (method == HttpMethod.POST)
        await testClient.post(Uri.parse(url), body, null, headers);
      else
        throw 'The test is broken.';
      assert(setCacheCalled && getCacheCalled);
    };

testCase getCase(String url) => httpTestCase(url, HttpMethod.GET, null, null);

testCase postCase(String url, Object body, Map<String, String> headers) =>
    httpTestCase(url, HttpMethod.POST, body, headers);

List<testCase> httpTestCases = [
  getCase('https://example.com/'),
  postCase('https://example.com/', 'this is a test', {}),
];

void main() {
  group('HTTP', () {
    var i = 1;
    for (var testCase in httpTestCases) test('case ${i++}', testCase);
  });
}
