import 'dart:convert';
import 'package:universal_io/io.dart';

import 'dart:typed_data';

class ScHttpClient {
  final _client = HttpClient();
  String? Function(Uri) getCache;
  void Function(Uri, String, Duration?) setCache;
  String? Function(Uri, Object) getPostCache;
  void Function(String, String, String, Duration?) setPostCache;
  Uint8List? Function(String) getBinCache;
  void Function(String, Uint8List, Duration?) setBinCache;
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
    return _finishRequest(
        url, req, writeCache, ttl, defaultCharset, forcedCharset);
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
    // TODO: fix
    return _finishRequest(
        url, req, writeCache, ttl, defaultCharset, forcedCharset);
  }

  Future<Uint8List> getBin(
    String url, {
    bool readCache = true,
    bool writeCache = true,
    Duration? ttl,
  }) =>
      _getBin(Uri.parse(url), url, readCache, writeCache, ttl);

  Future<Uint8List> getBinUri(
    Uri url, {
    bool readCache = true,
    bool writeCache = true,
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
    return _finishBin(req, id, writeCache, ttl);
  }

  Future<Uint8List> _finishBin(
    HttpClientRequest req,
    String id,
    bool writeCache,
    Duration? ttl,
  ) async {
    final res = await req.close();
    final b = await res.toList();
    final bin = Uint8List.fromList(b.reduce((v, e) => [...v, ...e]));
    if (res.statusCode == 200 && (writeCache || forceBinCache))
      setBinCache(id, bin, ttl);
    return bin;
  }

  Future<String> _finishRequest(
    Uri url,
    HttpClientRequest req,
    bool writeCache,
    Duration? ttl,
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
      } on Exception {}
      r = charset(bytes);
    }

    if (res.statusCode == 200 && (writeCache || forceCache))
      // TODO: this is what's wrong rn, it fucks posts up
      setCache(url, r, ttl);
    return r;
  }
}
