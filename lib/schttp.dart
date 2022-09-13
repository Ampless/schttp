import 'dart:convert';
import 'package:bom/bom.dart';
import 'package:universal_io/io.dart';

import 'dart:typed_data';

String? _getCacheDmy(_) => null;
String? _getPostCacheDmy(_, __) => null;
Uint8List? _getBinCacheDmy(_) => null;
void _setCacheDmy(_, __, ___) {}
void _setPostCacheDmy(_, __, ___, ____) {}

// TODO: can we just extend HttpClient? (we probably cant)
class ScHttpClient {
  final _client = HttpClient();
  String? Function(Uri) getCache;
  void Function(Uri, String, Duration?) setCache;
  String? Function(Uri, Object) getPostCache;
  void Function(Uri, Object, String, Duration?) setPostCache;
  Uint8List? Function(Uri) getBinCache;
  void Function(Uri, Uint8List, Duration?) setBinCache;

  ScHttpClient({
    this.getCache = _getCacheDmy,
    this.setCache = _setCacheDmy,
    this.getPostCache = _getPostCacheDmy,
    this.setPostCache = _setPostCacheDmy,
    this.getBinCache = _getBinCacheDmy,
    this.setBinCache = _setCacheDmy,
    String? userAgent,
    String Function(Uri)? findProxy,
  }) {
    if (userAgent != null) _client.userAgent = userAgent;
    if (findProxy != null) _client.findProxy = findProxy;
  }

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
      postUri(Uri.parse(url), body,
          headers: headers,
          readCache: readCache,
          writeCache: writeCache,
          ttl: ttl,
          defaultCharset: defaultCharset,
          forcedCharset: forcedCharset);

  Future<String> postUri(
    Uri url,
    Object body, {
    Map<String, String> headers = const {},
    bool readCache = true,
    bool writeCache = true,
    Duration? ttl,
    String Function(List<int>)? defaultCharset,
    String Function(List<int>)? forcedCharset,
  }) async {
    final cachedResp = readCache ? getPostCache(url, body) : null;
    if (cachedResp != null) return cachedResp;
    final req = await _client.postUrl(url);
    headers.forEach((k, v) => req.headers.add(k, v));
    req.writeln(body);
    return _finishRequest(req, writeCache, defaultCharset, forcedCharset,
        (r) => setPostCache(url, body, r, ttl));
  }

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
    final cachedResp = readCache ? getCache(url) : null;
    if (cachedResp != null) return cachedResp;
    final req = await _client.getUrl(url);
    headers.forEach((k, v) => req.headers.add(k, v));
    return _finishRequest(req, writeCache, defaultCharset, forcedCharset,
        (r) => setCache(url, r, ttl));
  }

  Future<Uint8List> getBin(
    String url, {
    bool readCache = true,
    bool writeCache = true,
    Duration? ttl,
    Map<String, String> headers = const {},
  }) =>
      getBinUri(Uri.parse(url),
          readCache: readCache,
          writeCache: writeCache,
          ttl: ttl,
          headers: headers);

  Future<Uint8List> getBinUri(
    Uri url, {
    bool readCache = true,
    bool writeCache = true,
    Duration? ttl,
    Map<String, String> headers = const {},
  }) async {
    final cachedResp = readCache ? getBinCache(url) : null;
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
    if (res.statusCode == 200 && writeCache) setBinCache(url, bin, ttl);
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

    String r = (forcedCharset ??
        {
          // TODO: support more of these:
          // https://www.iana.org/assignments/character-sets/character-sets.xhtml
          // (or just look at what package:http is doing)
          'utf8': utf8,
          'us': ascii,
          'usascii': ascii,
          'ascii': ascii,
          'latin1': latin1,
          'l1': latin1,
        }[res.headers.contentType?.charset?.toLowerCase().replaceAll('-', '')]
            ?.decode ??
        {
          // TODO: also support utf16/32/... here
          UnicodeEncoding.utf8: utf8,
        }[UnicodeEncoding.fromBom(bytes)]
            ?.decode ??
        defaultCharset ??
        utf8.decode)(bytes);

    if (res.statusCode == 200 && writeCache) setc(r);
    return r;
  }
}

class SCacheClient implements ScHttpClient {
  String? Function(Uri) getCache;
  String? Function(Uri, Object) getPostCache;
  Uint8List? Function(Uri) getBinCache;

  var setCache = _setCacheDmy,
      setPostCache = _setPostCacheDmy,
      setBinCache = _setCacheDmy;

  SCacheClient({
    this.getCache = _getCacheDmy,
    this.getPostCache = _getPostCacheDmy,
    this.getBinCache = _getBinCacheDmy,
  });

  HttpClient get _client => throw UnimplementedError();
  _finishBin(_, __, ___, ____) => throw UnimplementedError();
  _finishRequest(_, __, ___, ____, _____) => throw UnimplementedError();

  @override
  Future<String> get(String url,
          {readCache = true,
          writeCache = true,
          ttl,
          headers = const {},
          defaultCharset,
          forcedCharset}) async =>
      getUri(Uri.parse(url));

  @override
  Future<String> getUri(Uri url,
          {readCache = true,
          writeCache = true,
          ttl,
          headers = const {},
          defaultCharset,
          forcedCharset}) async =>
      getCache(url)!;

  @override
  Future<Uint8List> getBin(String url,
          {readCache = true, writeCache = true, ttl, headers = const {}}) =>
      getBinUri(Uri.parse(url));

  @override
  Future<Uint8List> getBinUri(Uri url,
          {readCache = true,
          writeCache = true,
          ttl,
          headers = const {}}) async =>
      getBinCache(url)!;

  @override
  Future<String> post(String url, Object body,
          {headers = const {},
          readCache = true,
          writeCache = true,
          ttl,
          defaultCharset,
          forcedCharset}) =>
      postUri(Uri.parse(url), body);

  @override
  Future<String> postUri(Uri url, Object body,
          {headers = const {},
          readCache = true,
          writeCache = true,
          ttl,
          defaultCharset,
          forcedCharset}) async =>
      getPostCache(url, body)!;
}
