import 'dart:async';

import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/error/failures.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/core/services/mobile_push_notification_service.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/order_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/repositories/mobile_backend_repository.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _reviewed = CustomerOrderModel.fromJson({
  'id': 'order-id',
  'status': 'DELIVERED',
  'canReview': false,
  'reviewRating': 4,
  'review': {
    'id': 'review-id',
    'rating': 4,
    'comment': 'Delicious',
    'photos': [],
  },
});
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _ReviewRepository repository;
  late MobileBackendController backend;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = _ReviewRepository();
    backend = MobileBackendController(
      repository,
      MobilePushNotificationService(ApiClient(baseUrl: 'https://example.test')),
    );
  });
  tearDown(() => backend.dispose());
  test('already reviewed refreshes and returns success', () async {
    repository.response = const Error(
      ConflictFailure(
        'Request conflict',
        ApiFailurePayload(errorCode: 'ORDER_ALREADY_REVIEWED'),
      ),
    );
    final result = await backend.submitOrderReview(
      orderId: 'order-id',
      rating: 4,
      photoPaths: [],
    );
    expect(result.dataOrNull, same(_reviewed));
    expect(repository.refreshCalls, 1);
    expect(backend.orders.single, same(_reviewed));
  });

  test('a failed duplicate refresh retains failure for retry', () async {
    repository.response = const Error(
      ConflictFailure(
        'Request conflict',
        ApiFailurePayload(errorCode: 'ORDER_ALREADY_REVIEWED'),
      ),
    );
    repository.refreshResponse = const Error(NetworkFailure());
    final result = await backend.submitOrderReview(
      orderId: 'order-id',
      rating: 4,
      photoPaths: [],
    );
    expect(result.failureOrNull, isA<NetworkFailure>());
    expect(backend.orders, isEmpty);
  });

  test('late submission cannot restore an ended session', () async {
    final pending = Completer<Result<CustomerOrderModel>>();
    repository.pending = pending.future;
    final submission = backend.submitOrderReview(
      orderId: 'order-id',
      rating: 4,
      photoPaths: [],
    );
    await backend.handleSessionExpired();
    pending.complete(Success(_reviewed));
    expect((await submission).failureOrNull, isA<AuthFailure>());
    expect(backend.orders, isEmpty);
  });
}

class _ReviewRepository implements MobileBackendRepository {
  Result<CustomerOrderModel>? response;
  Future<Result<CustomerOrderModel>>? pending;
  Result<CustomerOrderModel>? refreshResponse;
  int refreshCalls = 0;
  int? rating;
  String? comment;
  List<String>? paths;

  @override
  Future<Result<CustomerOrderModel>> submitOrderReview({
    required String orderId,
    required int rating,
    String? comment,
    required List<String> photoPaths,
    void Function(int sent, int total)? onSendProgress,
  }) {
    this.rating = rating;
    this.comment = comment;
    paths = photoPaths;
    return pending ?? Future.value(response ?? Success(_reviewed));
  }

  @override
  Future<Result<CustomerOrderModel>> getOrder({required String id}) async {
    refreshCalls++;
    return refreshResponse ?? Success(_reviewed);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => Completer<Never>().future;
}
