import 'dart:convert';
import 'dart:collection';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/api/api_endpoints.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/cart_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/file_upload_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/repositories/mobile_backend_repository_impl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('cart preview uses the authenticated client route', () async {
    late RequestOptions recordedRequest;
    final adapter = _Adapter((options) async {
      recordedRequest = options;
      return _jsonResponse({
        'itemsAmount': 10000,
        'modifiersAmount': 0,
        'discountAmount': 0,
        'deliveryAmount': 0,
        'serviceFeeAmount': 0,
        'totalAmount': 10000,
      });
    });
    final repository = MobileBackendRepositoryImpl(
      ApiClient(baseUrl: 'https://example.test', httpClientAdapter: adapter),
    );

    final result = await repository.previewCart(
      const CartPreviewRequest(
        type: MobileOrderType.pickup,
        branchId: 'branch-1',
        items: <CartItemInput>[],
        paymentMethod: MobilePaymentMethod.cash,
      ),
    );

    expect(result, isA<Success<CartPreviewModel>>());
    expect(recordedRequest.uri.path, '/clients/me/cart/preview');
  });

  test('push registration deletion addresses the record ID', () {
    expect(
      ApiEndpoints.clientPushTokenRegistration('registration/id'),
      '/clients/me/push-token-registrations/registration%2Fid',
    );
  });

  test('file uploads can be rejected locally above 10 MB', () {
    final request = FileUploadRequest(
      bytes: _VirtualBytes(FileUploadRequest.maxSizeBytes + 1),
      filename: 'large.jpg',
    );

    expect(request.isTooLarge, isTrue);
  });
}

class _VirtualBytes extends ListBase<int> {
  _VirtualBytes(this._length);

  final int _length;

  @override
  int get length => _length;

  @override
  int operator [](int index) => 0;

  @override
  void operator []=(int index, int value) {
    throw UnsupportedError('read only');
  }

  @override
  set length(int value) {
    throw UnsupportedError('fixed length');
  }
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.onFetch);

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
