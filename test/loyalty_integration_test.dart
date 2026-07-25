import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/error/dio_error_mapper.dart';
import 'package:enjoy_lavash_mobile/core/error/failures.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/cart_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/loyalty_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/order_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/repositories/mobile_backend_repository_impl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('wallet parses complete, debt, and nullable expiry states', () {
    final wallet = LoyaltyWalletModel.fromJson({
      'available_balance': 42000,
      'reservedBalance': 10000,
      'debt_balance': 3000,
      'spendableBalance': 0,
      'nextExpiryAt': null,
      'expiring_within_seven_days': 6000,
      'validityDays': 180,
      'reminder_days': 7,
      'programEnabled': true,
      'redemption_enabled': true,
      'spendOnDelivery': false,
      'spend_on_service_fee': true,
    });

    expect(wallet.availableBalance, 42000);
    expect(wallet.reservedBalance, 10000);
    expect(wallet.debtBalance, 3000);
    expect(wallet.nextExpiryAt, isNull);
    expect(wallet.expiringWithinSevenDays, 6000);
    expect(wallet.canRedeem, isFalse);
  });

  test('unknown transaction remains forward compatible', () {
    final transaction = LoyaltyTransactionModel.fromJson({
      'id': 'entry-1',
      'type': 'FUTURE_ADJUSTMENT',
      'availableDelta': 500,
      'reservedDelta': 0,
      'debtDelta': 0,
      'availableBalanceAfter': 500,
      'reservedBalanceAfter': 0,
      'debtBalanceAfter': 0,
      'createdAt': '2026-07-24T07:15:00.000Z',
    });

    expect(transaction.type, LoyaltyTransactionType.unknown);
    expect(transaction.rawType, 'FUTURE_ADJUSTMENT');
    expect(transaction.displayDelta, 500);
  });

  test('old and loyalty-aware orders both parse safely', () {
    final legacy = CustomerOrderModel.fromJson({
      'id': 'legacy',
      'type': 'DELIVERY',
      'status': 'DELIVERED',
      'paymentMethod': 'CASH',
      'totalAmount': 90000,
      'items': const [],
      'statusLog': const [],
    });
    final current = CustomerOrderModel.fromJson({
      'id': 'current',
      'type': 'DELIVERY',
      'status': 'NEW',
      'paymentMethod': 'PAYME',
      'totalBeforePointsAmount': 90000,
      'loyaltyRedeemedAmount': 20000,
      'totalAmount': 70000,
      'items': const [],
      'statusLog': const [],
      'loyalty': {
        'eligible': true,
        'redemption': {'amount': 20000, 'status': 'RESERVED'},
        'accrual': {
          'status': 'PENDING',
          'grossAmount': 0,
          'debtRepaidAmount': 0,
          'creditedAmount': 0,
        },
      },
    });

    expect(legacy.loyalty.eligible, isFalse);
    expect(legacy.loyalty.accrual.status, LoyaltyAccrualStatus.notEligible);
    expect(current.totalBeforePointsAmount, 90000);
    expect(current.loyaltyRedeemedAmount, 20000);
    expect(
      current.loyalty.redemption?.status,
      LoyaltyRedemptionStatus.reserved,
    );
    expect(current.loyalty.accrual.status, LoyaltyAccrualStatus.pending);
  });

  test('preview and create always serialize exact requested points', () {
    const preview = CartPreviewRequest(
      type: MobileOrderType.pickup,
      items: <CartItemInput>[],
      paymentMethod: MobilePaymentMethod.cash,
      loyaltyRedemptionAmount: 20000,
    );
    const create = CreateOrderRequest(
      type: MobileOrderType.pickup,
      items: <CartItemInput>[],
      paymentMethod: MobilePaymentMethod.cash,
      loyaltyRedemptionAmount: 90000,
    );

    expect(preview.toJson()['loyaltyRedemptionAmount'], 20000);
    expect(create.toJson()['loyaltyRedemptionAmount'], 90000);
  });

  test('create order sends the stable idempotency key', () async {
    late RequestOptions recordedRequest;
    final adapter = _LoyaltyAdapter((options) async {
      recordedRequest = options;
      return _jsonResponse({
        'id': 'order-1',
        'type': 'PICKUP',
        'status': 'NEW',
        'paymentMethod': 'CASH',
        'totalAmount': 0,
        'items': const [],
        'statusLog': const [],
      });
    });
    final repository = MobileBackendRepositoryImpl(
      ApiClient(baseUrl: 'https://example.test', httpClientAdapter: adapter),
    );

    final result = await repository.createOrder(
      const CreateOrderRequest(
        type: MobileOrderType.pickup,
        items: <CartItemInput>[],
        paymentMethod: MobilePaymentMethod.cash,
        loyaltyRedemptionAmount: 90000,
      ),
      idempotencyKey: '2f5506fa-48fe-4c0f-9a39-c1a15a111ee1',
    );

    expect(result, isA<Success<CustomerOrderModel>>());
    expect(
      recordedRequest.headers['Idempotency-Key'],
      '2f5506fa-48fe-4c0f-9a39-c1a15a111ee1',
    );
  });

  test('Dio mapper preserves loyalty error code, details, and metadata', () {
    final options = RequestOptions(
      path: '/clients/me/orders',
      headers: const {'Accept-Language': 'en'},
    );
    final failure = mapDioError(
      DioException(
        requestOptions: options,
        response: Response<Object?>(
          requestOptions: options,
          statusCode: 409,
          data: {
            'errorCode': 'LOYALTY_AMOUNT_CHANGED',
            'message': 'Available points changed.',
            'details': ['loyaltyRedemptionAmount is too high'],
            'metadata': {'maxPointsToSpend': 15000},
          },
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(failure, isA<ConflictFailure>());
    final conflict = failure as ConflictFailure;
    expect(conflict.errorCode, 'LOYALTY_AMOUNT_CHANGED');
    expect(conflict.details, isA<List<Object?>>());
    expect(conflict.metadata['maxPointsToSpend'], 15000);
  });
}

class _LoyaltyAdapter implements HttpClientAdapter {
  _LoyaltyAdapter(this.onFetch);

  final Future<ResponseBody> Function(RequestOptions options) onFetch;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return onFetch(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(Map<String, Object?> data) {
  return ResponseBody.fromString(
    jsonEncode(data),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}
