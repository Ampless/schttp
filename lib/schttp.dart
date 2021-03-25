import 'dart:convert';
import 'dart:io';

import 'dart:typed_data';

class ScHttpClient {
  final _client = HttpClient();
  String? Function(String) getCache;
  void Function(String, String, Duration) setCache;

  ScHttpClient({
    this.getCache = _getCacheDmy,
    this.setCache = _setCacheDmy,
    String? userAgent,
    String Function(Uri)? findProxy,
  }) {
    if (userAgent != null) _client.userAgent = userAgent;
    if (findProxy != null) _client.findProxy = findProxy;
  }

  static String? _getCacheDmy(String _) => null;
  static void _setCacheDmy(String _, String __, Duration ___) {}

  Future<String> post(
    String url,
    Object body,
    String id,
    Map<String, String> headers, {
    bool readCache = true,
    bool writeCache = true,
    Duration? ttl,
  }) =>
      _post(Uri.parse(url), body, id, headers, readCache, writeCache, ttl);

  Future<String> postUri(
    Uri url,
    Object body,
    String id,
    Map<String, String> headers, {
    bool readCache = true,
    bool writeCache = true,
    Duration? ttl,
  }) =>
      _post(url, body, id, headers, readCache, writeCache, ttl);

  Future<String> get(
    String url, {
    bool readCache = true,
    bool writeCache = true,
    Duration? ttl,
  }) =>
      _get(Uri.parse(url), url, readCache, writeCache, ttl);

  Future<String> getUri(
    Uri url, {
    bool readCache = true,
    bool writeCache = true,
    Duration? ttl,
  }) =>
      _get(url, '$url', readCache, writeCache, ttl);

  Future<String> _post(
    Uri url,
    Object body,
    String id,
    Map<String, String> headers,
    bool readCache,
    bool writeCache,
    Duration? ttl,
  ) async {
    final cachedResp = readCache ? getCache(id) : null;
    if (cachedResp != null) return cachedResp;
    final req = await _client.postUrl(url);
    headers.forEach((k, v) => req.headers.add(k, v));
    req.writeln(body);
    return _finishRequest(req, id, writeCache, ttl ?? Duration(minutes: 15));
  }

  Future<String> _get(
    Uri url,
    String strurl,
    bool readCache,
    bool writeCache,
    Duration? ttl,
  ) async =>
      (readCache ? getCache(strurl) : null) ??
      await _finishRequest(
        await _client.getUrl(url),
        strurl,
        writeCache,
        ttl ?? Duration(days: 4),
      );

  Future<Uint8List> getBin(String url) => getBinUri(Uri.parse(url));

  Future<Uint8List> getBinUri(Uri url) async =>
      _finishBin(await _client.getUrl(url));

  Future<Uint8List> _finishBin(HttpClientRequest req) async {
    final res = await req.close();
    final b = await res.toList();
    return Uint8List.fromList(b.reduce((value, element) {
      value.addAll(element);
      return value;
    }));
  }

  Future<String> _finishRequest(
    HttpClientRequest req,
    String id,
    bool writeCache,
    Duration ttl,
  ) async {
    final res = await req.close();
    final b = await res.toList();
    final bytes = b.reduce((value, element) {
      value.addAll(element);
      return value;
    });

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
      r = charset(bytes);
    } catch (e) {
      r = String.fromCharCodes(bytes);
    }

    if (res.statusCode == 200 && writeCache) setCache(id, r, ttl);
    return r;
  }
}
