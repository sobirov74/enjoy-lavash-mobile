// Pins the checkout flow end to end (cart → confirmation sheet → preview →
// order) before the shell is refactored: the exact preview and create-order
// payloads, the success path, failures and idempotency-key reuse.

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
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/address_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/app_version_policy_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/branch_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/cart_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/catalog_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/client_profile_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/loyalty_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/order_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/ordering_status_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/repositories/mobile_backend_repository_impl.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/navigation/main_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final L _l10n = lookupL(const Locale('en'));

const List<Map<String, Object?>> _expectedItems = <Map<String, Object?>>[
  <String, Object?>{'productId': 'lavash', 'quantity': 2, 'modifiers': []},
  // The order uses the iiko id when the product has one.
  <String, Object?>{'productId': 'iiko-burger', 'quantity': 1, 'modifiers': []},
];

void main() {
  testWidgets('delivery to the saved default address', (tester) async {
    final app = await _pumpCheckoutApp(tester);

    await app.openCheckout();
    await app.confirmOrder();

    expect(app.backend.previews.map((request) => request.toJson()), [
      {
        'type': 'DELIVERY',
        'addressId': 'address-home',
        'items': _expectedItems,
        'paymentMethod': 'CASH',
        'loyaltyRedemptionAmount': 0,
      },
    ]);
    expect(app.backend.createdOrders.single.request.toJson(), {
      'type': 'DELIVERY',
      'addressId': 'address-home',
      'items': _expectedItems,
      'paymentMethod': 'CASH',
      'loyaltyRedemptionAmount': 0,
    });
    expect(app.backend.createdOrders.single.idempotencyKey, isNotEmpty);

    expect(find.byType(OrderSuccessScreen), findsOneWidget);
    expect(await _savedCart(), isNull);
  });

  testWidgets('delivery to the picked map point sends it inline with the '
      'preview branch', (tester) async {
    final app = await _pumpCheckoutApp(tester);
    app.location.setFromMap(
      latitude: 41.311,
      longitude: 69.279,
      address: 'Amir Temur 1',
    );

    await app.openCheckout();
    await app.confirmOrder();

    expect(app.backend.previews.single.toJson(), {
      'type': 'DELIVERY',
      'address': {'latitude': 41.311, 'longitude': 69.279},
      'items': _expectedItems,
      'paymentMethod': 'CASH',
      'loyaltyRedemptionAmount': 0,
    });
    expect(app.backend.createdOrders.single.request.toJson(), {
      'type': 'DELIVERY',
      'address': {
        'latitude': 41.311,
        'longitude': 69.279,
        'label': 'Amir Temur 1',
        'text': 'Amir Temur 1',
        'street': 'Amir Temur 1',
      },
      'branchId': 'branch-1',
      'items': _expectedItems,
      'paymentMethod': 'CASH',
      'loyaltyRedemptionAmount': 0,
    });
  });

  testWidgets('pickup from a branch chosen in the sheet', (tester) async {
    final app = await _pumpCheckoutApp(tester);

    await app.openCheckout();
    await tester.tap(
      find.byKey(const ValueKey<String>('order-type-pickup-target')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('branch-card-branch-2')),
    );
    await tester.pumpAndSettle();
    await app.confirmOrder();

    expect(app.backend.previews.last.toJson(), {
      'type': 'PICKUP',
      'branchId': 'branch-2',
      'items': _expectedItems,
      'paymentMethod': 'CASH',
      'loyaltyRedemptionAmount': 0,
    });
    expect(app.backend.orderingStatusRequests, contains('branch-2'));
    expect(app.backend.createdOrders.single.request.toJson(), {
      'type': 'PICKUP',
      'branchId': 'branch-2',
      'items': _expectedItems,
      'paymentMethod': 'CASH',
      'loyaltyRedemptionAmount': 0,
    });
  });

  testWidgets('a promo code accepted by the preview goes into the order', (
    tester,
  ) async {
    final app = await _pumpCheckoutApp(tester);
    app.backend.previewResult = Success(
      CartPreviewModel.fromJson({
        ..._previewJson,
        'promotionStatus': 'APPLIED',
        'discountAmount': 5000,
        'totalAmount': 95000,
      }),
    );

    await app.openCheckout();
    final promoField = find.widgetWithText(TextField, _l10n.enterPromoCode);
    await tester.ensureVisible(promoField);
    await tester.enterText(promoField, ' SPRING ');
    // The preview is debounced while typing.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    await app.confirmOrder();

    expect(app.backend.previews.last.toJson()['promoCode'], 'SPRING');
    expect(app.backend.createdOrders.single.request.toJson(), {
      'type': 'DELIVERY',
      'addressId': 'address-home',
      'items': _expectedItems,
      'paymentMethod': 'CASH',
      'promoCode': 'SPRING',
      'loyaltyRedemptionAmount': 0,
    });
  });

  testWidgets('changing the payment method previews and orders with it', (
    tester,
  ) async {
    final app = await _pumpCheckoutApp(tester);

    await app.openCheckout();
    final payme = find.byKey(const ValueKey<String>('payme'));
    await tester.ensureVisible(payme);
    await tester.tap(payme);
    await tester.pumpAndSettle();
    await app.confirmOrder();

    expect(app.backend.previews.map((request) => request.paymentMethod), [
      MobilePaymentMethod.cash,
      MobilePaymentMethod.payme,
    ]);
    expect(
      app.backend.createdOrders.single.request.toJson()['paymentMethod'],
      'PAYME',
    );
  });

  testWidgets('ordering closed keeps the cart and explains why', (
    tester,
  ) async {
    final app = await _pumpCheckoutApp(tester);
    app.backend.createResults.add(
      const Error(
        ServerFailure(
          409,
          'Ordering is closed',
          ApiFailurePayload(errorCode: 'ORDERING_CLOSED'),
        ),
      ),
    );

    await app.openCheckout();
    await app.confirmOrder();

    expect(find.text(_l10n.orderingClosed), findsOneWidget);
    expect(find.text(_l10n.retry), findsNothing);
    await tester.tap(find.text(_l10n.close));
    await tester.pumpAndSettle();

    expect(find.byType(OrderSuccessScreen), findsNothing);
    expect(await _savedCart(), hasLength(2));
    // A definite answer: history is not reloaded.
    expect(app.backend.customerDataRefreshes, 0);
  });

  testWidgets('a timeout offers retry, and the retry reuses the key', (
    tester,
  ) async {
    final app = await _pumpCheckoutApp(tester);
    app.backend.createResults.add(const Error(TimeoutFailure()));

    await app.openCheckout();
    await app.confirmOrderExpectingDialog();

    expect(find.text(_l10n.errorSlowNetwork), findsOneWidget);
    await tester.tap(find.text(_l10n.retry));
    await tester.pumpAndSettle();

    final keys = app.backend.createdOrders.map((order) => order.idempotencyKey);
    expect(keys, hasLength(2));
    expect(keys.toSet(), hasLength(1));
    expect(find.byType(OrderSuccessScreen), findsOneWidget);
    expect(await _savedCart(), isNull);
  });

  testWidgets('after an unknown outcome the next checkout reuses the key and '
      'history is reloaded', (tester) async {
    final app = await _pumpCheckoutApp(tester);
    app.backend.createResults.add(const Error(TimeoutFailure()));

    await app.openCheckout();
    await app.confirmOrderExpectingDialog();
    expect(find.text(_l10n.errorSlowNetwork), findsOneWidget);
    await app.tapDialogAction(_l10n.close);
    await tester.pumpAndSettle();

    expect(app.backend.customerDataRefreshes, 1);
    expect(await _savedCart(), hasLength(2));

    // The confirmation sheet closed; checkout starts again from the cart.
    await app.openCheckout(fromCartTab: false);
    await app.confirmOrder();

    final keys = app.backend.createdOrders.map((order) => order.idempotencyKey);
    expect(keys, hasLength(2));
    expect(keys.toSet(), hasLength(1));
    expect(find.byType(OrderSuccessScreen), findsOneWidget);
  });
}

class _CheckoutApp {
  _CheckoutApp(this.tester, this.backend, this.location);

  final WidgetTester tester;
  final _CheckoutBackend backend;
  final LocationController location;

  Future<void> openCheckout({bool fromCartTab = true}) async {
    if (fromCartTab) {
      await tester.tap(find.byKey(const ValueKey<String>('main-tab-3')));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text(_l10n.checkout));
    await tester.pumpAndSettle();
  }

  Future<void> confirmOrder() async {
    final label = _l10n.createOrderFor('#').split('#').first;
    await tester.tap(
      find.ancestor(
        of: find.textContaining(label),
        matching: find.byType(FilledButton),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Confirms an order whose creation fails with an unknown outcome. The
  /// cart's checkout button keeps spinning while the error dialog is open, so
  /// the frames are pumped instead of settled.
  Future<void> confirmOrderExpectingDialog() async {
    final label = _l10n.createOrderFor('#').split('#').first;
    await tester.tap(
      find.ancestor(
        of: find.textContaining(label),
        matching: find.byType(FilledButton),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Taps a dialog action while the checkout button is still spinning.
  Future<void> tapDialogAction(String label) async {
    await tester.tap(find.text(label));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
}

Future<_CheckoutApp> _pumpCheckoutApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({
    'app_locale': 'en',
    'mobile_cart_lines_v2': jsonEncode([
      {'productId': 'lavash', 'quantity': 2},
      {'productId': 'burger', 'quantity': 1},
    ]),
  });
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final localeController = LocaleController();
  await localeController.loadLocale();
  addTearDown(localeController.dispose);
  final location = LocationController(YandexGeocoderService());
  final backend = _CheckoutBackend(ApiClient());

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeController>(
          create: (_) => ThemeController(),
        ),
        ChangeNotifierProvider<LocaleController>.value(value: localeController),
        ChangeNotifierProvider<LocationController>.value(value: location),
        ChangeNotifierProvider<MobileBackendController>.value(value: backend),
      ],
      child: const MyApp(),
    ),
  );
  await tester.pumpAndSettle();
  return _CheckoutApp(tester, backend, location);
}

Future<List<Object?>?> _savedCart() async {
  final preferences = await SharedPreferences.getInstance();
  final encoded = preferences.getString('mobile_cart_lines_v2');
  return encoded == null ? null : jsonDecode(encoded) as List<Object?>;
}

const Map<String, Object?> _previewJson = <String, Object?>{
  'branchId': 'branch-1',
  'itemsAmount': 100000,
  'modifiersAmount': 0,
  'discountAmount': 0,
  'deliveryAmount': 0,
  'serviceFeeAmount': 0,
  'totalAmount': 100000,
};

/// A signed-in customer with a saved address. Every call the checkout makes
/// is answered here and recorded; nothing reaches the network.
class _CheckoutBackend extends MobileBackendController {
  _CheckoutBackend(ApiClient apiClient)
    : super(
        MobileBackendRepositoryImpl(apiClient),
        MobilePushNotificationService(apiClient),
      );

  final List<CartPreviewRequest> previews = <CartPreviewRequest>[];
  final List<({CreateOrderRequest request, String idempotencyKey})>
  createdOrders = <({CreateOrderRequest request, String idempotencyKey})>[];
  final List<String> orderingStatusRequests = <String>[];

  /// Answers for successive create-order calls; success once empty.
  final List<Result<CustomerOrderModel>> createResults =
      <Result<CustomerOrderModel>>[];
  Result<CartPreviewModel> previewResult = Success(
    CartPreviewModel.fromJson(_previewJson),
  );
  int customerDataRefreshes = 0;

  @override
  MobileBackendStatus get status => MobileBackendStatus.loaded;

  @override
  bool get isAuthenticated => true;

  @override
  ClientProfile? get client => _client;

  @override
  List<String> get menuCategories => const ['Lavash', 'Burger'];

  @override
  List<MenuProduct> get menuProducts => _products;

  @override
  List<ClientAddress> get addresses => _addresses;

  @override
  List<BranchModel> get branches => _branches;

  @override
  List<PaymentMethodModel> get paymentMethods => _paymentMethods;

  @override
  String? get paymentMethodsBranchId => 'branch-1';

  @override
  Future<Result<CartPreviewModel>> previewCart(
    CartPreviewRequest request,
  ) async {
    previews.add(request);
    return previewResult;
  }

  @override
  Future<Result<CustomerOrderModel>> createOrder(
    CreateOrderRequest request, {
    required String idempotencyKey,
  }) async {
    createdOrders.add((request: request, idempotencyKey: idempotencyKey));
    if (createResults.isNotEmpty) return createResults.removeAt(0);
    return Success(_createdOrder);
  }

  @override
  Future<Result<OrderingStatusModel>> getBranchOrderingStatus({
    required String branchId,
  }) async {
    orderingStatusRequests.add(branchId);
    return Success(OrderingStatusModel.fromJson(_openStatus(branchId)));
  }

  @override
  Future<Result<LoyaltyWalletModel>> refreshLoyaltyWallet() async =>
      const Error(NetworkFailure());

  @override
  Future<Result<List<PaymentMethodModel>>> refreshPaymentMethods({
    required String language,
    String? branchId,
  }) async => Success(_paymentMethods);

  @override
  Future<Result<CatalogModel>> refreshCatalog({
    required String language,
    String? branchId,
  }) async => Success(CatalogModel.fromJson(const {'categories': []}));

  @override
  Future<void> refreshCustomerData() async => customerDataRefreshes++;

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
  // A known birth date keeps the startup birth-date prompt away.
  'birthDate': '1990-05-01',
});

const List<MenuProduct> _products = <MenuProduct>[
  MenuProduct(
    id: 'lavash',
    title: 'Lavash',
    price: 30000,
    category: 'Lavash',
    emoji: '🌯',
    tint: Colors.orange,
    highlight: Colors.amber,
  ),
  MenuProduct(
    id: 'burger',
    iikoId: 'iiko-burger',
    title: 'Burger',
    price: 40000,
    category: 'Burger',
    emoji: '🍔',
    tint: Colors.orange,
    highlight: Colors.amber,
  ),
];

const List<ClientAddress> _addresses = <ClientAddress>[
  ClientAddress(
    id: 'address-work',
    label: 'Work',
    street: 'Navoi',
    latitude: 41.30,
    longitude: 69.24,
    isDefault: false,
  ),
  ClientAddress(
    id: 'address-home',
    label: 'Home',
    street: 'Bunyodkor',
    houseNumber: '12',
    latitude: 41.28,
    longitude: 69.20,
    isDefault: true,
  ),
];

final List<BranchModel> _branches = <BranchModel>[
  BranchModel.fromJson({
    'id': 'branch-1',
    'name': 'Chilonzor',
    'address': 'Bunyodkor 1',
    'isActive': true,
  }),
  BranchModel.fromJson({
    'id': 'branch-2',
    'name': 'Yunusobod',
    'address': 'Amir Temur 100',
    'isActive': true,
  }),
];

const List<PaymentMethodModel> _paymentMethods = <PaymentMethodModel>[
  PaymentMethodModel(
    id: 'cash',
    code: MobilePaymentMethod.cash,
    name: 'Cash',
    isOnline: false,
    sortOrder: 0,
  ),
  PaymentMethodModel(
    id: 'payme',
    code: MobilePaymentMethod.payme,
    name: 'Payme',
    isOnline: true,
    sortOrder: 1,
  ),
];

final CustomerOrderModel _createdOrder = CustomerOrderModel.fromJson({
  'id': 'order-42',
  'type': 'DELIVERY',
  'status': 'NEW',
  'paymentMethod': 'CASH',
  'totalAmount': 100000,
  'items': const [],
  'statusLog': const [],
});

Map<String, Object?> _openStatus(String branchId) {
  final now = DateTime.now().toUtc().toIso8601String();
  Map<String, Object?> availability() => {
    'isOpen': true,
    'evaluatedAt': now,
    'timezone': 'Asia/Tashkent',
    'weeklySource': 'BRANCH',
    'closureSource': null,
    'nextOpeningAt': null,
  };
  return {
    'branchId': branchId,
    'timezone': 'Asia/Tashkent',
    'evaluatedAt': now,
    'weeklyHours': const <Object?>[],
    'pickup': availability(),
    'delivery': availability(),
  };
}
