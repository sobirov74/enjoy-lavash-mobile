import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/core/storage/public_content_cache.dart';
import 'package:enjoy_lavash_mobile/core/storage/token_storage.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/repositories/mobile_backend_repository_impl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    TokenStorage.resetStorage();
    directory = Directory.systemTemp.createTempSync('public_content_repo');
  });

  tearDown(() {
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });

  File savedFile() => File('${directory.path}/${PublicContentCache.fileName}');

  MobileBackendRepositoryImpl repository({
    Map<String, Object?> catalog = _catalog,
    Set<String> failing = const <String>{},
    List<Object?>? banners,
  }) {
    return MobileBackendRepositoryImpl(
      ApiClient(
        baseUrl: 'https://api.example.test',
        httpClientAdapter: _Adapter(
          catalog: catalog,
          failing: failing,
          banners: banners,
        ),
      ),
      organisationId: 'org-1',
      publicContentCache: PublicContentCache(directory: () async => directory),
    );
  }

  test(
    'a bootstrap saves the public content and it reads back the same',
    () async {
      final first = repository();
      final bootstrap = (await first.bootstrap(language: 'ru')).dataOrNull!;
      await _waitFor(savedFile);

      final saved = await repository().readCachedPublicContent(language: 'ru');
      expect(saved, isNotNull);
      expect(
        saved!.catalog.products.map((product) => product.id),
        bootstrap.catalog.products.map((product) => product.id),
      );
      expect(saved.branches.map((branch) => branch.id), ['branch-1']);
      expect(saved.banners.single.imageUrl, bootstrap.banners.single.imageUrl);
      // Another language is not served from this content.
      expect(
        await repository().readCachedPublicContent(language: 'uz'),
        isNull,
      );
    },
  );

  test('customer data never reaches the saved file', () async {
    await TokenStorage.saveAccessToken('access');
    await TokenStorage.saveRefreshToken('refresh');

    final result = await repository().bootstrap(language: 'ru');
    expect(result.dataOrNull!.client!.fullName, 'Secret Customer');
    await _waitFor(savedFile);

    final saved = savedFile().readAsStringSync();
    expect(saved, isNot(contains('Secret Customer')));
    expect(saved, isNot(contains('+998901112233')));
    expect(saved, isNot(contains('Hidden street')));
    expect(saved, isNot(contains('order-private')));
    expect(saved, isNot(contains('access')));
  });

  test('a branch-specific bootstrap is not saved', () async {
    await repository().bootstrap(language: 'ru', branchId: 'branch-1');
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(savedFile().existsSync(), isFalse);
  });

  test('nothing is saved when the catalog request fails', () async {
    final result = await repository(
      failing: {'/catalog'},
    ).bootstrap(language: 'ru');
    expect(result.isSuccess, isFalse);
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(savedFile().existsSync(), isFalse);
  });

  test(
    'an answer with nothing to order never replaces a good saved menu',
    () async {
      await repository().bootstrap(language: 'ru');
      await _waitFor(savedFile);
      final good = savedFile().readAsStringSync();

      // An empty menu, and a body that is not a menu at all (a captive
      // portal page answers 200 too).
      await repository(catalog: _emptyCatalog).bootstrap(language: 'ru');
      await repository(
        catalog: const {'html': '<html>'},
      ).bootstrap(language: 'ru');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(savedFile().readAsStringSync(), good);
      final saved = await repository().readCachedPublicContent(language: 'ru');
      expect(saved!.catalog.products, isNotEmpty);
    },
  );

  test('the public promotions list is no longer requested or saved', () async {
    final adapter = _Adapter(catalog: _catalog, failing: const <String>{});
    final repo = MobileBackendRepositoryImpl(
      ApiClient(
        baseUrl: 'https://api.example.test',
        httpClientAdapter: adapter,
      ),
      organisationId: 'org-1',
      publicContentCache: PublicContentCache(directory: () async => directory),
    );

    await repo.bootstrap(language: 'ru');
    await _waitFor(savedFile);

    expect(adapter.paths, isNot(contains('/promotions/active')));
    expect(savedFile().readAsStringSync(), isNot(contains('promotions')));
  });

  test('a saved banner whose promotion has ended is not shown', () async {
    final ended = DateTime.now().subtract(const Duration(days: 1));
    final running = DateTime.now().add(const Duration(days: 1));
    await repository(
      banners: [
        {
          'id': 'ended',
          'imageUrl': '/uploads/banners/ended.jpg',
          'promotion': {'id': 'p-ended', 'endsAt': ended.toIso8601String()},
        },
        {
          'id': 'running',
          'imageUrl': '/uploads/banners/running.jpg',
          'promotion': {'id': 'p-running', 'endsAt': running.toIso8601String()},
        },
        {'id': 'plain', 'imageUrl': '/uploads/banners/plain.jpg'},
      ],
    ).bootstrap(language: 'ru');
    await _waitFor(savedFile);

    final saved = await repository().readCachedPublicContent(language: 'ru');

    expect(saved!.banners.map((banner) => banner.id), ['running', 'plain']);
  });
}

Future<void> _waitFor(File Function() file) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (file().existsSync()) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail('the public content was not saved');
}

const Map<String, Object?> _catalog = <String, Object?>{
  'categories': <Object?>[
    <String, Object?>{
      'id': 'cat-lavash',
      'name': 'Лаваш',
      'isActive': true,
      'products': <Object?>[
        <String, Object?>{
          'id': 'lavash',
          'name': 'Лаваш',
          'basePrice': 30000,
          'image': '/uploads/products/lavash.jpg',
        },
        <String, Object?>{'id': 'burger', 'name': 'Бургер', 'basePrice': 40000},
      ],
    },
  ],
};

const Map<String, Object?> _emptyCatalog = <String, Object?>{
  'categories': <Object?>[
    <String, Object?>{
      'id': 'cat-lavash',
      'name': 'Лаваш',
      'isActive': true,
      'products': <Object?>[
        <String, Object?>{
          'id': 'gone',
          'name': 'Gone',
          'basePrice': 1,
          'isAvailable': false,
        },
      ],
    },
  ],
};

class _Adapter implements HttpClientAdapter {
  _Adapter({required this.catalog, required this.failing, this.banners});

  final Map<String, Object?> catalog;
  final Set<String> failing;
  final List<Object?>? banners;
  final List<String> paths = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.uri.path;
    paths.add(path);
    if (failing.contains(path)) return _json({'message': 'down'}, status: 503);
    return switch (path) {
      '/catalog' => _json(catalog),
      '/branches' => _json({
        'branches': [
          {'id': 'branch-1', 'name': 'Chilonzor', 'isActive': true},
        ],
      }),
      '/banners/active' when banners != null => _json(banners),
      '/banners/active' => _json([
        {
          'id': 'banner-1',
          'titleI18n': {'ru': 'Акция'},
          'imageUrl': '/uploads/banners/banner-1.jpg',
        },
      ]),
      '/payment-methods' => _json({'paymentMethods': <Object?>[]}),
      '/clients/me' => _json({
        'id': 'client-1',
        'fullName': 'Secret Customer',
        'phoneNumber': '+998901112233',
        'language': 'ru',
      }),
      '/clients/me/addresses' => _json({
        'addresses': [
          {
            'id': 'address-1',
            'label': 'Home',
            'street': 'Hidden street',
            'latitude': 41.3,
            'longitude': 69.2,
            'isDefault': true,
          },
        ],
      }),
      '/clients/me/orders' => _json({
        'orders': [
          {
            'id': 'order-private',
            'type': 'PICKUP',
            'status': 'NEW',
            'paymentMethod': 'CASH',
            'totalAmount': 30000,
            'items': <Object?>[],
            'statusLog': <Object?>[],
          },
        ],
      }),
      _ => _json({'message': 'not found'}, status: 404),
    };
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object? data, {int status = 200}) {
  return ResponseBody.fromString(
    jsonEncode(data),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}
