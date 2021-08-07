import 'dart:convert';
import 'package:universal_io/io.dart';

import 'dart:typed_data';

class ScHttpClient {
  final _client = HttpClient();
  String? Function(String) getCache;
  void Function(String, String, Duration) setCache;
  Uint8List? Function(String) getBinCache;
  void Function(String, Uint8List, Duration) setBinCache;
  bool forceCache, forceBinCache;

  ScHttpClient({
    this.getCache = _getCacheDmy,
    this.setCache = _setCacheDmy,
    this.getBinCache = _getBinCacheDmy,
    this.setBinCache = _setCacheDmy,
    this.forceCache = false,
    this.forceBinCache = false,
    String? userAgent,
    String Function(Uri)? findProxy,
  }) {
    if (userAgent != null) _client.userAgent = userAgent;
    if (findProxy != null) _client.findProxy = findProxy;
  }

  static String? _getCacheDmy(_) => null;
  static Uint8List? _getBinCacheDmy(_) => null;
  static void _setCacheDmy(_, __, ___) {}

  //TODO: this a very bad api and really has to be changed in the next major
  Future<String> post(
    String url,
    Object body,
    String id,
    Map<String, String> headers, {
    bool readCache = true,
    bool writeCache = true,
    Duration? ttl,
    String Function(List<int>)? defaultCharset,
    String Function(List<int>)? forcedCharset,
  }) =>
      _post(Uri.parse(url), body, id, headers, readCache, writeCache, ttl,
          defaultCharset, forcedCharset);

  Future<String> postUri(
    Uri url,
    Object body,
    String id,
    Map<String, String> headers, {
    bool readCache = true,
    bool writeCache = true,
    Duration? ttl,
    String Function(List<int>)? defaultCharset,
    String Function(List<int>)? forcedCharset,
  }) =>
      _post(url, body, id, headers, readCache, writeCache, ttl, defaultCharset,
          forcedCharset);

  Future<String> get(
    String url, {
    bool readCache = true,
    bool writeCache = true,
    Duration? ttl,
    Map<String, String> headers = const {},
    String Function(List<int>)? defaultCharset,
    String Function(List<int>)? forcedCharset,
  }) =>
      _get(Uri.parse(url), url, headers, readCache, writeCache, ttl,
          defaultCharset, forcedCharset);

  Future<String> getUri(
    Uri url, {
    bool readCache = true,
    bool writeCache = true,
    Duration? ttl,
    Map<String, String> headers = const {},
    String Function(List<int>)? defaultCharset,
    String Function(List<int>)? forcedCharset,
  }) =>
      _get(url, '$url', headers, readCache, writeCache, ttl, defaultCharset,
          forcedCharset);

  Future<String> _post(
    Uri url,
    Object body,
    String id,
    Map<String, String> headers,
    bool readCache,
    bool writeCache,
    Duration? ttl,
    String Function(List<int>)? defaultCharset,
    String Function(List<int>)? forcedCharset,
  ) async {
    final cachedResp = (readCache || forceCache) ? getCache(id) : null;
    if (cachedResp != null) return cachedResp;
    final req = await _client.postUrl(url);
    headers.forEach((k, v) => req.headers.add(k, v));
    req.writeln(body);
    return _finishRequest(req, id, writeCache, ttl ?? Duration(minutes: 15),
        defaultCharset, forcedCharset);
  }

  Future<String> _get(
    Uri url,
    String id,
    Map<String, String> headers,
    bool readCache,
    bool writeCache,
    Duration? ttl,
    String Function(List<int>)? defaultCharset,
    String Function(List<int>)? forcedCharset,
  ) async {
    final cachedResp = (readCache || forceCache) ? getCache(id) : null;
    if (cachedResp != null) return cachedResp;
    final req = await _client.getUrl(url);
    headers.forEach((k, v) => req.headers.add(k, v));
    return _finishRequest(req, id, writeCache, ttl ?? Duration(days: 4),
        defaultCharset, forcedCharset);
  }

  // TODO: turn on caching by default in next major
  Future<Uint8List> getBin(
    String url, {
    bool readCache = false,
    bool writeCache = false,
    Duration? ttl,
  }) =>
      _getBin(Uri.parse(url), url, readCache, writeCache, ttl);

  // TODO: turn on caching by default in next major
  Future<Uint8List> getBinUri(
    Uri url, {
    bool readCache = false,
    bool writeCache = false,
    Duration? ttl,
  }) async =>
      _getBin(url, url.toString(), readCache, writeCache, ttl);

  Future<Uint8List> _getBin(
    Uri url,
    String id,
    bool readCache,
    bool writeCache,
    Duration? ttl,
  ) async {
    final cachedResp = (readCache || forceBinCache) ? getBinCache(id) : null;
    if (cachedResp != null) return cachedResp;
    final req = await _client.getUrl(url);
    return _finishBin(req, id, writeCache, ttl ?? Duration(days: 4));
  }

  Future<Uint8List> _finishBin(
    HttpClientRequest req,
    String id,
    bool writeCache,
    Duration ttl,
  ) async {
    final res = await req.close();
    final b = await res.toList();
    final bin = Uint8List.fromList(b.reduce((v, e) => [...v, ...e]));
    if (res.statusCode == 200 && (writeCache || forceBinCache))
      setBinCache(id, bin, ttl);
    return bin;
  }

  Future<String> _finishRequest(
    HttpClientRequest req,
    String id,
    bool writeCache,
    Duration ttl,
    String Function(List<int>)? defaultCharset,
    String Function(List<int>)? forcedCharset,
  ) async {
    final res = await req.close();
    final b = await res.toList();
    final bytes = b.reduce((v, e) => [...v, ...e]);

    String r;
    if (forcedCharset != null)
      r = forcedCharset(bytes);
    else {
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
          charset = defaultCharset ?? utf8.decode;
        r = charset(bytes);
      } catch (e) {
        // TODO: in the next major this should probably be defaultCharset??utf8
        r = String.fromCharCodes(bytes);
      }
    }

    if (res.statusCode == 200 && (writeCache || forceCache))
      setCache(id, r, ttl);
    return r;
  }
}
