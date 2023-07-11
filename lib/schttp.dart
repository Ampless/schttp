import 'dart:convert';
import 'package:bom/bom.dart';
import 'package:meta/meta.dart';
import 'package:universal_io/io.dart';

import 'dart:typed_data';

String? _getCacheDmy(_, __) => null;
String? _getPostCacheDmy(_, __, ___) => null;
Uint8List? _getBinCacheDmy(_, __) => null;
void _setCacheDmy(_, __, ___, ____) {}
void _setPostCacheDmy(_, __, ___, ____, _____) {}

class ScHttpClient {
  final _client = HttpClient();
  String? Function(Uri, Map<String, String>) getCache;
  void Function(Uri, Map<String, String>, String, Duration?) setCache;
  String? Function(Uri, Object, Map<String, String>) getPostCache;
  void Function(Uri, Object, Map<String, String>, String, Duration?)
      setPostCache;
  Uint8List? Function(Uri, Map<String, String>) getBinCache;
  void Function(Uri, Map<String, String>, Uint8List, Duration?) setBinCache;

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
    final cachedResp = readCache ? getPostCache(url, body, headers) : null;
    if (cachedResp != null) return cachedResp;
    final req = await _client.postUrl(url);
    headers.forEach(req.headers.set);
    return _finishRequest(req..writeln(body), writeCache, defaultCharset,
        forcedCharset, (r) => setPostCache(url, body, headers, r, ttl));
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
    final cachedResp = readCache ? getCache(url, headers) : null;
    if (cachedResp != null) return cachedResp;
    final req = await _client.getUrl(url);
    headers.forEach(req.headers.set);
    return _finishRequest(req, writeCache, defaultCharset, forcedCharset,
        (r) => setCache(url, headers, r, ttl));
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
    final cachedResp = readCache ? getBinCache(url, headers) : null;
    if (cachedResp != null) return cachedResp;
    final req = await _client.getUrl(url);
    headers.forEach(req.headers.set);
    return _finishBin(
        req, writeCache, (r) => setBinCache(url, headers, r, ttl));
  }

  Future<Uint8List> _finishBin(
    HttpClientRequest req,
    bool writeCache,
    void Function(Uint8List) setCache,
  ) async {
    final res = await req.close();
    final b = await res.toList();
    final bin = Uint8List.fromList(b.reduce((v, e) => v + e));
    if (res.statusCode == 200 && writeCache) setCache(bin);
    return bin;
  }

  Future<String> _finishRequest(
    HttpClientRequest req,
    bool writeCache,
    String Function(List<int>)? defaultCharset,
    String Function(List<int>)? forcedCharset,
    void Function(String) setCache,
  ) async {
    final res = await req.close();
    final bytes = await res.toList().then((b) => b.reduce((v, e) => v + e));

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
          // TODO: also support utf16/32/… here
          UnicodeEncoding.utf8: utf8,
        }[UnicodeEncoding.fromBom(bytes)]
            ?.decode ??
        defaultCharset ??
        utf8.decode)(bytes);

    if (res.statusCode == 200 && writeCache) setCache(r);
    return r;
  }
}

@sealed
class SCacheClient implements ScHttpClient {
  @override
  var getCache = _getCacheDmy,
      getPostCache = _getPostCacheDmy,
      getBinCache = _getBinCacheDmy,
      setCache = _setCacheDmy,
      setPostCache = _setPostCacheDmy,
      setBinCache = _setCacheDmy;

  SCacheClient({
    this.getCache = _getCacheDmy,
    this.getPostCache = _getPostCacheDmy,
    this.getBinCache = _getBinCacheDmy,
  });

  @override
  get _client => throw UnimplementedError();
  @override
  _finishBin(_, __, ___) => throw UnimplementedError();
  @override
  _finishRequest(_, __, ___, ____, _____) => throw UnimplementedError();

  @override
  Future<String> get(url,
          {readCache = true,
          writeCache = true,
          ttl,
          headers = const {},
          defaultCharset,
          forcedCharset}) async =>
      getUri(Uri.parse(url));

  @override
  Future<String> getUri(url,
          {readCache = true,
          writeCache = true,
          ttl,
          headers = const {},
          defaultCharset,
          forcedCharset}) async =>
      getCache(url, headers)!;

  @override
  Future<Uint8List> getBin(url,
          {readCache = true, writeCache = true, ttl, headers = const {}}) =>
      getBinUri(Uri.parse(url));

  @override
  Future<Uint8List> getBinUri(url,
          {readCache = true,
          writeCache = true,
          ttl,
          headers = const {}}) async =>
      getBinCache(url, headers)!;

  @override
  Future<String> post(url, body,
          {headers = const {},
          readCache = true,
          writeCache = true,
          ttl,
          defaultCharset,
          forcedCharset}) =>
      postUri(Uri.parse(url), body);

  @override
  Future<String> postUri(url, body,
          {headers = const {},
          readCache = true,
          writeCache = true,
          ttl,
          defaultCharset,
          forcedCharset}) async =>
      getPostCache(url, body, headers)!;
}
