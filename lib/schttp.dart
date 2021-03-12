import 'dart:convert';
import 'dart:io';

class ScHttpClient {
  final _client = HttpClient();
  String? Function(String) getCache;
  void Function(String, String, Duration) setCache;

  ScHttpClient([this.getCache = _getCacheDmy, this.setCache = _setCacheDmy]);

  static String? _getCacheDmy(String _) => null;
  static void _setCacheDmy(String _, String __, Duration ___) {}

  Future<String> post(
    Uri url,
    Object body,
    String id,
    Map<String, String> headers, {
    bool readCache = true,
    bool writeCache = true,
    Duration? ttl,
  }) async {
    ttl ??= Duration(minutes: 15);
    final cachedResp = readCache ? getCache(id) : null;
    if (cachedResp != null) return cachedResp;
    final req = await _client.postUrl(url);
    headers.forEach((k, v) => req.headers.add(k, v));
    req.writeln(body);
    return _finishRequest(req, id, writeCache, ttl);
  }

  Future<String> get(
    Uri url, {
    bool readCache = true,
    bool writeCache = true,
    Duration? ttl,
  }) async {
    ttl ??= Duration(days: 4);
    final cachedResp = getCache('$url');
    if (cachedResp != null) return cachedResp;
    return _finishRequest(await _client.getUrl(url), '$url', writeCache, ttl);
  }

  Future<String> _finishRequest(
    HttpClientRequest req,
    String id,
    bool writeCache,
    Duration ttl,
  ) async {
    await req.flush();
    final res = await req.close();
    final bytes = await res.toList();
    final actualBytes = <int>[];
    for (var b in bytes) actualBytes.addAll(b);

    String r;
    try {
      String Function(List<int>) charset;
      var cs = res.headers.contentType!.charset!.toLowerCase();
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

    if (res.statusCode == 200 && writeCache) setCache(id, r, ttl);
    return r;
  }
}
