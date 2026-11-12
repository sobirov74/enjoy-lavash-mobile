import 'dart:convert';
import 'dart:io';

import 'package:enjoy_lavash_mobile/core/storage/public_content_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late DateTime now;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('public_content_cache');
    now = DateTime.utc(2026, 11, 11, 12);
  });

  tearDown(() {
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });

  PublicContentCache cache() =>
      PublicContentCache(directory: () async => directory, clock: () => now);

  File file() => File('${directory.path}/${PublicContentCache.fileName}');

  const payloads = (
    catalog: <String, Object?>{'categories': <Object?>[]},
    branches: <Object?>[
      <String, Object?>{'id': 'branch-1'},
    ],
    promotions: null,
    banners: <Object?>[],
  );

  test('reads back exactly what was written', () async {
    await cache().write(scope: 'api|org', language: 'ru', payloads: payloads);

    final read = await cache().read(scope: 'api|org', language: 'ru');
    expect(read, isNotNull);
    expect(read!.catalog, payloads.catalog);
    expect(read.branches, payloads.branches);
    expect(read.promotions, isNull);
    expect(read.banners, isEmpty);
    // Written aside and renamed: no temporary file is left behind.
    expect(directory.listSync().map((entry) => entry.path), [file().path]);
  });

  test('another server, organisation or language is a miss', () async {
    await cache().write(scope: 'api|org', language: 'ru', payloads: payloads);

    expect(await cache().read(scope: 'other|org', language: 'ru'), isNull);
    expect(await cache().read(scope: 'api|org', language: 'uz'), isNull);
    // A miss does not delete the content for the right scope.
    expect(await cache().read(scope: 'api|org', language: 'ru'), isNotNull);
  });

  test('content older than two weeks is a miss', () async {
    await cache().write(scope: 'api|org', language: 'ru', payloads: payloads);
    now = now.add(PublicContentCache.maxAge + const Duration(minutes: 1));

    expect(await cache().read(scope: 'api|org', language: 'ru'), isNull);
  });

  test('another schema is a miss', () async {
    await cache().write(scope: 'api|org', language: 'ru', payloads: payloads);
    final document = jsonDecode(file().readAsStringSync()) as Map;
    file().writeAsStringSync(jsonEncode({...document, 'schema': 99}));

    expect(await cache().read(scope: 'api|org', language: 'ru'), isNull);
  });

  test('an unreadable file is a miss and is deleted', () async {
    file().writeAsStringSync('{not json');

    expect(await cache().read(scope: 'api|org', language: 'ru'), isNull);
    expect(file().existsSync(), isFalse);
  });

  test('an oversized file is a miss and is deleted', () async {
    file().writeAsBytesSync(
      List<int>.filled(PublicContentCache.maxBytes + 1, 32),
    );

    expect(await cache().read(scope: 'api|org', language: 'ru'), isNull);
    expect(file().existsSync(), isFalse);
  });

  test('an unavailable directory never throws', () async {
    final broken = PublicContentCache(
      directory: () async => throw const FileSystemException('no cache dir'),
    );

    await broken.write(scope: 'api|org', language: 'ru', payloads: payloads);
    expect(await broken.read(scope: 'api|org', language: 'ru'), isNull);
  });
}
