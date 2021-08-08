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
