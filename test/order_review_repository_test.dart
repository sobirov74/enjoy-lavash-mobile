import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/api/api_endpoints.dart';
import 'package:enjoy_lavash_mobile/core/error/failures.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/core/storage/token_storage.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/repositories/mobile_backend_repository_impl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temporary;
  late List<String> paths;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await TokenStorage.saveAccessToken('old-access');
    await TokenStorage.saveRefreshToken('old-refresh');
    temporary = await Directory.systemTemp.createTemp('review-test-');
    paths = [];
    for (var index = 0; index < 2; index++) {
      final file = File('${temporary.path}/photo-$index.jpg');
      await file.writeAsString('photo-body-$index');
      paths.add(file.path);
    }
  });
  tearDown(() async => temporary.delete(recursive: true));

  for (final replay in [false, true]) {
    test(
      'multipart fields and file bytes reach the adapter${replay ? ' again after 401' : ''}',
      () async {
        final adapter = _ReviewRecordingAdapter(replay: replay);
        final api = ApiClient(
          baseUrl: 'https://example.test',
          httpClientAdapter: adapter,
        );
        final repository = MobileBackendRepositoryImpl(api);
        final progress = <int>[];
        final result = await repository.submitOrderReview(
          orderId: 'order-id',
          rating: 4,
          comment: '  Delicious  ',
          photoPaths: paths,
          onSendProgress: (sent, _) => progress.add(sent),
        );
        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull!.review!.rating, 4);
        expect(result.dataOrNull!.canReview, isFalse);
        expect(
          result.dataOrNull!.review!.photos.single.url,
          'https://example.test/uploads/reviews/a.jpg',
        );
        expect(adapter.uploads, hasLength(replay ? 2 : 1));
        for (final record in adapter.uploads) {
          expect(record.path, '/clients/me/orders/order-id/review');
          expect(record.fields, {'rating': '4', 'comment': 'Delicious'});
          expect(record.fileFields, ['photos', 'photos']);
          expect(record.contentTypes, everyElement('image/jpeg'));
          expect(record.body, contains('name="rating"\r\n\r\n4'));
          expect(record.body, contains('name="comment"\r\n\r\nDelicious'));
          expect(record.body, contains('photo-body-0'));
          expect(record.body, contains('photo-body-1'));
          expect(record.sendTimeout, const Duration(minutes: 2));
          expect(record.receiveTimeout, const Duration(minutes: 1));
        }
        expect(progress, isNotEmpty);
        expect(adapter.uploads.first.authorization, 'Bearer old-access');
        if (replay) {
          expect(adapter.refreshes, 1);
          expect(adapter.uploads.last.authorization, 'Bearer new-access');
          expect(adapter.uploads.last.body, adapter.uploads.first.body);
        }
      },
    );
  }

  test('optional comment and photos may be absent', () async {
    final adapter = _ReviewRecordingAdapter();
    final repo = MobileBackendRepositoryImpl(
      ApiClient(baseUrl: 'https://example.test', httpClientAdapter: adapter),
    );
    final result = await repo.submitOrderReview(
      orderId: 'o',
      rating: 5,
      photoPaths: [],
    );
    expect(result.isSuccess, isTrue);
    expect(adapter.uploads.single.fields, {'rating': '5'});
    expect(adapter.uploads.single.fileFields, isEmpty);
  });

  test('missing file is returned as a Failure', () async {
    final adapter = _ReviewRecordingAdapter();
    final repo = MobileBackendRepositoryImpl(
      ApiClient(baseUrl: 'https://example.test', httpClientAdapter: adapter),
    );
    final result = await repo.submitOrderReview(
      orderId: 'o',
      rating: 5,
      photoPaths: ['${temporary.path}/missing.jpg'],
    );
    expect(result.failureOrNull, isA<UnknownFailure>());
    expect(adapter.uploads, isEmpty);
  });
}

class _UploadRecord {
  _UploadRecord(RequestOptions options, this.body)
    : path = options.uri.path,
      authorization = options.headers['Authorization'],
      fields = Map.fromEntries((options.data as FormData).fields),
      fileFields = (options.data as FormData).files
          .map((file) => file.key)
          .toList(),
      contentTypes = (options.data as FormData).files
          .map((file) => file.value.contentType.toString())
          .toList(),
      sendTimeout = options.sendTimeout,
      receiveTimeout = options.receiveTimeout;

  final String path;
  final Object? authorization;
  final Map<String, String> fields;
  final List<String> fileFields;
  final List<String> contentTypes;
  final String body;
  final Duration? sendTimeout;
  final Duration? receiveTimeout;
}

class _ReviewRecordingAdapter implements HttpClientAdapter {
  _ReviewRecordingAdapter({this.replay = false});
  final bool replay;
  final uploads = <_UploadRecord>[];
  int refreshes = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bytes =
        await requestStream?.expand((chunk) => chunk).toList() ?? <int>[];
    if (options.path == ApiEndpoints.clientRefresh) {
      refreshes++;
      return _json({
        'access_token': 'new-access',
        'refresh_token': 'new-refresh',
        'refresh_token_expires_at': '2027-01-01T00:00:00Z',
      });
    }
    uploads.add(_UploadRecord(options, utf8.decode(bytes)));
    if (replay && uploads.length == 1) {
      return _json({'errorCode': 'ACCESS_TOKEN_EXPIRED'}, status: 401);
    }
    return _json({
      'id': 'order-id',
      'reviewRating': 4,
      'canReview': false,
      'review': {
        'id': 'review-id',
        'rating': 4,
        'photos': [
          {'url': '/uploads/reviews/a.jpg', 'width': 1600, 'height': 1200},
        ],
      },
    }, status: 201);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Map<String, Object?> data, {int status = 200}) =>
    ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
