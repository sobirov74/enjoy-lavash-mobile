import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/api/api_endpoints.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/core/storage/token_storage.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/ordering_status_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/repositories/mobile_backend_repository_impl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('ordering-status endpoint encodes the branch identifier', () {
    expect(
      ApiEndpoints.branchOrderingStatus('branch/chilanzar'),
      '/branches/branch%2Fchilanzar/ordering-status',
    );
  });

  test(
    'fetches immediate ordering status as a public GET without at',
    () async {
      await TokenStorage.saveAccessToken('client-access');
      late RequestOptions recordedRequest;
      final adapter = _Adapter((options) async {
        recordedRequest = options;
        return _jsonResponse(_orderingStatusJson());
      });
      final repository = MobileBackendRepositoryImpl(
        ApiClient(baseUrl: 'https://example.test', httpClientAdapter: adapter),
      );

      final result = await repository.getBranchOrderingStatus(
        branchId: 'branch/chilanzar',
      );

      expect(result, isA<Success<OrderingStatusModel>>());
      expect(recordedRequest.method, 'GET');
      expect(
        recordedRequest.path,
        '/branches/branch%2Fchilanzar/ordering-status',
      );
      expect(recordedRequest.uri.queryParameters, isEmpty);
      expect(recordedRequest.headers['Authorization'], isNull);
      expect(result.dataOrNull?.pickup.isOpen, isTrue);
      expect(result.dataOrNull?.delivery.isOpen, isFalse);
    },
  );
}

class _Adapter implements HttpClientAdapter {
  const _Adapter(this.onFetch);

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

Map<String, Object?> _orderingStatusJson() {
  final weeklyHours = List<Map<String, Object?>>.generate(7, (index) {
    return {
      'weekday': index + 1,
      'opensAt': '09:00',
      'closesAt': '24:00',
      'isClosed': false,
      'deliveryOpensAt': '10:00',
      'deliveryClosesAt': '23:00',
      'source': 'BRANCH',
    };
  });

  return {
    'branchId': 'branch/chilanzar',
    'timezone': 'Asia/Tashkent',
    'evaluatedAt': '2026-08-10T18:15:00.000Z',
    'weeklyHours': weeklyHours,
    'pickup': {
      'isOpen': true,
      'evaluatedAt': '2026-08-10T18:15:00.000Z',
      'timezone': 'Asia/Tashkent',
      'localDate': '2026-08-10',
      'weekday': 1,
      'weeklySource': 'BRANCH',
      'closureSource': null,
      'nextOpeningAt': null,
    },
    'delivery': {
      'isOpen': false,
      'evaluatedAt': '2026-08-10T18:15:00.000Z',
      'timezone': 'Asia/Tashkent',
      'localDate': '2026-08-10',
      'weekday': 1,
      'weeklySource': 'BRANCH',
      'closureSource': 'OUTSIDE_HOURS',
      'nextOpeningAt': '2026-08-11T05:00:00.000Z',
    },
  };
}
