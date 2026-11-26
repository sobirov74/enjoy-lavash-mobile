import 'dart:async';

import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/error/failures.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/core/services/mobile_push_notification_service.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/order_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/repositories/mobile_backend_repository.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:enjoy_lavash_mobile/features/order_review/data/review_photo_normalizer.dart';
import 'package:enjoy_lavash_mobile/features/order_review/data/review_photo_picker.dart';
import 'package:enjoy_lavash_mobile/features/order_review/presentation/order_review_sheet.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

final _order = CustomerOrderModel.fromJson({
  'id': 'order-id',
  'status': 'DELIVERED',
  'canReview': true,
});
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
const _send = ValueKey<String>('review-send');
const _comment = ValueKey<String>('review-comment');
const _fourStars = ValueKey<String>('review-star-4');

void main() {
  late _ReviewRepository repository;
  late MobileBackendController backend;

  setUp(() {
    repository = _ReviewRepository();
    backend = MobileBackendController(
      repository,
      MobilePushNotificationService(ApiClient(baseUrl: 'https://example.test')),
    );
  });
  tearDown(() => backend.dispose());

  Future<void> pump(
    WidgetTester tester, {
    ValueChanged<CustomerOrderModel?>? onResult,
    bool fakePhotos = false,
    ReviewPhotoNormalizer photoNormalizer = const _PhotoNormalizer(),
  }) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: backend,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                key: const ValueKey<String>('open-review'),
                onPressed: () async {
                  final result = fakePhotos
                      ? await showModalBottomSheet<CustomerOrderModel>(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => ChangeNotifierProvider.value(
                            value: backend,
                            child: OrderReviewSheet(
                              order: _order,
                              photoPicker: const _PhotoPicker(),
                              photoNormalizer: photoNormalizer,
                            ),
                          ),
                        )
                      : await showOrderReviewSheet(context, _order);
                  onResult?.call(result);
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey<String>('open-review')));
    await tester.pumpAndSettle();
  }

  Future<void> send(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(_send));
    await tester.tap(find.byKey(_send));
    await tester.pumpAndSettle();
  }

  testWidgets('submit stays disabled until a star is chosen', (tester) async {
    await pump(tester);
    expect(tester.widget<FilledButton>(find.byKey(_send)).onPressed, isNull);
    await tester.tap(find.byKey(_fourStars));
    await tester.pump();
    expect(tester.widget<FilledButton>(find.byKey(_send)).onPressed, isNotNull);
    expect(find.text('Good'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(_fourStars)).shortestSide,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('failure retains the comment and allows a successful retry', (
    tester,
  ) async {
    repository.response = const Error(NetworkFailure());
    CustomerOrderModel? result;
    await pump(tester, onResult: (value) => result = value);
    await tester.tap(find.byKey(_fourStars));
    await tester.pump();
    await tester.enterText(find.byKey(_comment), 'Delicious');
    await send(tester);
    expect(find.byKey(const ValueKey<String>('review-error')), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byKey(_comment)).controller!.text,
      'Delicious',
    );
    expect(repository.comment, 'Delicious');
    expect(repository.rating, 4);
    expect(result, isNull);
    repository.response = Success(_reviewed);
    await send(tester);
    expect(result, same(_reviewed));
    expect(find.byType(OrderReviewSheet), findsNothing);
    expect(backend.orders.single, same(_reviewed));
  });

  testWidgets('success pops with the updated order', (tester) async {
    CustomerOrderModel? result;
    await pump(tester, onResult: (value) => result = value);
    await tester.tap(find.byKey(_fourStars));
    await tester.pump();
    await send(tester);
    expect(result, same(_reviewed));
    expect(result!.review!.rating, 4);
  });

  testWidgets('draft close asks for confirmation and Keep writing retains it', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(find.byKey(_comment), 'Keep this draft');
    await tester.tap(find.byKey(const ValueKey<String>('review-close')));
    await tester.pumpAndSettle();
    expect(find.text('Discard review?'), findsOneWidget);
    await tester.tap(find.text('Keep writing'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byKey(_comment)).controller!.text,
      'Keep this draft',
    );
    await tester.tap(find.byKey(const ValueKey<String>('review-close')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.byType(OrderReviewSheet), findsNothing);
  });

  testWidgets('sending locks stars, comment, photos and close', (tester) async {
    final pending = Completer<Result<CustomerOrderModel>>();
    repository.pending = pending.future;
    await pump(tester);
    await tester.tap(find.byKey(_fourStars));
    await tester.pump();
    await tester.ensureVisible(find.byKey(_send));
    await tester.tap(find.byKey(_send));
    await tester.pump();
    expect(tester.widget<TextField>(find.byKey(_comment)).enabled, isFalse);
    expect(tester.widget<IconButton>(find.byKey(_fourStars)).onPressed, isNull);
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const ValueKey<String>('review-close')),
          )
          .onPressed,
      isNull,
    );
    expect(
      find.byKey(const ValueKey<String>('review-progress')),
      findsOneWidget,
    );
    pending.complete(Success(_reviewed));
    await tester.pumpAndSettle();
  });

  testWidgets('fake photo picker and normalizer require no platform channels', (
    tester,
  ) async {
    await pump(tester, fakePhotos: true);
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('review-add-photo')),
    );
    await tester.tap(find.byKey(const ValueKey<String>('review-add-photo')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('review-gallery')));
    await tester.pumpAndSettle();
    expect(find.text('1/5 photos'), findsOneWidget);
    await tester.tap(find.byKey(_fourStars));
    await tester.pump();
    await send(tester);
    expect(repository.paths, ['/tmp/fake-normalized-review.jpg']);
  });

  testWidgets('a photo being prepared holds its place until the thumbnail '
      'is ready', (tester) async {
    final prepared = Completer<Result<String>>();
    await pump(
      tester,
      fakePhotos: true,
      photoNormalizer: _PendingPhotoNormalizer(prepared.future),
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('review-add-photo')),
    );
    await tester.tap(find.byKey(const ValueKey<String>('review-add-photo')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('review-gallery')));
    // The spinner never settles: pump the sheet's own transitions instead.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    const preparing = ValueKey<String>('review-photo-preparing');
    const thumbnail = ValueKey<String>('review-photo-thumb-0');
    expect(find.byKey(preparing), findsOneWidget);
    expect(find.text('Adding photo…'), findsOneWidget);
    expect(find.byKey(thumbnail), findsNothing);
    // Nothing else can be added or sent meanwhile.
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const ValueKey<String>('review-add-photo')),
          )
          .onPressed,
      isNull,
    );

    prepared.complete(const Success('/tmp/fake-normalized-review.jpg'));
    await tester.pumpAndSettle();

    expect(find.byKey(preparing), findsNothing);
    expect(find.byKey(thumbnail), findsOneWidget);
    expect(find.text('1/5 photos'), findsOneWidget);
    expect(tester.takeException(), isNull);
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

class _PhotoPicker extends ReviewPhotoPicker {
  const _PhotoPicker();
  @override
  Future<String?> pick(ReviewPhotoSource source) async =>
      '/tmp/picked-review.jpg';
}

class _PhotoNormalizer extends ReviewPhotoNormalizer {
  const _PhotoNormalizer();
  @override
  Future<Result<String>> normalize(String path) async =>
      const Success('/tmp/fake-normalized-review.jpg');
  @override
  Future<void> remove(String path) async {}
}

class _PendingPhotoNormalizer extends ReviewPhotoNormalizer {
  const _PendingPhotoNormalizer(this.result);

  final Future<Result<String>> result;

  @override
  Future<Result<String>> normalize(String path) => result;
  @override
  Future<void> remove(String path) async {}
}
