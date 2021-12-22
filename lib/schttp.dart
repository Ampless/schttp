import 'dart:convert';
import 'package:universal_io/io.dart';

import 'dart:typed_data';

class ScHttpClient {
  final _client = HttpClient();
  String? Function(Uri) getCache;
  void Function(Uri, String, Duration?) setCache;
  String? Function(Uri, Object) getPostCache;
  void Function(Uri, Object, String, Duration?) setPostCache;
  Uint8List? Function(Uri) getBinCache;
  void Function(Uri, Uint8List, Duration?) setBinCache;
  bool forceCache, forceBinCache;

  ScHttpClient({
    this.getCache = _getCacheDmy,
    this.setCache = _setCacheDmy,
    this.getPostCache = _getPostCacheDmy,
    this.setPostCache = _setPostCacheDmy,
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
  static String? _getPostCacheDmy(_, __) => null;
  static Uint8List? _getBinCacheDmy(_) => null;
  static void _setCacheDmy(_, __, ___) {}
  static void _setPostCacheDmy(_, __, ___, ____) {}

  Future<String> post(
    String url,
    Object body, {
    Map<String, String> headers = const {},
    bool readCache = true,
    bool writeCache = true,
    Duration? ttl,
    String Function(List<int>)? defaultCharset,
    String Function(List<int>)? forcedCharset,
  }) =>
      _post(Uri.parse(url), body, headers, readCache, writeCache, ttl,
          defaultCharset, forcedCharset);

  Future<String> postUri(
    Uri url,
    Object body, {
    Map<String, String> headers = const {},
    bool readCache = true,
    bool writeCache = true,
    Duration? ttl,
    String Function(List<int>)? defaultCharset,
    String Function(List<int>)? forcedCharset,
  }) =>
      _post(url, body, headers, readCache, writeCache, ttl, defaultCharset,
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
      getUri(Uri.parse(url),
          headers: headers,
          readCache: readCache,
          writeCache: writeCache,
          ttl: ttl,
          defaultCharset: defaultCharset,
          forcedCharset: forcedCharset);

  Future<String> getUri(
    Uri url, {
    bool readCache = true,
    bool writeCache = true,
    Duration? ttl,
    Map<String, String> headers = const {},
    String Function(List<int>)? defaultCharset,
    String Function(List<int>)? forcedCharset,
  }) async {
    final cachedResp = (readCache || forceCache) ? getCache(url) : null;
    if (cachedResp != null) return cachedResp;
    final req = await _client.getUrl(url);
    headers.forEach((k, v) => req.headers.add(k, v));
    return _finishRequest(req, writeCache, defaultCharset, forcedCharset,
        (r) => setCache(url, r, ttl));
  }

  Future<String> _post(
    Uri url,
    Object body,
    Map<String, String> headers,
    bool readCache,
    bool writeCache,
    Duration? ttl,
    String Function(List<int>)? defaultCharset,
    String Function(List<int>)? forcedCharset,
  ) async {
    final cachedResp =
        (readCache || forceCache) ? getPostCache(url, body) : null;
    if (cachedResp != null) return cachedResp;
    final req = await _client.postUrl(url);
    headers.forEach((k, v) => req.headers.add(k, v));
    req.writeln(body);
    return _finishRequest(req, writeCache, defaultCharset, forcedCharset,
        (r) => setPostCache(url, body, r, ttl));
  }

  Future<Uint8List> getBin(
    String url, {
    bool readCache = true,
    bool writeCache = true,
    Duration? ttl,
    Map<String, String> headers = const {},
  }) =>
      _getBin(Uri.parse(url), readCache, writeCache, ttl, headers);

  Future<Uint8List> getBinUri(
    Uri url, {
    bool readCache = true,
    bool writeCache = true,
    Duration? ttl,
    Map<String, String> headers = const {},
  }) async =>
      _getBin(url, readCache, writeCache, ttl, headers);

  Future<Uint8List> _getBin(
    Uri url,
    bool readCache,
    bool writeCache,
    Duration? ttl,
    Map<String, String> headers,
  ) async {
    final cachedResp = (readCache || forceBinCache) ? getBinCache(url) : null;
    if (cachedResp != null) return cachedResp;
    final req = await _client.getUrl(url);
    headers.forEach((k, v) => req.headers.add(k, v));
    return _finishBin(req, url, writeCache, ttl);
  }

  Future<Uint8List> _finishBin(
    HttpClientRequest req,
    Uri url,
    bool writeCache,
    Duration? ttl,
  ) async {
    final res = await req.close();
    final b = await res.toList();
    final bin = Uint8List.fromList(b.reduce((v, e) => [...v, ...e]));
    if (res.statusCode == 200 && (writeCache || forceBinCache))
      setBinCache(url, bin, ttl);
    return bin;
  }

  Future<String> _finishRequest(
    HttpClientRequest req,
    bool writeCache,
    String Function(List<int>)? defaultCharset,
    String Function(List<int>)? forcedCharset,
    void Function(String) setc,
  ) async {
    final res = await req.close();
    final b = await res.toList();
    final bytes = b.reduce((v, e) => [...v, ...e]);

    String r;
    if (forcedCharset != null)
      r = forcedCharset(bytes);
    else {
      String Function(List<int>) charset = defaultCharset ?? utf8.decode;
      try {
        charset = {
          'utf8': utf8,
          'us': ascii,
          'usascii': ascii,
          'ascii': ascii,
          'latin1': latin1,
          'l1': latin1,
        }[res.headers.contentType!.charset!.toLowerCase().replaceAll('-', '')]!
            .decode;
      } on Object {}
      r = charset(bytes);
    }

    if (res.statusCode == 200 && (writeCache || forceCache)) setc(r);
    return r;
  }
}
