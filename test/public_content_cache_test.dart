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
    banners: <Object?>[],
  );

  test('reads back exactly what was written', () async {
    await cache().write(scope: 'api|org', language: 'ru', payloads: payloads);

    final read = await cache().read(scope: 'api|org', language: 'ru');
    expect(read, isNotNull);
    expect(read!.catalog, payloads.catalog);
    expect(read.branches, payloads.branches);
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

  test('content saved "in the future" is a miss', () async {
    // The clock was wrong when it was saved (or is wrong now): without this
    // such content would never expire.
    await cache().write(scope: 'api|org', language: 'ru', payloads: payloads);
    now = now.subtract(const Duration(days: 2));

    expect(await cache().read(scope: 'api|org', language: 'ru'), isNull);
  });

  test('a file left by a killed save is replaced, not piled up', () async {
    final leftover = File(
      '${directory.path}/${PublicContentCache.temporaryFileName}',
    )..writeAsStringSync('{"half": ');

    await cache().write(scope: 'api|org', language: 'ru', payloads: payloads);

    expect(leftover.existsSync(), isFalse);
    expect(directory.listSync().map((entry) => entry.path), [file().path]);
    expect(await cache().read(scope: 'api|org', language: 'ru'), isNotNull);
  });

  test('saves that overlap leave one good file', () async {
    final shared = cache();
    await Future.wait([
      for (final language in ['ru', 'uz', 'en'])
        shared.write(scope: 'api|org', language: language, payloads: payloads),
    ]);

    expect(directory.listSync().map((entry) => entry.path), [file().path]);
    // The last one asked for wins.
    expect(await shared.read(scope: 'api|org', language: 'en'), isNotNull);
  });

  test('an unavailable directory never throws', () async {
    final broken = PublicContentCache(
      directory: () async => throw const FileSystemException('no cache dir'),
    );

    await broken.write(scope: 'api|org', language: 'ru', payloads: payloads);
    expect(await broken.read(scope: 'api|org', language: 'ru'), isNull);
  });
}
