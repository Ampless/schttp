import 'dart:convert';
import 'dart:io';

class ScHttpClient {
  var _client = HttpClient();
  String Function(String) getCache;
  void Function(String, String, Duration) setCache;

  ScHttpClient(this.getCache, this.setCache);

  Future<String> post(
    Uri url,
    Object body,
    String id,
    Map<String, String> headers, {
    Duration ttl,
  }) async {
    if (url == null) throw '[schttp-POST] url = null';
    if (body == null) throw '[schttp-POST] body = null';
    if (id == null) throw '[schttp-POST] id = null';
    if (headers == null) throw '[schttp-POST] headers = null';
    ttl ??= Duration(minutes: 15);
    if (getCache != null) {
      var cachedResp = getCache(id);
      if (cachedResp != null) return cachedResp;
    }
    var req = await _client.postUrl(url);
    headers.forEach((k, v) => req.headers.add(k, v));
    req.writeln(body);
    return _finishRequest(req, id, ttl);
  }

  Future<String> get(Uri url, {Duration ttl}) async {
    if (url == null) throw '[schttp-GET] url = null';
    ttl ??= Duration(days: 4);
    if (getCache != null) {
      var cachedResp = getCache('$url');
      if (cachedResp != null) return cachedResp;
    }
    return _finishRequest(await _client.getUrl(url), '$url', ttl);
  }

  Future<String> _finishRequest(
    HttpClientRequest req,
    String id,
    Duration ttl,
  ) async {
    await req.flush();
    var res = await req.close();
    var bytes = await res.toList();
    var actualBytes = <int>[];
    for (var b in bytes) actualBytes.addAll(b);

    String r;
    try {
      String Function(List<int>) charset;
      var cs = res.headers.contentType.charset.toLowerCase();
      if (cs == 'utf-8')
        charset = utf8.decode;
      else if (cs == 'us' || cs == 'us-ascii' || cs == 'ascii')
        charset = ascii.decode;
      else if (cs == 'latin1' || cs == 'l1')
        charset = latin1.decode;
      else
        charset = utf8.decode;
      r = charset(actualBytes);
    } catch (e) {
      r = String.fromCharCodes(actualBytes);
    }

    if (res.statusCode == 200 && setCache != null) setCache(id, r, ttl);
    return r;
  }
}
