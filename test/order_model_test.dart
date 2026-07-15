import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/cart_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/order_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serializes authenticated delivery preview with saved address id', () {
    const request = CartPreviewRequest(
      type: MobileOrderType.delivery,
      addressId: 'addr-ali-home',
      items: [CartItemInput(productId: 'prod-classic-lavash', quantity: 2)],
      paymentMethod: MobilePaymentMethod.cash,
      promoCode: 'FIRST20',
    );

    expect(request.toJson(), {
      'type': 'DELIVERY',
      'addressId': 'addr-ali-home',
      'items': [
        {'productId': 'prod-classic-lavash', 'quantity': 2, 'modifiers': []},
      ],
      'paymentMethod': 'CASH',
      'promoCode': 'FIRST20',
    });
  });

  test('parses cart preview promotion result fields', () {
    final preview = CartPreviewModel.fromJson({
      'itemsAmount': 64000,
      'modifiersAmount': 10000,
      'discountAmount': 14800,
      'deliveryAmount': 10000,
      'serviceFeeAmount': 0,
      'totalAmount': 69200,
      'promotionStatus': 'CLIENT_LIMIT_REACHED',
      'promotionStatusReason': 'Client promotion usage limit was reached',
      'promotionDeliveryDiscountAmount': 10000,
      'bonusItems': [
        {'productId': 'prod-gift', 'quantity': 1},
      ],
    });

    expect(preview.promotionStatus, CartPromotionStatus.clientLimitReached);
    expect(preview.hasPromotionStatus, isTrue);
    expect(
      preview.promotionStatusReason,
      'Client promotion usage limit was reached',
    );
    expect(preview.promotionDeliveryDiscountAmount, 10000);
    expect(preview.bonusItems.single['productId'], 'prod-gift');
  });

  test('uses backend message as cart preview promotion error fallback', () {
    final preview = CartPreviewModel.fromJson({
      'itemsAmount': 64000,
      'modifiersAmount': 0,
      'discountAmount': 0,
      'deliveryAmount': 10000,
      'serviceFeeAmount': 0,
      'totalAmount': 74000,
      'promotionStatus': 'CONDITIONS_NOT_MET',
      'message': 'Minimum order amount was not reached',
    });

    expect(preview.promotionStatus, CartPromotionStatus.conditionsNotMet);
    expect(
      preview.promotionStatusReason,
      'Minimum order amount was not reached',
    );
  });

  test('serializes coordinate delivery with branch id', () {
    final request = CreateOrderRequest(
      type: MobileOrderType.delivery,
      branchId: 'branch-chilanzar',
      address: const CreateOrderAddressInput(
        latitude: 41.3111,
        longitude: 69.2797,
        label: 'Office',
        text: 'Amir Temur Avenue 15, office 42',
        street: 'Amir Temur Avenue',
        houseNumber: '15',
        apartmentNumber: '42',
        entrance: '2',
        floor: '7',
        doorCode: '1234',
        comment: 'Call on arrival',
      ),
      items: const [
        CartItemInput(productId: 'prod-classic-lavash', quantity: 1),
      ],
      paymentMethod: MobilePaymentMethod.cash,
    );

    expect(request.toJson(), {
      'type': 'DELIVERY',
      'address': {
        'latitude': 41.3111,
        'longitude': 69.2797,
        'label': 'Office',
        'text': 'Amir Temur Avenue 15, office 42',
        'street': 'Amir Temur Avenue',
        'houseNumber': '15',
        'apartmentNumber': '42',
        'entrance': '2',
        'floor': '7',
        'doorCode': '1234',
        'comment': 'Call on arrival',
      },
      'branchId': 'branch-chilanzar',
      'items': [
        {'productId': 'prod-classic-lavash', 'quantity': 1, 'modifiers': []},
      ],
      'paymentMethod': 'CASH',
    });
  });

  test('serializes pickup without address fields', () {
    final request = CreateOrderRequest(
      type: MobileOrderType.pickup,
      branchId: 'branch-chilanzar',
      items: const [
        CartItemInput(productId: 'prod-classic-lavash', quantity: 1),
      ],
      paymentMethod: MobilePaymentMethod.cash,
      comment: 'Less spicy please',
    );

    expect(request.toJson(), {
      'type': 'PICKUP',
      'branchId': 'branch-chilanzar',
      'items': [
        {'productId': 'prod-classic-lavash', 'quantity': 1, 'modifiers': []},
      ],
      'paymentMethod': 'CASH',
      'comment': 'Less spicy please',
    });
  });

  test('parses localized product snapshot and status log time', () {
    final order = CustomerOrderModel.fromJson({
      'id': '8b760167-6042-4695-95e6-545d23c3d668',
      'createdAt': '2026-06-19T12:24:27.046Z',
      'updatedAt': '2026-06-19T12:24:27.046Z',
      'orderNumber': '20260619-00004',
      'branchId': '90b4a31e-cb55-49e7-afb1-f2ba9c988816',
      'addressId': null,
      'type': 'DELIVERY',
      'status': 'NEW',
      'paymentMethod': 'CASH',
      'totalAmount': 1015000,
      'items': [
        {
          'productId': '839c0892-d0e2-4923-bbfc-ec4620c83f7c',
          'productNameSnapshotI18n': {'ru': '+18 plus'},
          'quantity': 1,
          'unitPrice': 15000,
          'totalPrice': 15000,
        },
      ],
      'statusLog': [
        {'status': 'NEW', 'at': '2026-06-19T12:24:27.046Z'},
      ],
    });

    final item = order.items.single;
    expect(item.localizedName('ru'), '+18 plus');
    expect(item.localizedName('uz'), '+18 plus');
    expect(item.amount, 15000);
    expect(order.statusLog.single.changedAt, isNotNull);
  });

  test('parses online payment fields from created order response', () {
    final order = CustomerOrderModel.fromJson({
      'id': 'order-payme',
      'type': 'DELIVERY',
      'status': 'NEW',
      'paymentMethod': 'PAYME',
      'paymentStatus': 'PENDING',
      'paymentUrl': 'https://checkout.paycom.uz/token',
      'paymentExpiresAt': '2026-07-03T12:15:00.000Z',
      'paymentRetryAvailable': true,
      'paymentAttemptCount': 1,
      'totalAmount': 40000,
      'items': const [],
      'statusLog': const [],
    });

    expect(order.paymentMethod, MobilePaymentMethod.payme);
    expect(order.paymentStatus, MobilePaymentStatus.pending);
    expect(order.paymentUrl, 'https://checkout.paycom.uz/token');
    expect(order.paymentExpiresAt, isNotNull);
    expect(order.paymentRetryAvailable, isTrue);
    expect(order.paymentAttemptCount, 1);
  });
}
