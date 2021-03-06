import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:sqlite3/open.dart';

import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:test/test.dart';

void main() {
  late DbCacheStore store;

  DynamicLibrary _openOnLinux() {
    final libFile = File('${Directory.current.path}/test/lib/libsqlite3.so');
    return DynamicLibrary.open(libFile.path);
  }

  DynamicLibrary _openOnWindows() {
    final libFile = File('${Directory.current.path}/test/lib/sqlite3.dll');
    return DynamicLibrary.open(libFile.path);
  }

  setUp(() async {
    open.overrideFor(OperatingSystem.linux, _openOnLinux);
    open.overrideFor(OperatingSystem.windows, _openOnWindows);
    store = DbCacheStore(databasePath: '${Directory.current.path}/test/data');
    await store.clean();
  });

  tearDown(() async {
    await store.close();
  });

  Future<void> _addFooResponse() {
    final resp = CacheResponse(
      cacheControl: null,
      content: utf8.encode('foo'),
      date: DateTime.now(),
      eTag: 'an etag',
      expires: null,
      headers: null,
      key: 'foo',
      lastModified: null,
      maxStale: null,
      priority: CachePriority.normal,
      responseDate: DateTime.now(),
      url: 'https://foo.com',
    );

    return store.set(resp);
  }

  group('DB store tests', () {
    test('Empty by default', () async {
      expect(await store.exists('foo'), isFalse);
    });

    test('Add item', () async {
      await _addFooResponse();

      expect(await store.exists('foo'), isTrue);
    });

    test('Get item', () async {
      await _addFooResponse();

      final resp = await store.get('foo');
      expect(resp, isNotNull);
      expect(resp?.key, 'foo');
      expect(resp?.url, 'https://foo.com');
      expect(resp?.eTag, 'an etag');
      expect(resp?.lastModified, isNull);
      expect(resp?.maxStale, isNull);
      expect(resp?.content, utf8.encode('foo'));
      expect(resp?.headers, isNull);
      expect(resp?.priority, CachePriority.normal);
    });

    test('Delete item', () async {
      await _addFooResponse();
      expect(await store.exists('foo'), isTrue);

      await store.delete('foo');
      expect(await store.exists('foo'), isFalse);
    });
  });
}
