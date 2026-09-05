import 'package:enjoy_lavash_mobile/app/locale_controller.dart';
import 'package:enjoy_lavash_mobile/app/location_controller.dart';
import 'package:enjoy_lavash_mobile/app/theme_controller.dart';
import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/core/services/mobile_push_notification_service.dart';
import 'package:enjoy_lavash_mobile/core/services/yandex_geocoder_service.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/address_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/assigned_promotion_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/cart_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/catalog_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/client_notification_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/client_profile_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/loyalty_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/order_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/entities/mobile_bootstrap.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/repositories/mobile_backend_repository.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/screens/authorization_screen.dart';
import 'package:enjoy_lavash_mobile/screens/profile.dart';
import 'package:enjoy_lavash_mobile/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_locale': 'uz',
      'theme_mode': 'light',
      'push_notifications_enabled': true,
    });
    PackageInfo.setMockInitialValues(
      appName: 'Enjoy Lavash',
      packageName: 'uz.enjoy.lavash',
      version: '1.4.0',
      buildNumber: '14',
      buildSignature: '',
    );
  });

  test('saved-address mutations keep the Profile count synchronized', () async {
    final repository = _ProfileRepository(authenticated: true);
    final push = _FakePushService();
    final controller = MobileBackendController(repository, push);
    addTearDown(() async {
      controller.dispose();
      await push.dispose();
    });
    await controller.bootstrap(language: 'uz');

    final created = await controller.createAddress(
      const ClientAddressInput(
        label: 'Ota-ona',
        street: 'Navoiy kochasi',
        latitude: 41.32,
        longitude: 69.25,
        isDefault: false,
      ),
    );
    expect(created.isSuccess, isTrue);
    expect(controller.addresses, hasLength(3));

    final updated = await controller.updateAddress(
      id: 'address-2',
      request: const ClientAddressInput(
        label: 'Ish',
        street: 'Shahrisabz kochasi',
        latitude: 41.31,
        longitude: 69.28,
        isDefault: true,
      ),
    );
    expect(updated.isSuccess, isTrue);
    expect(controller.addresses.first.id, 'address-2');
    expect(
      controller.addresses.where((address) => address.isDefault),
      hasLength(1),
    );

    final deleted = await controller.deleteAddress(id: 'address-3');
    expect(deleted.isSuccess, isTrue);
    expect(controller.addresses, hasLength(2));
  });

  testWidgets('authenticated Profile matches the reference hierarchy', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fixture = await _ProfileFixture.authenticated();
    addTearDown(fixture.dispose);
    await tester.pumpWidget(fixture.host());
    await _settleProfile(tester);

    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Aziz Toshmatov'), findsOneWidget);
    expect(find.text('+998 90 123 45 67'), findsOneWidget);
    expect(find.text('41 250 ball'), findsOneWidget);
    expect(find.text('12 ta'), findsOneWidget);
    expect(find.text('2 ta'), findsOneWidget);

    for (final key in <String>[
      'profile-header-row',
      'profile-points-row',
      'profile-orders-row',
      'profile-promos-row',
      'profile-addresses-row',
      'profile-language-row',
      'profile-theme-row',
      'profile-notifications-row',
      'profile-share-row',
      'profile-logout-row',
      'profile-version-label',
    ]) {
      expect(find.byKey(ValueKey<String>(key)), findsOneWidget);
    }

    final headerRect = tester.getRect(
      find.byKey(const ValueKey<String>('profile-header-row')),
    );
    final pointsRect = tester.getRect(
      find.byKey(const ValueKey<String>('profile-points-row')),
    );
    expect(headerRect.left, 20);
    expect(headerRect.width, 350);
    expect(headerRect.height, 84);
    expect(pointsRect.left, 20);
    expect(pointsRect.width, 350);
    expect(pointsRect.height, 69);
    expect(pointsRect.top - headerRect.bottom, 14);
    expect(tester.takeException(), isNull);
  });

  testWidgets('guest Profile keeps public settings and gates account data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fixture = await _ProfileFixture.guest();
    addTearDown(fixture.dispose);
    await tester.pumpWidget(fixture.host());
    await _settleProfile(tester);

    expect(find.text('Avtorizatsiya'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('profile-points-row')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('profile-orders-row')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('profile-logout-row')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('profile-language-row')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('profile-share-row')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey<String>('profile-header-row')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(AuthorizationScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Profile remains usable on a narrow large-text screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fixture = await _ProfileFixture.authenticated(textScale: 1.45);
    addTearDown(fixture.dispose);
    await tester.pumpWidget(fixture.host());
    await _settleProfile(tester);

    final version = find.byKey(const ValueKey<String>('profile-version-label'));
    await tester.scrollUntilVisible(
      version,
      220,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey<String>('profile-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pump();

    expect(version, findsOneWidget);
    expect(tester.takeException(), isNull);

    final themeController = fixture.themeController;
    final themeRow = find.byKey(const ValueKey<String>('profile-theme-row'));
    await tester.ensureVisible(themeRow);
    await tester.tap(themeRow);
    await tester.pump(const Duration(milliseconds: 300));
    expect(themeController.themeMode, ThemeMode.dark);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _settleProfile(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 350));
}

class _ProfileFixture {
  _ProfileFixture({
    required this.controller,
    required this.push,
    required this.themeController,
    required this.textScale,
  });

  final MobileBackendController controller;
  final _FakePushService push;
  final ThemeController themeController;
  final double textScale;

  static Future<_ProfileFixture> authenticated({double textScale = 1}) async {
    final repository = _ProfileRepository(authenticated: true);
    final push = _FakePushService();
    final controller = MobileBackendController(repository, push);
    await controller.bootstrap(language: 'uz');
    await controller.refreshAssignedPromotions(language: 'uz');
    await controller.refreshLoyaltyWallet();
    return _ProfileFixture(
      controller: controller,
      push: push,
      themeController: ThemeController(),
      textScale: textScale,
    );
  }

  static Future<_ProfileFixture> guest() async {
    final repository = _ProfileRepository(authenticated: false);
    final push = _FakePushService();
    final controller = MobileBackendController(repository, push);
    await controller.bootstrap(language: 'uz');
    return _ProfileFixture(
      controller: controller,
      push: push,
      themeController: ThemeController(),
      textScale: 1,
    );
  }

  Widget host() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MobileBackendController>.value(
          value: controller,
        ),
        ChangeNotifierProvider<LocaleController>(
          create: (_) => LocaleController(),
        ),
        ChangeNotifierProvider<ThemeController>.value(value: themeController),
        ChangeNotifierProvider<LocationController>(
          create: (_) => LocationController(YandexGeocoderService()),
        ),
      ],
      child: Consumer2<LocaleController, ThemeController>(
        builder: (context, locale, theme, _) => MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: theme.themeMode,
          locale: locale.locale,
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: const Scaffold(body: SafeArea(child: Profile())),
        ),
      ),
    );
  }

  Future<void> dispose() async {
    controller.dispose();
    themeController.dispose();
    await push.dispose();
  }
}

class _FakePushService extends MobilePushNotificationService {
  _FakePushService() : super(ApiClient(baseUrl: 'https://example.test'));

  bool enabled = true;

  @override
  Stream<PushNotificationMessage> get messages => const Stream.empty();

  @override
  Future<PushNotificationSettings> getSettings() async =>
      PushNotificationSettings(
        supported: true,
        enabled: enabled,
        userEnabled: enabled,
        permissionGranted: true,
        permissionPermanentlyDenied: false,
      );

  @override
  Future<PushNotificationSettings> setNotificationsEnabled(
    bool enabled, {
    String? locale,
  }) async {
    this.enabled = enabled;
    return getSettings();
  }

  @override
  Future<void> syncTokenIfPermissionGranted({String? locale}) async {}

  @override
  Future<void> deleteRegisteredToken() async {}

  @override
  Future<void> clearLocalRegistration({bool resetDeviceId = false}) async {}
}

class _ProfileRepository implements MobileBackendRepository {
  _ProfileRepository({required this.authenticated});

  final bool authenticated;

  static final ClientProfile client = ClientProfile.fromJson({
    'id': 'client-1',
    'fullName': 'Aziz Toshmatov',
    'phoneNumber': '+998901234567',
    'language': 'uz',
    'bonusBalance': 41250,
    'birthDate': '1995-04-07',
    'marketingConsent': true,
    'isBlocked': false,
  });

  static const addresses = <ClientAddress>[
    ClientAddress(
      id: 'address-1',
      label: 'Uy',
      street: 'Amir Temur shoh kochasi',
      houseNumber: '25',
      latitude: 41.3,
      longitude: 69.2,
      isDefault: true,
    ),
    ClientAddress(
      id: 'address-2',
      label: 'Ish',
      street: 'Shahrisabz kochasi',
      latitude: 41.31,
      longitude: 69.28,
      isDefault: false,
    ),
  ];

  static final orders = List<CustomerOrderModel>.generate(
    12,
    (index) => CustomerOrderModel(
      id: 'order-$index',
      type: MobileOrderType.delivery,
      status: MobileOrderStatus.delivered,
      totalAmount: 100000,
      paymentMethod: MobilePaymentMethod.cash,
      items: const [],
      statusLog: const [],
    ),
  );

  static const promotions = <AssignedPromotionModel>[
    AssignedPromotionModel(
      id: 'assignment-1',
      promotionAssignmentId: 'assignment-1',
      promotionId: 'promotion-1',
      code: 'ONE',
      status: AssignedPromotionStatus.active,
      title: 'One',
      description: 'One',
      reward: '10%',
      conditions: <String>[],
      remainingUses: 1,
    ),
    AssignedPromotionModel(
      id: 'assignment-2',
      promotionAssignmentId: 'assignment-2',
      promotionId: 'promotion-2',
      code: 'TWO',
      status: AssignedPromotionStatus.active,
      title: 'Two',
      description: 'Two',
      reward: '20%',
      conditions: <String>[],
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
        paymentMethods: const [],
        client: authenticated ? client : null,
        addresses: authenticated ? addresses : const [],
        orders: authenticated ? orders : const [],
      ),
    );
  }

  @override
  Future<Result<ClientProfile>> getProfile() async => Success(client);

  @override
  Future<Result<List<ClientAddress>>> getAddresses() async =>
      const Success(addresses);

  @override
  Future<Result<List<CustomerOrderModel>>> getOrders() async => Success(orders);

  @override
  Future<Result<ClientAddress>> createAddress(
    ClientAddressInput request,
  ) async => Success(_addressFromInput(id: 'address-3', request: request));

  @override
  Future<Result<ClientAddress>> updateAddress({
    required String id,
    required ClientAddressInput request,
  }) async => Success(_addressFromInput(id: id, request: request));

  @override
  Future<Result<void>> deleteAddress({required String id}) async =>
      const Success(null);

  @override
  Future<Result<ClientNotificationInboxModel>> getNotifications({
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) async => Success(
    ClientNotificationInboxModel(
      items: const [],
      unreadCount: 0,
      total: 0,
      limit: limit,
      offset: offset,
    ),
  );

  @override
  Future<Result<List<AssignedPromotionModel>>> getAssignedPromotions({
    bool includeAll = false,
    String language = 'uz',
  }) async => authenticated
      ? const Success(promotions)
      : const Success(<AssignedPromotionModel>[]);

  @override
  Future<Result<LoyaltyWalletModel>> getLoyaltyWallet() async => Success(
    LoyaltyWalletModel.fromJson({
      'availableBalance': 41250,
      'reservedBalance': 3000,
      'debtBalance': 0,
      'spendableBalance': 38250,
      'nextExpiryAt': null,
      'expiringWithinSevenDays': 0,
      'validityDays': 180,
      'reminderDays': 7,
      'programEnabled': true,
      'redemptionEnabled': true,
      'spendOnDelivery': false,
      'spendOnServiceFee': false,
    }),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ClientAddress _addressFromInput({
  required String id,
  required ClientAddressInput request,
}) {
  return ClientAddress(
    id: id,
    label: request.label,
    street: request.street,
    houseNumber: request.houseNumber,
    apartmentNumber: request.apartmentNumber,
    entrance: request.entrance,
    floor: request.floor,
    doorCode: request.doorCode,
    latitude: request.latitude,
    longitude: request.longitude,
    comment: request.comment,
    isDefault: request.isDefault ?? false,
  );
}
