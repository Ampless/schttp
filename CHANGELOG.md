## 5.0.0-alpha.4

* Added `SCacheClient`
* Removed `forceCache` and `forceBinCache`; use `SCacheClient` instead
* Everything now uses `bom` to figure out the charset if it isn't provided directly

## 4.1.0

* Added support for custom `headers` to `getBin` and `getBinUri`

## 4.0.0

* A better API for `post` and `postUri`
* `readCache` and `writeCache` now default to `true` in `getBin` and `getBinUri`
* Missing `ttl`s now get passed onto the `get cache` functions, so you can
handle them yourself
* Added `getPostCache` and `setPostCache` to also outsource the id generation
* Adjusted the caching APIs to operate on `Uri`s instead of `String`s for urls
* Changed the charset matching behavior to make more sense for most use-cases

## 3.3.0

* `getBinCache`, `setBinCache` and `forceBinCache` for opt-in binary caching
* `defaultCharset` and `forcedCharset` for better charset matching
(useful for dealing with weird servers)

## 3.2.1

* Switched from `dart:io` to `universal_io` to support Web apps

## 3.2.0

* Added support for custom `headers` to `get` and `getUri`

## 3.1.0

* Added `forceCache` to force caching even though some library might not want you to

## 3.0.0

* Added support for Proxies and custom User Agents
* Made `getCache` and `setCache` named parameters instead of positional ones
* Added `getBin` and `getBinUri` for binary data

## 2.0.0

* Renamed `get` to `getUri`
* Renamed `post` to `postUri`
* Added `get`
* Added `post`

## 1.1.0

* Made `getCache` and `setCache` non-nullable (if this breaks your code, your code's wrong)
* Added readCache and writeCache parameters to disable caching dynamically

## 1.0.0-nullsafety.0

* Null-safety

## 0.2.0

* Support for using US-ASCII and Latin-1 when the server sends it.

## 0.1.0

* Initial release: copied from Amplessimus, can GET and POST text with caching
