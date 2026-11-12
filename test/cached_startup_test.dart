// Cold start with the menu saved by the last launch: it shows while the
// network loads, never overrides network data, never trims the cart, and
// signed-in actions wait for the session instead of asking to sign in.

import 'dart:async';
import 'dart:convert';

import 'package:enjoy_lavash_mobile/app/app.dart';
import 'package:enjoy_lavash_mobile/app/locale_controller.dart';
import 'package:enjoy_lavash_mobile/app/location_controller.dart';
import 'package:enjoy_lavash_mobile/app/theme_controller.dart';
import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/error/failures.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/core/services/mobile_push_notification_service.dart';
import 'package:enjoy_lavash_mobile/core/services/yandex_geocoder_service.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/catalog_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/client_notification_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/client_profile_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/entities/mobile_bootstrap.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/entities/mobile_public_content.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/repositories/mobile_backend_repository.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/screens/authorization_screen.dart';
import 'package:enjoy_lavash_mobile/screens/notifications_screen.dart';
import 'package:enjoy_lavash_mobile/widgets/notification_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final L _l10n = lookupL(const Locale('en'));

void main() {
  group('controller', () {
    test(
      'saved content shows while loading and the network replaces it',
      () async {
        final repository = _Repository(cached: _cachedContent);
        final backend = _controller(repository);

        unawaited(backend.bootstrap(language: 'en'));
        await backend.restoreCachedContent(language: 'en');

        expect(backend.status, MobileBackendStatus.loading);
        expect(backend.isShowingCachedContent, isTrue);
        expect(_ids(backend), <String>['both', 'cached-and-gone']);

        repository.bootstrapResult.complete(Success(_guestBootstrap));
        await backend.whenSessionSettled();

        expect(backend.status, MobileBackendStatus.loaded);
        expect(backend.isShowingCachedContent, isFalse);
        expect(_ids(backend), <String>['both', 'only-network']);
      },
    );

    test('a failed refresh keeps the saved content on screen', () async {
      final repository = _Repository(cached: _cachedContent);
      final backend = _controller(repository);

      unawaited(backend.bootstrap(language: 'en'));
      await backend.restoreCachedContent(language: 'en');
      repository.bootstrapResult.complete(const Error(NetworkFailure()));
      await backend.whenSessionSettled();

      expect(backend.status, MobileBackendStatus.error);
      expect(backend.failure, isA<NetworkFailure>());
      expect(backend.isShowingCachedContent, isTrue);
      expect(_ids(backend), <String>['both', 'cached-and-gone']);
    });

    test('saved content read after the network answered is ignored', () async {
      final repository = _Repository(cached: _cachedContent);
      final backend = _controller(repository);

      unawaited(backend.bootstrap(language: 'en'));
      repository.bootstrapResult.complete(Success(_guestBootstrap));
      await backend.whenSessionSettled();
      await backend.restoreCachedContent(language: 'en');

      expect(backend.isShowingCachedContent, isFalse);
      expect(_ids(backend), <String>['both', 'only-network']);
    });

    test('without saved content nothing changes', () async {
      final repository = _Repository(cached: null);
      final backend = _controller(repository);

      unawaited(backend.bootstrap(language: 'en'));
      await backend.restoreCachedContent(language: 'en');

      expect(backend.isShowingCachedContent, isFalse);
      expect(backend.menuProducts, isEmpty);
    });

    test('the session settles when the bootstrap ends', () async {
      final repository = _Repository(cached: _cachedContent);
      final backend = _controller(repository);
      var settled = false;

      await backend.whenSessionSettled();
      unawaited(backend.bootstrap(language: 'en'));
      unawaited(backend.whenSessionSettled().then((_) => settled = true));
      await Future<void>.delayed(Duration.zero);
      expect(settled, isFalse);

      repository.bootstrapResult.complete(Success(_signedInBootstrap));
      await Future<void>.delayed(Duration.zero);
      expect(settled, isTrue);
      expect(backend.isAuthenticated, isTrue);
    });
  });

  group('shell', () {
    testWidgets('the cart is reconciled against the network catalog only', (
      tester,
    ) async {
      final app = await _pumpWithSavedContent(
        tester,
        savedCart: const <Object?>[
          {'productId': 'only-network', 'quantity': 1},
          {'productId': 'cached-and-gone', 'quantity': 2},
          {'productId': 'both', 'quantity': 1},
        ],
      );

      // Nothing removed while the saved menu shows, even a product it lacks.
      expect(await _savedCartIds(), <String>[
        'only-network',
        'cached-and-gone',
        'both',
      ]);
      expect(find.textContaining('removed from your cart'), findsNothing);

      app.repository.bootstrapResult.complete(Success(_guestBootstrap));
      await tester.pumpAndSettle();

      // The network catalog decides, and the removed line is named.
      expect(
        find.text(_l10n.cartItemsUnavailable('Cached and gone')),
        findsOneWidget,
      );
      expect(await _savedCartIds(), <String>['only-network', 'both']);
    });

    testWidgets('Home holds the greeting back until the session is known', (
      tester,
    ) async {
      final app = await _pumpWithSavedContent(tester);

      expect(
        find.byKey(const ValueKey<String>('home-greeting-pending')),
        findsOneWidget,
      );
      expect(find.text(_l10n.homeGreeting(_l10n.guest)), findsNothing);
      // The saved menu's category is already on Home.
      expect(find.text('Lavash'), findsWidgets);

      app.repository.bootstrapResult.complete(Success(_signedInBootstrap));
      await tester.pumpAndSettle();

      expect(find.text(_l10n.homeGreeting('Ali')), findsOneWidget);
    });

    testWidgets('a signed-in action waits for the session instead of asking '
        'to sign in', (tester) async {
      final app = await _pumpWithSavedContent(tester);

      await tester.tap(find.byType(NotificationButton).first);
      await tester.pumpAndSettle();
      expect(find.byType(AuthorizationScreen), findsNothing);
      expect(find.byType(NotificationsScreen), findsNothing);

      app.repository.bootstrapResult.complete(Success(_signedInBootstrap));
      await tester.pumpAndSettle();

      expect(find.byType(AuthorizationScreen), findsNothing);
      expect(find.byType(NotificationsScreen), findsOneWidget);
    });

    testWidgets('a failed refresh keeps the saved menu and offers Retry', (
      tester,
    ) async {
      final app = await _pumpWithSavedContent(tester);

      app.repository.bootstrapResult.complete(const Error(NetworkFailure()));
      // The result lands after a frame; the message shows on the next one
      // and stays while it counts down, so frames are pumped, not settled.
      for (var frame = 0; frame < 4; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text(_l10n.retry), findsOneWidget);
      expect(find.text('Lavash'), findsWidgets);
    });
  });
}

List<String> _ids(MobileBackendController backend) =>
    backend.menuProducts.map((product) => product.id).toList();

MobileBackendController _controller(MobileBackendRepository repository) {
  final apiClient = ApiClient();
  return MobileBackendController(
    repository,
    MobilePushNotificationService(apiClient),
  );
}

class _App {
  _App(this.repository);
  final _Repository repository;
}

Future<_App> _pumpWithSavedContent(
  WidgetTester tester, {
  List<Object?> savedCart = const <Object?>[],
}) async {
  SharedPreferences.setMockInitialValues({
    'app_locale': 'en',
    'mobile_cart_lines_v2': jsonEncode(savedCart),
  });
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final localeController = LocaleController();
  await localeController.loadLocale();
  addTearDown(localeController.dispose);
  final repository = _Repository(cached: _cachedContent);
  final backend = _controller(repository);
  // As in main(): the bootstrap starts, then the saved content is applied.
  unawaited(backend.bootstrap(language: 'en'));
  await backend.restoreCachedContent(language: 'en');

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
  return _App(repository);
}

Future<List<String>> _savedCartIds() async {
  final preferences = await SharedPreferences.getInstance();
  final encoded = preferences.getString('mobile_cart_lines_v2');
  if (encoded == null) return const <String>[];
  return (jsonDecode(encoded) as List<Object?>)
      .map((line) => (line! as Map<String, Object?>)['productId']! as String)
      .toList();
}

CatalogModel _catalog(List<(String, String)> products) {
  return CatalogModel.fromJson({
    'categories': [
      {
        'id': 'cat-lavash',
        'name': 'Lavash',
        'isActive': true,
        'products': [
          for (final (id, name) in products)
            {'id': id, 'name': name, 'basePrice': 30000, 'isAvailable': true},
        ],
      },
    ],
  }, language: 'en');
}

final MobilePublicContent _cachedContent = MobilePublicContent(
  branches: const [],
  catalog: _catalog(const [
    ('both', 'Both'),
    ('cached-and-gone', 'Cached and gone'),
  ]),
  promotions: const [],
  banners: const [],
);

final MobileBootstrap _guestBootstrap = MobileBootstrap(
  branches: const [],
  catalog: _catalog(const [('both', 'Both'), ('only-network', 'Only network')]),
  promotions: const [],
  paymentMethods: const [],
);

final ClientProfile _client = ClientProfile.fromJson(const {
  'id': 'client-1',
  'fullName': 'Ali Valiyev',
  'phoneNumber': '+998901234567',
  'language': 'en',
  'birthDate': '1990-05-01',
});

final MobileBootstrap _signedInBootstrap = MobileBootstrap(
  branches: const [],
  catalog: _catalog(const [('both', 'Both'), ('only-network', 'Only network')]),
  promotions: const [],
  paymentMethods: const [],
  client: _client,
);

class _Repository implements MobileBackendRepository {
  _Repository({required this.cached});

  final MobilePublicContent? cached;
  final Completer<Result<MobileBootstrap>> bootstrapResult =
      Completer<Result<MobileBootstrap>>();

  @override
  Future<MobilePublicContent?> readCachedPublicContent({
    required String language,
  }) async => cached;

  @override
  Future<Result<MobileBootstrap>> bootstrap({
    required String language,
    String? branchId,
  }) => bootstrapResult.future;

  @override
  Future<Result<ClientNotificationInboxModel>> getNotifications({
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    return Success(
      ClientNotificationInboxModel(
        items: const [],
        unreadCount: 0,
        total: 0,
        limit: limit,
        offset: offset,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Background refreshes are not under test; keep them inert.
    if (invocation.isMethod) return Completer<Never>().future;
    return super.noSuchMethod(invocation);
  }
}
