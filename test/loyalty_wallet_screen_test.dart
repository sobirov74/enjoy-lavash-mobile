import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/core/services/mobile_push_notification_service.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/assigned_promotion_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/client_notification_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/client_profile_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/catalog_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/loyalty_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/entities/mobile_bootstrap.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/repositories/mobile_backend_repository.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/screens/loyalty_wallet_screen.dart';
import 'package:enjoy_lavash_mobile/theme/light_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('debt wallet stays usable on a narrow large-text screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = MobileBackendController(
      _WalletRepository(),
      MobilePushNotificationService(ApiClient(baseUrl: 'https://example.test')),
    );
    addTearDown(controller.dispose);
    await controller.bootstrap(language: 'en');

    await tester.pumpWidget(
      ChangeNotifierProvider<MobileBackendController>.value(
        value: controller,
        child: MaterialApp(
          theme: lightTheme,
          locale: const Locale('en'),
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          ),
          home: const LoyaltyWalletScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My points'), findsOneWidget);
    expect(find.textContaining('Points debt'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Your points activity will appear here.'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Your points activity will appear here.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _WalletRepository implements MobileBackendRepository {
  static final ClientProfile _client = ClientProfile.fromJson({
    'id': 'client-1',
    'fullName': 'Ali',
    'phoneNumber': '+998901234567',
    'language': 'en',
    'bonusBalance': 0,
    'marketingConsent': false,
    'isBlocked': false,
  });

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
        client: _client,
      ),
    );
  }

  @override
  Future<Result<LoyaltyWalletModel>> getLoyaltyWallet() async {
    return Success(
      LoyaltyWalletModel.fromJson({
        'availableBalance': 12000,
        'reservedBalance': 3000,
        'debtBalance': 2500,
        'spendableBalance': 0,
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
  }

  @override
  Future<Result<LoyaltyTransactionPageModel>> getLoyaltyTransactions({
    int limit = 50,
    String? cursor,
  }) async {
    return Success(
      LoyaltyTransactionPageModel(items: const <LoyaltyTransactionModel>[]),
    );
  }

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
  Future<Result<List<AssignedPromotionModel>>> getAssignedPromotions({
    bool includeAll = false,
    String language = 'uz',
  }) async {
    return const Success(<AssignedPromotionModel>[]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
