import 'package:schttp/schttp.dart';
import 'package:test/test.dart';

typedef Future<Null> testCase();

testCase httpTestCase(String url, bool get,
        [String? body, Map<String, String>? headers]) =>
    () async {
      var setCacheCalled = false, getCacheCalled = false;
      final http = ScHttpClient(
        getCache: (_) {
          getCacheCalled = true;
          return null;
        },
        setCache: (_, __, ___) => setCacheCalled = true,
      );
      await (get ? http.get(url) : http.post(url, body!, body, headers!));
      assert(setCacheCalled && getCacheCalled);
    };

testCase getCase(String url) => httpTestCase(url, true);
testCase postCase(String url, String body, Map<String, String> headers) =>
    httpTestCase(url, false, body, headers);

List<testCase> testCases = [
  getCase('https://example.com/'),
  postCase('https://example.com/', 'this is a test', {}),
];

void main() {
  var i = 1;
  for (final testCase in testCases) test('case ${i++}', testCase);
}
