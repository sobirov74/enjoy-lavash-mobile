import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/core/services/mobile_push_notification_service.dart';
import 'package:enjoy_lavash_mobile/app/locale_controller.dart';
import 'package:enjoy_lavash_mobile/app/location_controller.dart';
import 'package:enjoy_lavash_mobile/app/theme_controller.dart';
import 'package:enjoy_lavash_mobile/core/services/yandex_geocoder_service.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/assigned_promotion_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/cart_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/catalog_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/client_notification_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/client_profile_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/entities/mobile_bootstrap.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/repositories/mobile_backend_repository.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/navigation/main_tabs.dart';
import 'package:enjoy_lavash_mobile/screens/assigned_promotions_screen.dart';
import 'package:enjoy_lavash_mobile/screens/notifications_screen.dart';
import 'package:enjoy_lavash_mobile/screens/profile.dart';
import 'package:enjoy_lavash_mobile/theme/light_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('notification inbox fits a compact mobile viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = await _controller();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(controller: controller, child: const NotificationsScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lunch promo'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Promotions'), findsOneWidget);
    expect(find.byIcon(Icons.done_all_rounded), findsOneWidget);

    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();
    expect(find.text('Lunch promo'), findsNothing);
    expect(find.text('No notifications match this filter.'), findsOneWidget);

    await tester.tap(find.text('Promotions'));
    await tester.pumpAndSettle();
    expect(find.text('Lunch promo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('assigned promotion remains usable on a compact viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = await _controller();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(controller: controller, child: const AssignedPromotionsScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('PRIVATE20-ABC'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Use in order'),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Use in order'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all orders exposes button and pull-to-refresh controls', (
    tester,
  ) async {
    final controller = await _controller();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(
        controller: controller,
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () => showAllOrdersScreen(context),
            child: const Text('Open orders'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open orders'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing birth date is prompted once at startup and can close', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = await _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_mainTabsHost(controller));
    await tester.pumpAndSettle();

    expect(find.text('Your special day 🎂'), findsOneWidget);
    expect(find.byType(CupertinoPicker), findsNWidgets(3));

    await tester.tap(
      find.byKey(const ValueKey<String>('birth-date-close-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your special day 🎂'), findsNothing);
    await tester.pump();
    expect(find.text('Your special day 🎂'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('guest inbox navigation is gated by authorization', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = await _guestController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_mainTabsHost(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Inbox'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your phone number'), findsOneWidget);
    expect(find.byType(NotificationsScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<MobileBackendController> _controller() async {
  final apiClient = ApiClient(baseUrl: 'https://example.test');
  final controller = MobileBackendController(
    _NotificationsRepository(),
    MobilePushNotificationService(apiClient),
  );
  await controller.bootstrap(language: 'en');
  return controller;
}

Future<MobileBackendController> _guestController() async {
  final apiClient = ApiClient(baseUrl: 'https://example.test');
  final controller = MobileBackendController(
    _GuestNotificationsRepository(),
    MobilePushNotificationService(apiClient),
  );
  await controller.bootstrap(language: 'en');
  return controller;
}

Widget _host({
  required MobileBackendController controller,
  required Widget child,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<MobileBackendController>.value(value: controller),
      ChangeNotifierProvider<LocaleController>(
        create: (_) => LocaleController(),
      ),
    ],
    child: MaterialApp(
      theme: lightTheme,
      locale: const Locale('en'),
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,
      home: child,
    ),
  );
}

Widget _mainTabsHost(MobileBackendController controller) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<MobileBackendController>.value(value: controller),
      ChangeNotifierProvider<LocaleController>(
        create: (_) => LocaleController(),
      ),
      ChangeNotifierProvider<ThemeController>(create: (_) => ThemeController()),
      ChangeNotifierProvider<LocationController>(
        create: (_) => LocationController(YandexGeocoderService()),
      ),
    ],
    child: MaterialApp(
      theme: lightTheme,
      locale: const Locale('en'),
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,
      home: const MainTabs(),
    ),
  );
}

class _NotificationsRepository implements MobileBackendRepository {
  static final ClientProfile _client = ClientProfile.fromJson({
    'id': 'client-1',
    'fullName': 'Ali',
    'phoneNumber': '+998901234567',
    'language': 'en',
    'bonusBalance': 12,
    'marketingConsent': true,
    'isBlocked': false,
  });

  static final ClientNotificationInboxModel _inbox =
      ClientNotificationInboxModel.fromJson({
        'items': [
          {
            'id': 'notification-1',
            'notificationId': 'notification-1',
            'kind': 'PROMOTION_ASSIGNMENT',
            'title': 'Lunch promo',
            'body': 'Your personal promo code is ready.',
            'sentAt': '2026-07-23T12:00:00.000Z',
            'isRead': false,
            'promotionAssignmentId': 'assignment-1',
            'promotionCode': 'PRIVATE20-ABC',
          },
        ],
        'unreadCount': 1,
        'total': 1,
        'limit': 50,
        'offset': 0,
      });

  static const List<AssignedPromotionModel> _promotions = [
    AssignedPromotionModel(
      id: 'assignment-1',
      promotionAssignmentId: 'assignment-1',
      promotionId: 'promotion-1',
      code: 'PRIVATE20-ABC',
      status: AssignedPromotionStatus.active,
      title: 'Personal lunch offer',
      description: 'Save on your next order.',
      reward: '20%',
      conditions: <String>['Minimum order: 100 000'],
      remainingUses: 1,
    ),
  ];

  @override
  Future<Result<MobileBootstrap>> bootstrap({
    required String language,
    String? branchId,
  }) async {
    return Success(
      MobileBootstrap(
        branches: const [],
        catalog: CatalogModel.fromJson(const <String, dynamic>{}),
        promotions: const [],
        paymentMethods: const <PaymentMethodModel>[],
        client: _client,
      ),
    );
  }

  @override
  Future<Result<ClientNotificationInboxModel>> getNotifications({
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    return Success(_inbox);
  }

  @override
  Future<Result<List<AssignedPromotionModel>>> getAssignedPromotions({
    bool includeAll = false,
    String language = 'uz',
  }) async {
    return const Success(_promotions);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _GuestNotificationsRepository implements MobileBackendRepository {
  @override
  Future<Result<MobileBootstrap>> bootstrap({
    required String language,
    String? branchId,
  }) async {
    return Success(
      MobileBootstrap(
        branches: const [],
        catalog: CatalogModel.fromJson(const <String, dynamic>{}),
        promotions: const [],
        paymentMethods: const <PaymentMethodModel>[],
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
