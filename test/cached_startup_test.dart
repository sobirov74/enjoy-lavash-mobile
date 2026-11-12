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

  group('a branch picked while the start-up runs', () {
    test('does not leave the saved menu on screen when its own request '
        'fails', () async {
      final repository = _Repository(cached: _cachedContent);
      final backend = _controller(repository);
      unawaited(backend.bootstrap(language: 'en'));
      await backend.restoreCachedContent(language: 'en');
      // The saved branch list is on screen; the customer picks one.
      final branchCatalog = backend.refreshCatalog(
        language: 'en',
        branchId: 'branch-1',
      );

      repository.bootstrapResult.complete(Success(_guestBootstrap));
      await backend.whenSessionSettled();
      // The fresh default menu shows until the branch menu answers.
      expect(backend.isShowingCachedContent, isFalse);
      expect(_ids(backend), <String>['both', 'only-network']);

      repository.catalogResult.complete(const Error(NetworkFailure()));
      await branchCatalog;
      expect(backend.isShowingCachedContent, isFalse);
      expect(_ids(backend), <String>['both', 'only-network']);
    });

    test('still gets the branch menu when that request works', () async {
      final repository = _Repository(cached: _cachedContent);
      final backend = _controller(repository);
      unawaited(backend.bootstrap(language: 'en'));
      await backend.restoreCachedContent(language: 'en');
      final branchCatalog = backend.refreshCatalog(
        language: 'en',
        branchId: 'branch-1',
      );
      repository.bootstrapResult.complete(Success(_guestBootstrap));
      await backend.whenSessionSettled();

      repository.catalogResult.complete(
        Success(_catalog(const [('branch-only', 'Branch only')])),
      );
      await branchCatalog;
      expect(_ids(backend), <String>['branch-only']);
    });
  });

  group('coming back to the app', () {
    test('retries a start-up that failed over the saved menu', () async {
      final repository = _Repository(cached: _cachedContent);
      final backend = _controller(repository);
      unawaited(backend.bootstrap(language: 'en'));
      await backend.restoreCachedContent(language: 'en');
      repository.bootstrapResult.complete(const Error(NetworkFailure()));
      await backend.whenSessionSettled();
      expect(backend.isSessionUnknown, isTrue);

      unawaited(backend.handleAppResumed(locale: 'en'));
      await Future<void>.delayed(Duration.zero);
      expect(repository.bootstrapCalls, 2);

      repository.bootstrapAt(1).complete(Success(_signedInBootstrap));
      await backend.whenSessionSettled();
      expect(backend.isSessionUnknown, isFalse);
      expect(backend.isAuthenticated, isTrue);
    });

    test('does not repeat a start-up that worked', () async {
      final repository = _Repository(cached: _cachedContent);
      final backend = _controller(repository);
      unawaited(backend.bootstrap(language: 'en'));
      repository.bootstrapResult.complete(Success(_guestBootstrap));
      await backend.whenSessionSettled();

      unawaited(backend.handleAppResumed(locale: 'en'));
      await Future<void>.delayed(Duration.zero);
      expect(repository.bootstrapCalls, 1);
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

    testWidgets('a start-up that failed before the first frame is announced, '
        'and Home does not call the customer a guest', (tester) async {
      await _pumpWithSavedContent(tester, failBeforeFirstFrame: true);
      await _pumpFrames(tester);

      expect(find.text(_l10n.retry), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('home-greeting-pending')),
        findsOneWidget,
      );
      expect(find.text(_l10n.homeGreeting(_l10n.guest)), findsNothing);
    });

    testWidgets('the Retry notice stays until a retry starts, and that retry '
        'can bring the customer back', (tester) async {
      final app = await _pumpWithSavedContent(
        tester,
        failBeforeFirstFrame: true,
      );
      await _pumpFrames(tester);
      // Far longer than an ordinary message stays.
      await tester.pump(const Duration(minutes: 5));
      expect(find.text(_l10n.retry), findsOneWidget);

      await tester.tap(find.text(_l10n.retry));
      await _pumpFrames(tester);
      expect(app.repository.bootstrapCalls, 2);
      expect(find.text(_l10n.retry), findsNothing);

      app.repository.bootstrapAt(1).complete(Success(_signedInBootstrap));
      await tester.pumpAndSettle();
      expect(find.text(_l10n.homeGreeting('Ali')), findsOneWidget);
      expect(find.text(_l10n.retry), findsNothing);
    });

    testWidgets('after a failed start-up a signed-in action tries again '
        'instead of asking to sign in', (tester) async {
      final app = await _pumpWithSavedContent(
        tester,
        failBeforeFirstFrame: true,
      );
      await _pumpFrames(tester);

      // Still offline: nothing opens, and the notice is back.
      await tester.tap(find.byType(NotificationButton).first);
      await tester.pump();
      app.repository.bootstrapAt(1).complete(const Error(NetworkFailure()));
      await _pumpFrames(tester);
      expect(find.byType(AuthorizationScreen), findsNothing);
      expect(find.byType(NotificationsScreen), findsNothing);
      expect(find.text(_l10n.retry), findsOneWidget);

      // Back online: the customer turns out to be signed in.
      await tester.tap(find.byType(NotificationButton).first);
      await tester.pump();
      app.repository.bootstrapAt(2).complete(Success(_signedInBootstrap));
      await tester.pumpAndSettle();
      expect(find.byType(AuthorizationScreen), findsNothing);
      expect(find.byType(NotificationsScreen), findsOneWidget);
    });

    testWidgets('a second tap while the session is awaited opens one screen', (
      tester,
    ) async {
      final app = await _pumpWithSavedContent(tester);

      await tester.tap(find.byType(NotificationButton).first);
      await tester.pump();
      await tester.tap(find.byType(NotificationButton).first);
      await tester.pump();
      app.repository.bootstrapResult.complete(Success(_signedInBootstrap));
      await tester.pumpAndSettle();

      expect(
        find.byType(NotificationsScreen, skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('a gated screen does not open over what the customer moved '
        'on to', (tester) async {
      final app = await _pumpWithSavedContent(tester);

      await tester.tap(find.byType(NotificationButton).first);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey<String>('main-tab-1')));
      await tester.pumpAndSettle();
      app.repository.bootstrapResult.complete(Success(_signedInBootstrap));
      await tester.pumpAndSettle();

      expect(find.byType(NotificationsScreen), findsNothing);
    });

    testWidgets('Checkout tapped twice while the session is awaited opens '
        'one confirmation, for the cart as the network catalog left it', (
      tester,
    ) async {
      final app = await _pumpWithSavedContent(
        tester,
        savedCart: const <Object?>[
          {'productId': 'both', 'quantity': 1},
          {'productId': 'cached-and-gone', 'quantity': 2},
        ],
      );
      await tester.tap(find.byKey(const ValueKey<String>('main-tab-3')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('checkout-label')));
      await tester.pump();
      // The button shows progress and takes no second tap.
      expect(
        find.byKey(const ValueKey<String>('checkout-loading')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('checkout-loading')),
        warnIfMissed: false,
      );
      await tester.pump();

      app.repository.bootstrapResult.complete(Success(_signedInBootstrap));
      await _pumpFrames(tester, 12);

      // One confirmation page, not one per tap.
      expect(
        find.text('1 · ${_l10n.orderType.toUpperCase()}', skipOffstage: false),
        findsOneWidget,
      );
      // The line the network catalog removed is not ordered.
      expect(find.text('Cached and gone', skipOffstage: false), findsNothing);
      expect(find.text('Both', skipOffstage: false), findsWidgets);
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
  _App(this.repository, this.backend);
  final _Repository repository;
  final MobileBackendController backend;
}

/// The Retry notice stays on screen, so frames are pumped, not settled.
Future<void> _pumpFrames(WidgetTester tester, [int frames = 8]) async {
  for (var frame = 0; frame < frames; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<_App> _pumpWithSavedContent(
  WidgetTester tester, {
  List<Object?> savedCart = const <Object?>[],
  bool failBeforeFirstFrame = false,
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
  if (failBeforeFirstFrame) {
    // An offline launch: the request fails before the first frame.
    repository.bootstrapResult.complete(const Error(NetworkFailure()));
    await backend.whenSessionSettled();
  }

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
  return _App(repository, backend);
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
  banners: const [],
);

final MobileBootstrap _guestBootstrap = MobileBootstrap(
  branches: const [],
  catalog: _catalog(const [('both', 'Both'), ('only-network', 'Only network')]),
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
  paymentMethods: const [],
  client: _client,
);

class _Repository implements MobileBackendRepository {
  _Repository({required this.cached});

  final MobilePublicContent? cached;
  final List<Completer<Result<MobileBootstrap>>> _bootstraps =
      <Completer<Result<MobileBootstrap>>>[];
  int bootstrapCalls = 0;

  /// The answer to the first bootstrap call.
  Completer<Result<MobileBootstrap>> get bootstrapResult => bootstrapAt(0);

  /// The answer to bootstrap call number [call] (0 is the first).
  Completer<Result<MobileBootstrap>> bootstrapAt(int call) {
    while (_bootstraps.length <= call) {
      _bootstraps.add(Completer<Result<MobileBootstrap>>());
    }
    return _bootstraps[call];
  }

  final Completer<Result<CatalogModel>> catalogResult =
      Completer<Result<CatalogModel>>();

  @override
  Future<Result<CatalogModel>> getCatalog({
    String language = 'ru',
    String? branchId,
  }) => catalogResult.future;

  @override
  Future<MobilePublicContent?> readCachedPublicContent({
    required String language,
  }) async => cached;

  @override
  Future<Result<MobileBootstrap>> bootstrap({
    required String language,
    String? branchId,
  }) => bootstrapAt(bootstrapCalls++).future;

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
