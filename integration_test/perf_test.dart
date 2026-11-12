// Offline, repeatable performance scenarios for docs/PERFORMANCE_PASS_2.md.
//
// The real app (MyApp, repository, controllers) runs against an in-memory
// fixture server and generated photos, so runs are comparable and never touch
// the network, the keychain or the saved cart of an installed app.
//
// Frame timings (profile mode, Android). `-P perfBuild=true` builds the app as
// `…enjoy_lavash_mobile.perf`, next to the store app:
//   flutter build apk --profile -P perfBuild=true \
//     --target=integration_test/perf_test.dart
//   PERF_TAG=<label>-profile flutter drive --profile \
//     --use-application-binary=build/app/outputs/flutter-apk/app-profile.apk \
//     --driver=test_driver/perf_driver.dart \
//     --target=integration_test/perf_test.dart -d <device-id>
// Always pass the prebuilt APK: without it `flutter drive` uninstalls the
// plain `com.aurumdev.enjoy_lavash_mobile` (the store app) when it finishes.
// Widget rebuild counts: the same with --debug and app-debug.apk.
// Results are written to build/perf/perf_<label>.json.

import 'dart:convert';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:enjoy_lavash_mobile/app/app.dart';
import 'package:enjoy_lavash_mobile/app/locale_controller.dart';
import 'package:enjoy_lavash_mobile/app/location_controller.dart';
import 'package:enjoy_lavash_mobile/app/theme_controller.dart';
import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/services/mobile_push_notification_service.dart';
import 'package:enjoy_lavash_mobile/core/services/yandex_geocoder_service.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/repositories/mobile_backend_repository_impl.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:enjoy_lavash_mobile/widgets/product_image.dart';
import 'package:enjoy_lavash_mobile/widgets/utils/cached_image_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _fixtureBaseUrl = 'https://perf.fixture';
const List<String> _categoryNames = <String>[
  'Lavash',
  'Shawarma',
  'Burger',
  'Pizza',
  'Salad',
  'Drinks',
];
const int _productsPerCategory = 10;

/// Widget types whose rebuilds are reported per scenario (debug runs).
const Set<String> _trackedTypes = <String>{
  'HomeScreen',
  'MenuScreen',
  'ProductListItem',
  'CartScreen',
  'Profile',
  'AssignedPromotionsScreen',
};

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Real vsync frames, as on a device, rather than only explicitly pumped ones.
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('menu, cart and tab scenarios', (tester) async {
    binding.reportData = <String, dynamic>{};
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    final photos = await _Photos.generate();
    networkImageProvider = photos.provider;

    final apiClient = ApiClient(
      baseUrl: _fixtureBaseUrl,
      httpClientAdapter: const _FixtureAdapter(),
    );
    final backend = MobileBackendController(
      MobileBackendRepositoryImpl(apiClient),
      MobilePushNotificationService(apiClient),
    );
    final localeController = LocaleController();
    await localeController.loadLocale();
    final themeController = ThemeController();
    final locationController = LocationController(YandexGeocoderService());
    apiClient.setLanguage(localeController.locale.languageCode);
    await backend.bootstrap(language: localeController.locale.languageCode);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeController>.value(value: themeController),
          ChangeNotifierProvider<LocaleController>.value(
            value: localeController,
          ),
          ChangeNotifierProvider<LocationController>.value(
            value: locationController,
          ),
          ChangeNotifierProvider<MobileBackendController>.value(value: backend),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    Finder tab(int index) => find.byKey(ValueKey<String>('main-tab-$index'));
    Future<void> tapAndSettle(Finder finder) async {
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    Future<void> fling(Offset from, Offset by, double speed) async {
      await tester.flingFrom(from, by, speed);
      await tester.pumpAndSettle();
    }

    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    final gridPoint = Offset(screen.width / 2, screen.height * 0.62);

    await _scenario(tester, binding, 'tab_switch', () async {
      for (final index in const <int>[1, 3, 4, 0, 1, 0]) {
        await tapAndSettle(tab(index));
      }
      // Swipes avoid the Home banner and category strips and the guest-only
      // Promotions tab: Menu → Home, then Cart ↔ Profile.
      await tapAndSettle(tab(1));
      await fling(gridPoint, const Offset(320, 0), 1500);
      await tapAndSettle(tab(3));
      await fling(gridPoint, const Offset(-320, 0), 1500);
      await fling(gridPoint, const Offset(320, 0), 1500);
    });

    await tapAndSettle(tab(1));

    await _scenario(tester, binding, 'menu_scroll', () async {
      for (var i = 0; i < 3; i++) {
        await fling(gridPoint, const Offset(0, -600), 3000);
      }
      for (var i = 0; i < 3; i++) {
        await fling(gridPoint, const Offset(0, 600), 3000);
      }
    });
    // Decoded photo memory after the whole menu has been on screen once.
    final imageCache = PaintingBinding.instance.imageCache;
    binding.reportData!['image_cache_after_menu_scroll'] = <String, int>{
      'bytes': imageCache.currentSizeBytes,
      'images': imageCache.currentSize,
      'live_images': imageCache.liveImageCount,
    };

    await _scenario(tester, binding, 'category_switch', () async {
      for (final index in const <int>[0, 1, 2, -1]) {
        final label = find.byKey(
          ValueKey<String>('menu-category-label-$index'),
        );
        await tester.ensureVisible(label);
        await tapAndSettle(label);
      }
    });

    Finder card(String id) => find.byKey(ValueKey<String>('menu-$id'));

    await _scenario(tester, binding, 'add_to_cart', () async {
      for (final id in const <String>[
        'p-0-0',
        'p-0-1',
        'p-0-2',
        'p-0-0',
        'p-0-1',
      ]) {
        await tapAndSettle(
          find
              .descendant(
                of: card(id),
                matching: find.byIcon(Icons.add_rounded),
              )
              .first,
        );
      }
    });

    await _scenario(tester, binding, 'product_detail', () async {
      for (final id in const <String>['p-0-0', 'p-0-1', 'p-0-2']) {
        await tapAndSettle(
          find.descendant(of: card(id), matching: find.byType(ProductImage)),
        );
        await tapAndSettle(find.byIcon(Icons.close_rounded).last);
      }
    });
  });
}

Future<void> _scenario(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  String name,
  Future<void> Function() body,
) async {
  final rebuilds = <String, int>{};
  var total = 0;
  if (kDebugMode) {
    debugOnRebuildDirtyWidget = (element, _) {
      total++;
      final type = element.widget.runtimeType.toString();
      if (_trackedTypes.contains(type)) {
        rebuilds.update(type, (count) => count + 1, ifAbsent: () => 1);
      }
    };
  }
  // Same summary as `binding.watchPerformance`, without its garbage-collection
  // count: that needs the app to connect to its own VM service, which fails
  // on Android ("Failed to connect to VM Service at ws://localhost…").
  final timings = <ui.FrameTiming>[];
  void collect(List<ui.FrameTiming> batch) => timings.addAll(batch);
  // The engine reports frame timings in batches, at most about once a second:
  // wait so earlier frames are not counted, and so this scenario's arrive.
  await Future<void>.delayed(const Duration(seconds: 2));
  SchedulerBinding.instance.addTimingsCallback(collect);
  try {
    await body();
    await Future<void>.delayed(const Duration(seconds: 2));
  } finally {
    SchedulerBinding.instance.removeTimingsCallback(collect);
    debugOnRebuildDirtyWidget = null;
  }
  binding.reportData![name] = timings.isEmpty
      ? <String, Object>{'frame_count': 0}
      : FrameTimingSummarizer(timings).summary;
  if (kDebugMode) {
    binding.reportData!['${name}_rebuilds'] = <String, int>{
      'total': total,
      for (final type in _trackedTypes) type: rebuilds[type] ?? 0,
    };
  }
}

/// Generated photos, one distinct byte buffer per URL so every product is
/// decoded and cached separately, as with real photos.
class _Photos {
  _Photos(this._bases);

  final List<Uint8List> _bases;
  final Map<String, Uint8List> _byUrl = <String, Uint8List>{};

  static Future<_Photos> generate() async {
    const pixels = 720;
    const side = 720.0;
    const colors = <Color>[
      Color(0xFFE5793B),
      Color(0xFFC2452D),
      Color(0xFF8D5A2B),
      Color(0xFFE0A526),
      Color(0xFF3E7C4F),
      Color(0xFF3A6EA5),
    ];
    final bases = <Uint8List>[];
    for (var i = 0; i < colors.length; i++) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const extent = Offset(side, side);
      canvas.drawRect(
        Offset.zero & const Size(side, side),
        Paint()
          ..shader = ui.Gradient.linear(Offset.zero, extent, <Color>[
            colors[i],
            const Color(0xFFFFF4E6),
          ]),
      );
      canvas.drawCircle(
        extent / 2,
        side * 0.32,
        Paint()..color = colors[(i + 2) % colors.length],
      );
      final image = await recorder.endRecording().toImage(pixels, pixels);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      bases.add(data!.buffer.asUint8List());
    }
    return _Photos(bases);
  }

  ImageProvider<Object> provider(String url) {
    final bytes = _byUrl.putIfAbsent(
      url,
      () => Uint8List.fromList(_bases[url.hashCode.abs() % _bases.length]),
    );
    return MemoryImage(bytes);
  }
}

class _FixtureAdapter implements HttpClientAdapter {
  const _FixtureAdapter();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = switch (options.uri.path) {
      '/catalog' => _catalog(),
      '/branches' => <String, Object?>{
        'branches': <Object?>[
          <String, Object?>{
            'id': 'branch-1',
            'name': 'Chilonzor',
            'address': 'Bunyodkor 1',
            'isActive': true,
          },
          <String, Object?>{
            'id': 'branch-2',
            'name': 'Yunusobod',
            'address': 'Amir Temur 100',
            'isActive': true,
          },
        ],
      },
      '/banners/active' => <Object?>[
        for (var i = 0; i < 3; i++)
          <String, Object?>{
            'id': 'banner-$i',
            'titleI18n': <String, String>{
              'uz': 'Aksiya $i',
              'ru': 'Акция $i',
              'en': 'Offer $i',
            },
            'imageUrl': '/uploads/banners/banner-$i.jpg',
          },
      ],
      '/promotions/active' => <String, Object?>{'promotions': <Object?>[]},
      '/payment-methods' => <String, Object?>{'paymentMethods': <Object?>[]},
      _ => null,
    };
    final headers = <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    };
    if (body == null) {
      return ResponseBody.fromString(
        '{"message":"not found"}',
        404,
        headers: headers,
      );
    }
    return ResponseBody.fromString(jsonEncode(body), 200, headers: headers);
  }

  @override
  void close({bool force = false}) {}
}

Map<String, Object?> _catalog() => <String, Object?>{
  'categories': <Object?>[
    for (var c = 0; c < _categoryNames.length; c++)
      <String, Object?>{
        'id': 'cat-$c',
        'name': _categoryNames[c],
        'sortOrder': c,
        'isActive': true,
        'products': <Object?>[
          for (var p = 0; p < _productsPerCategory; p++)
            <String, Object?>{
              'id': 'p-$c-$p',
              'name': '${_categoryNames[c]} ${p + 1}',
              'description':
                  'Fixture product with a description long enough to '
                  'wrap onto a second line, like the real catalog',
              'image': '/uploads/products/p-$c-$p.jpg',
              'basePrice': 25000 + p * 3000,
              'calories': 400 + p * 20,
              'weightGrams': 250 + p * 10,
              'isAvailable': true,
              if (p % 4 == 3)
                'modifierGroups': <Object?>[
                  <String, Object?>{
                    'id': 'group-$c-$p',
                    'name': 'Extras',
                    'minSelect': 0,
                    'maxSelect': 2,
                    'modifiers': <Object?>[
                      <String, Object?>{
                        'id': 'mod-$c-$p-cheese',
                        'name': 'Cheese',
                        'price': 3000,
                      },
                      <String, Object?>{
                        'id': 'mod-$c-$p-sauce',
                        'name': 'Sauce',
                        'price': 2000,
                      },
                    ],
                  },
                ],
            },
        ],
      },
  ],
};
