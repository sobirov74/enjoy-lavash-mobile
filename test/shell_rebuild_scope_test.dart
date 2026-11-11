// Guards the shell's rebuild scope: tab switches, category taps, cart taps
// and backend notifications must rebuild only the widgets that show what
// changed. Counts come from `debugOnRebuildDirtyWidget` while an interaction
// runs.

import 'package:enjoy_lavash_mobile/app/app.dart';
import 'package:enjoy_lavash_mobile/app/locale_controller.dart';
import 'package:enjoy_lavash_mobile/app/location_controller.dart';
import 'package:enjoy_lavash_mobile/app/theme_controller.dart';
import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/error/failures.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/core/services/mobile_push_notification_service.dart';
import 'package:enjoy_lavash_mobile/core/services/yandex_geocoder_service.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/app_version_policy_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/client_profile_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/repositories/mobile_backend_repository_impl.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:enjoy_lavash_mobile/screens/home_screen.dart';
import 'package:enjoy_lavash_mobile/screens/menu_screen.dart';
import 'package:enjoy_lavash_mobile/widgets/product_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('a cart tap rebuilds the tapped card only, not the menu or '
      'Home', (tester) async {
    await _pumpShell(tester, _ShellController(ApiClient()));
    await _visit(tester, 1);

    final menuBefore = tester.widget<MenuScreen>(find.byType(MenuScreen));
    final rebuilds = await _rebuildsDuring(tester, () async {
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey<String>('menu-test-lavash')),
          matching: find.byIcon(Icons.add_rounded),
        ),
      );
      await tester.pumpAndSettle();
    });

    expect(rebuilds['ProductListItem'], 1);
    expect(rebuilds['MenuScreen'], isNull);
    expect(rebuilds['HomeScreen'], isNull);
    expect(
      identical(tester.widget<MenuScreen>(find.byType(MenuScreen)), menuBefore),
      isTrue,
    );
    expect(_card(tester, 'test-lavash').quantity, 1);
    expect(_card(tester, 'test-burger').quantity, 0);
  });

  testWidgets('switching tabs by tap or swipe builds no tab content', (
    tester,
  ) async {
    await _pumpShell(tester, _ShellController(ApiClient()));
    // Build every tab once; they stay alive afterwards.
    for (final tab in const <int>[1, 3, 4, 0]) {
      await _visit(tester, tab);
    }

    final rebuilds = await _rebuildsDuring(tester, () async {
      for (final tab in const <int>[1, 3, 4, 0, 1]) {
        await _visit(tester, tab);
      }
      await _visit(tester, 3);
      final pages = find.byKey(const ValueKey<String>('main-tabs-page-view'));
      await tester.fling(pages, const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
      await tester.fling(pages, const Offset(300, 0), 1000);
      await tester.pumpAndSettle();
    });

    for (final type in const <String>[
      'HomeScreen',
      'MenuScreen',
      'ProductListItem',
      'CartScreen',
      'Profile',
    ]) {
      expect(rebuilds[type], isNull, reason: '$type rebuilt on a tab switch');
    }
  });

  testWidgets('a category tap rebuilds the menu once and nothing else', (
    tester,
  ) async {
    await _pumpShell(tester, _ShellController(ApiClient()));
    await _visit(tester, 1);

    final rebuilds = await _rebuildsDuring(tester, () async {
      await tester.tap(
        find.byKey(const ValueKey<String>('menu-category-label-1')),
      );
      await tester.pumpAndSettle();
    });

    expect(rebuilds['MenuScreen'], 1);
    expect(rebuilds['HomeScreen'], isNull);
    expect(rebuilds['CartScreen'], isNull);
    expect(
      find.byKey(const ValueKey<String>('menu-test-lavash')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('menu-test-burger')),
      findsOneWidget,
    );
  });

  testWidgets('an unread-count change rebuilds Home but not the menu', (
    tester,
  ) async {
    final backend = _ShellController(ApiClient());
    await _pumpShell(tester, backend);
    await _visit(tester, 1);
    await _visit(tester, 0);

    final rebuilds = await _rebuildsDuring(tester, () async {
      backend.setUnreadCount(3);
      await tester.pump();
    });

    expect(rebuilds['HomeScreen'], 1);
    expect(rebuilds['MenuScreen'], isNull);
    expect(rebuilds['ProductListItem'], isNull);
    expect(rebuilds['CartScreen'], isNull);
  });

  testWidgets('a backend notification about nothing shown rebuilds no tab, '
      'the kept-alive Promotions tab included', (tester) async {
    final backend = _ShellController(ApiClient(), signedIn: true);
    await _pumpShell(tester, backend);
    for (final tab in const <int>[1, 2, 3, 4, 0]) {
      await _visit(tester, tab);
    }
    expect(find.byType(HomeScreen), findsOneWidget);

    final rebuilds = await _rebuildsDuring(tester, () async {
      backend.ping();
      await tester.pump();
    });

    for (final type in const <String>[
      'HomeScreen',
      'MenuScreen',
      'ProductListItem',
      'CartScreen',
      'Profile',
      'AssignedPromotionsScreen',
    ]) {
      expect(rebuilds[type], isNull, reason: '$type rebuilt on a no-op');
    }
  });
}

Future<void> _pumpShell(WidgetTester tester, _ShellController backend) async {
  SharedPreferences.setMockInitialValues({'app_locale': 'en'});
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final localeController = LocaleController();
  await localeController.loadLocale();
  addTearDown(localeController.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeController>(
          create: (_) => ThemeController(),
        ),
        ChangeNotifierProvider<LocaleController>.value(value: localeController),
        ChangeNotifierProvider<LocationController>(
          create: (_) => LocationController(YandexGeocoderService()),
        ),
        ChangeNotifierProvider<MobileBackendController>.value(value: backend),
      ],
      child: const MyApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _visit(WidgetTester tester, int tab) async {
  await tester.tap(find.byKey(ValueKey<String>('main-tab-$tab')));
  await tester.pumpAndSettle();
}

ProductListItem _card(WidgetTester tester, String productId) {
  return tester.widget<ProductListItem>(
    find.byKey(ValueKey<String>('menu-$productId')),
  );
}

/// Widget rebuilds by type while [action] runs.
Future<Map<String, int>> _rebuildsDuring(
  WidgetTester tester,
  Future<void> Function() action,
) async {
  final counts = <String, int>{};
  debugOnRebuildDirtyWidget = (element, _) {
    final type = element.widget.runtimeType.toString();
    counts[type] = (counts[type] ?? 0) + 1;
  };
  try {
    await action();
  } finally {
    debugOnRebuildDirtyWidget = null;
  }
  return counts;
}

class _ShellController extends MobileBackendController {
  _ShellController(ApiClient apiClient, {this.signedIn = false})
    : super(
        MobileBackendRepositoryImpl(apiClient),
        MobilePushNotificationService(apiClient),
      );

  final bool signedIn;
  int _unreadCount = 0;

  void ping() => notifyListeners();

  void setUnreadCount(int count) {
    _unreadCount = count;
    notifyListeners();
  }

  @override
  MobileBackendStatus get status => MobileBackendStatus.loaded;

  @override
  bool get isAuthenticated => signedIn;

  @override
  ClientProfile? get client => signedIn ? _client : null;

  @override
  int get notificationUnreadCount => _unreadCount;

  @override
  List<String> get menuCategories => const ['Lavash', 'Burger'];

  @override
  List<MenuProduct> get menuProducts => _products;

  @override
  Future<void> refreshPushNotificationSettings() async {}

  @override
  Future<Result<AppVersionPolicyModel>> getAppVersionPolicy({
    required String platform,
    String? currentVersion,
    String? language,
  }) async => const Error(NetworkFailure());
}

final ClientProfile _client = ClientProfile.fromJson(const {
  'id': 'client-1',
  'fullName': 'Ali Valiyev',
  'phoneNumber': '+998901234567',
  'language': 'en',
  'birthDate': '1990-05-01',
});

const List<MenuProduct> _products = <MenuProduct>[
  MenuProduct(
    id: 'test-lavash',
    title: 'Test lavash',
    price: 30000,
    category: 'Lavash',
    emoji: '🌯',
    tint: Colors.orange,
    highlight: Colors.amber,
  ),
  MenuProduct(
    id: 'test-burger',
    title: 'Test burger',
    price: 40000,
    category: 'Burger',
    emoji: '🍔',
    tint: Colors.orange,
    highlight: Colors.amber,
  ),
];
