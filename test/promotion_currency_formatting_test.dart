import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/core/services/mobile_push_notification_service.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/order_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/promotion_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/repositories/mobile_backend_repository.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/screens/profile.dart';
import 'package:enjoy_lavash_mobile/widgets/promo_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('public PERCENT reward is displayed as a percentage', (
    tester,
  ) async {
    const promotion = PromotionModel(
      id: 'promo-percent',
      title: 'Twenty percent off',
      isActive: true,
      discountType: 'PERCENT',
      discountValue: 20,
    );

    await tester.pumpWidget(
      _promotionHost(locale: const Locale('en'), promotion: promotion),
    );
    await tester.tap(find.text('Twenty percent off'));
    await tester.pumpAndSettle();

    expect(find.text('20%'), findsOneWidget);
  });

  testWidgets('fixed public reward uses the active locale currency', (
    tester,
  ) async {
    const promotion = PromotionModel(
      id: 'promo-fixed',
      title: 'Скидка',
      isActive: true,
      discountType: 'FIXED',
      discountValue: 15000,
    );
    final expected = '${NumberFormat.decimalPattern('ru').format(15000)} сум';

    await tester.pumpWidget(
      _promotionHost(locale: const Locale('ru'), promotion: promotion),
    );
    await tester.tap(find.text('Скидка'));
    await tester.pumpAndSettle();

    expect(find.text(expected), findsOneWidget);
    expect(find.text("15000 so'm"), findsNothing);
  });

  testWidgets('profile order sheet uses locale-aware order amounts', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final order = CustomerOrderModel.fromJson({
      'id': 'order-delivered',
      'type': 'PICKUP',
      'status': 'DELIVERED',
      'paymentMethod': 'CASH',
      'totalAmount': 56000,
      'items': const <Object?>[],
      'statusLog': const <Object?>[],
    });
    final controller = MobileBackendController(
      _OrderRepository(order),
      MobilePushNotificationService(ApiClient(baseUrl: 'https://example.test')),
    );
    addTearDown(controller.dispose);
    final expected = '${NumberFormat.decimalPattern('en').format(56000)} UZS';

    await tester.pumpWidget(
      ChangeNotifierProvider<MobileBackendController>.value(
        value: controller,
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: L.supportedLocales,
          localizationsDelegates: L.localizationsDelegates,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showProfileOrderDetailsSheet(
                  context: context,
                  order: order,
                  locale: 'en',
                  branches: const [],
                  addresses: const [],
                ),
                child: const Text('Open order'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open order'));
    await tester.pumpAndSettle();

    expect(find.text(expected), findsWidgets);
    expect(find.text("56 000 so'm"), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Widget _promotionHost({
  required Locale locale,
  required PromotionModel promotion,
}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: L.supportedLocales,
    localizationsDelegates: L.localizationsDelegates,
    home: Scaffold(
      body: PromoSlider(
        promotions: <PromotionModel>[promotion],
        locale: locale.languageCode,
      ),
    ),
  );
}

class _OrderRepository implements MobileBackendRepository {
  _OrderRepository(this.order);

  final CustomerOrderModel order;

  @override
  Future<Result<CustomerOrderModel>> getOrder({required String id}) async {
    return Success(order);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
