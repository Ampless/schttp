import 'package:schttp/schttp.dart';
import 'package:tested/tested.dart';

TestCase getCase(String url) => () async {
      var setCacheCalled = false, getCacheCalled = false;
      final http = ScHttpClient(
        getCache: (_, __) {
          getCacheCalled = true;
          return null;
        },
        setCache: (_, __, ___, ____) => setCacheCalled = true,
      );
      await http.get(url);
      assert(getCacheCalled);
      assert(setCacheCalled);
    };

TestCase postCase(String url, String body) => () async {
      var setCacheCalled = false, getCacheCalled = false;
      final http = ScHttpClient(
        getPostCache: (_, __, ___) {
          getCacheCalled = true;
          return null;
        },
        setPostCache: (_, __, ___, ____, _____) => setCacheCalled = true,
      );
      await http.post(url, body);
      assert(getCacheCalled);
      assert(setCacheCalled);
    };

void main() => tests('http', [
      getCase('https://example.com/'),
      postCase('https://example.com/', 'this is a test'),
    ]);
