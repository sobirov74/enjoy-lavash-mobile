import 'dart:async';

import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/error/failures.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/core/services/mobile_push_notification_service.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/cart_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/repositories/mobile_backend_repository.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a slower old branch cannot replace newer payment methods', () async {
    final repository = _PaymentMethodsRepository();
    final apiClient = ApiClient(baseUrl: 'https://example.test');
    final controller = MobileBackendController(
      repository,
      MobilePushNotificationService(apiClient),
    );

    final oldRequest = controller.refreshPaymentMethods(
      language: 'en',
      branchId: 'branch-a',
    );
    final newRequest = controller.refreshPaymentMethods(
      language: 'en',
      branchId: 'branch-b',
    );

    repository.requests['branch-b']!.complete(
      const Success(<PaymentMethodModel>[
        PaymentMethodModel(
          id: 'cash-b',
          code: MobilePaymentMethod.cash,
          name: 'Cash B',
          isOnline: false,
          sortOrder: 0,
        ),
      ]),
    );
    await newRequest;

    repository.requests['branch-a']!.complete(
      const Success(<PaymentMethodModel>[
        PaymentMethodModel(
          id: 'payme-a',
          code: MobilePaymentMethod.payme,
          name: 'Payme A',
          isOnline: true,
          sortOrder: 0,
        ),
      ]),
    );
    await oldRequest;

    expect(controller.paymentMethodsBranchId, 'branch-b');
    expect(controller.paymentMethods.single.id, 'cash-b');
    expect(controller.paymentMethodsLoading, isFalse);
  });

  test('a failed branch lookup clears methods from the previous branch',
      () async {
    final repository = _PaymentMethodsRepository();
    final apiClient = ApiClient(baseUrl: 'https://example.test');
    final controller = MobileBackendController(
      repository,
      MobilePushNotificationService(apiClient),
    );

    final firstRequest = controller.refreshPaymentMethods(
      language: 'en',
      branchId: 'branch-a',
    );
    repository.requests['branch-a']!.complete(
      const Success(<PaymentMethodModel>[
        PaymentMethodModel(
          id: 'cash-a',
          code: MobilePaymentMethod.cash,
          name: 'Cash A',
          isOnline: false,
          sortOrder: 0,
        ),
      ]),
    );
    await firstRequest;

    final failedRequest = controller.refreshPaymentMethods(
      language: 'en',
      branchId: 'branch-b',
    );
    expect(controller.paymentMethods, isEmpty);
    repository.requests['branch-b']!.complete(
      const Error<List<PaymentMethodModel>>(
        ServiceUnavailableFailure(),
      ),
    );
    await failedRequest;

    expect(controller.paymentMethods, isEmpty);
    expect(controller.paymentMethodsFailure, isA<ServiceUnavailableFailure>());
  });
}

class _PaymentMethodsRepository implements MobileBackendRepository {
  final Map<String, Completer<Result<List<PaymentMethodModel>>>> requests = {};

  @override
  Future<Result<List<PaymentMethodModel>>> getPaymentMethods({
    String language = 'ru',
    String? branchId,
  }) {
    final completer = Completer<Result<List<PaymentMethodModel>>>();
    requests[branchId ?? ''] = completer;
    return completer.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
