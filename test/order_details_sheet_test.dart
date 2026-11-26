import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/core/services/mobile_push_notification_service.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/branch_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/catalog_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/client_profile_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/order_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/entities/mobile_bootstrap.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/repositories/mobile_backend_repository.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:enjoy_lavash_mobile/features/order_review/presentation/order_review_sheet.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/screens/profile.dart';
import 'package:enjoy_lavash_mobile/theme/dark_theme.dart';
import 'package:enjoy_lavash_mobile/theme/light_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _ratePrompt = ValueKey<String>('order-review-prompt');
const _savedReview = ValueKey<String>('order-review-saved');
const _thanks = ValueKey<String>('order-review-thanks');
const _send = ValueKey<String>('review-send');

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('a star on the rate card opens the form with it chosen and '
      'the sent review replaces the card', (tester) async {
    final repository = _Repository(detail: _order(canReview: true))
      ..reviewed = _order(
        reviewRating: 4,
        review: _review(rating: 4, comment: 'Hot and fast'),
      );
    await _openSheet(tester, repository, _order(canReview: true));

    expect(find.byKey(_ratePrompt), findsOneWidget);
    expect(find.byKey(_savedReview), findsNothing);

    await tester.tap(find.byKey(const ValueKey<String>('details-rate-star-4')));
    await tester.pumpAndSettle();
    expect(find.byType(OrderReviewSheet), findsOneWidget);
    // The star tapped on the card is already chosen: Send is enabled.
    expect(find.text('Good'), findsOneWidget);
    await tester.ensureVisible(find.byKey(_send));
    await tester.tap(find.byKey(_send));
    await tester.pumpAndSettle();

    expect(repository.sentRating, 4);
    expect(find.byType(OrderReviewSheet), findsNothing);
    expect(find.byKey(_ratePrompt), findsNothing);
    expect(find.byKey(_savedReview), findsOneWidget);
    expect(find.byKey(_thanks), findsOneWidget);
    expect(find.text('Hot and fast'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('closing the form opened from a star asks nothing', (
    tester,
  ) async {
    final repository = _Repository(detail: _order(canReview: true));
    await _openSheet(tester, repository, _order(canReview: true));

    await tester.tap(find.byKey(const ValueKey<String>('details-rate-star-5')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('review-close')));
    await tester.pumpAndSettle();

    expect(find.byType(OrderReviewSheet), findsNothing);
    expect(find.text('Discard review?'), findsNothing);
    expect(find.byKey(_ratePrompt), findsOneWidget);
  });

  testWidgets('a rated order from the list shows its stars at once and the '
      'full review when the details arrive', (tester) async {
    final details = Completer<Result<CustomerOrderModel>>();
    final repository = _Repository(pendingDetail: details.future);
    // The order list carries the rating alone.
    await _openSheet(
      tester,
      repository,
      _order(reviewRating: 5),
      signedIn: true,
    );

    expect(find.byKey(_savedReview), findsOneWidget);
    expect(find.bySemanticsLabel('5 out of 5 stars'), findsOneWidget);
    expect(find.text('Excellent'), findsOneWidget);
    expect(find.byKey(_thanks), findsNothing);
    expect(find.byKey(_ratePrompt), findsNothing);

    details.complete(
      Success(
        _order(
          reviewRating: 5,
          review: _review(rating: 5, comment: 'Best lavash in town'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Best lavash in town'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an order that cannot be reviewed shows no review card', (
    tester,
  ) async {
    final order = _order(status: 'COOKING');
    await _openSheet(tester, _Repository(detail: order), order);

    expect(find.byKey(_ratePrompt), findsNothing);
    expect(find.byKey(_savedReview), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('order-progress-journey')),
      findsOneWidget,
    );
  });

  testWidgets('paying again stays pinned under the scrolling details', (
    tester,
  ) async {
    final order = _order(
      status: 'NEW',
      paymentRetryAvailable: true,
      paymentStatus: 'FAILED',
    );
    await _openSheet(tester, _Repository(detail: order), order);

    final retry = find.byKey(const ValueKey<String>('details-retry-payment'));
    expect(retry, findsOneWidget);
    expect(find.text('Failed'), findsOneWidget);
    final before = tester.getRect(retry);
    await tester.drag(find.text('Status history'), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(tester.getRect(retry), before);
  });

  testWidgets('the details fit a small screen with large text', (tester) async {
    final order = _order(
      canReview: true,
      paymentRetryAvailable: true,
      paymentStatus: 'PENDING',
    );
    await _openSheet(
      tester,
      _Repository(detail: order),
      order,
      size: const Size(320, 568),
      textScale: 1.6,
      locale: const Locale('ru'),
    );

    expect(tester.takeException(), isNull);
  });

  // Renders the sheet's states side by side for a design check. Pass
  // `--dart-define=ORDER_DETAILS_PREVIEW_PATH=/path/sheet.png`.
  testWidgets('order details preview', (tester) async {
    const previewPath = String.fromEnvironment('ORDER_DETAILS_PREVIEW_PATH');
    if (previewPath.isEmpty) return;
    await _loadAppFonts(tester);
    final scenes = <(CustomerOrderModel, ThemeData)>[
      (_order(status: 'ON_THE_WAY', type: 'DELIVERY'), lightTheme),
      (_order(canReview: true), lightTheme),
      (
        _order(
          reviewRating: 5,
          review: _review(rating: 5, comment: 'Hot, fast and very tasty.'),
        ),
        lightTheme,
      ),
      (_order(canReview: true), darkTheme),
      (
        _order(
          status: 'NEW',
          paymentRetryAvailable: true,
          paymentStatus: 'FAILED',
        ),
        darkTheme,
      ),
    ];
    const size = Size(390, 1500);
    final images = <ui.Image>[];
    for (final (order, theme) in scenes) {
      final boundary = GlobalKey();
      await _openSheet(
        tester,
        _Repository(detail: order),
        order,
        size: size,
        theme: theme,
        boundary: boundary,
      );
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      images.add((await tester.runAsync(() => render.toImage(pixelRatio: 2)))!);
      await tester.pumpWidget(const SizedBox.shrink());
    }
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    for (var index = 0; index < images.length; index++) {
      canvas.drawImage(
        images[index],
        ui.Offset(index * size.width * 2, 0),
        ui.Paint(),
      );
    }
    final sheet = await tester.runAsync(
      () => recorder.endRecording().toImage(
        (size.width * 2 * images.length).round(),
        (size.height * 2).round(),
      ),
    );
    final bytes = await tester.runAsync(
      () => sheet!.toByteData(format: ui.ImageByteFormat.png),
    );
    await tester.runAsync(
      () => File(previewPath).writeAsBytes(bytes!.buffer.asUint8List()),
    );
  });
}

Future<void> _openSheet(
  WidgetTester tester,
  _Repository repository,
  CustomerOrderModel order, {
  Size size = const Size(390, 844),
  double textScale = 1,
  Locale locale = const Locale('en'),
  ThemeData? theme,
  GlobalKey? boundary,
  bool signedIn = false,
}) async {
  // The view itself, not only the surface: the sheet sizes itself from
  // MediaQuery.
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final controller = MobileBackendController(
    repository,
    MobilePushNotificationService(ApiClient(baseUrl: 'https://example.test')),
  );
  addTearDown(controller.dispose);
  if (signedIn) {
    // The sheet asks the server for the order only for a signed-in customer.
    unawaited(controller.bootstrap(language: locale.languageCode));
    await tester.pump();
    expect(controller.isAuthenticated, isTrue);
  }

  await tester.pumpWidget(
    RepaintBoundary(
      key: boundary,
      child: ChangeNotifierProvider<MobileBackendController>.value(
        value: controller,
        child: MaterialApp(
          theme: theme,
          locale: locale,
          supportedLocales: L.supportedLocales,
          localizationsDelegates: L.localizationsDelegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showProfileOrderDetailsSheet(
                  context: context,
                  order: order,
                  locale: locale.languageCode,
                  branches: <BranchModel>[_branch],
                  addresses: const [],
                ),
                child: const Text('Open order'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open order'));
  await tester.pumpAndSettle();
}

final BranchModel _branch = BranchModel.fromJson(const {
  'id': 'branch-1',
  'name': 'Enjoy Lavash Chilonzor',
  'address': 'Bunyodkor avenue, 12',
}, language: 'en');

CustomerOrderModel _order({
  String status = 'DELIVERED',
  String type = 'PICKUP',
  bool canReview = false,
  int? reviewRating,
  Map<String, Object?>? review,
  bool paymentRetryAvailable = false,
  String? paymentStatus,
}) {
  return CustomerOrderModel.fromJson({
    'id': '6d1f0c52-7a54-4c0e-9d55-0a1b2c3d4e5f',
    'type': type,
    'status': status,
    'paymentMethod': 'CASH',
    'branchId': 'branch-1',
    'paymentStatus': ?paymentStatus,
    'paymentRetryAvailable': paymentRetryAvailable,
    'totalAmount': 86000,
    'totalBeforePointsAmount': 96000,
    'loyaltyRedeemedAmount': 10000,
    'promoCode': 'LAVASH10',
    'comment': 'No onions, please',
    'createdAt': '2026-11-26T08:40:00.000Z',
    'updatedAt': '2026-11-26T09:12:00.000Z',
    'canReview': canReview,
    'reviewRating': ?reviewRating,
    'review': ?review,
    'items': [
      {
        'productId': 'lavash',
        'quantity': 2,
        'amount': 64000,
        'name': 'Chicken lavash',
        'comment': 'Extra sauce',
      },
      {'productId': 'cola', 'quantity': 1, 'amount': 12000, 'name': 'Cola'},
      {'productId': 'fries', 'quantity': 1, 'amount': 20000, 'name': 'Fries'},
    ],
    'statusLog': [
      {'status': 'NEW', 'changedAt': '2026-11-26T08:40:00.000Z'},
      {'status': 'CONFIRMED', 'changedAt': '2026-11-26T08:42:00.000Z'},
      {'status': 'COOKING', 'changedAt': '2026-11-26T08:45:00.000Z'},
      {'status': status, 'changedAt': '2026-11-26T09:12:00.000Z'},
    ],
  });
}

Map<String, Object?> _review({required int rating, String? comment}) {
  return {
    'id': 'review-1',
    'rating': rating,
    'comment': comment,
    'photos': const <Object?>[],
    'createdAt': '2026-11-26T09:30:00.000Z',
  };
}

class _Repository implements MobileBackendRepository {
  _Repository({this.detail, this.pendingDetail});

  final CustomerOrderModel? detail;
  final Future<Result<CustomerOrderModel>>? pendingDetail;
  CustomerOrderModel? reviewed;
  int? sentRating;

  @override
  Future<Result<MobileBootstrap>> bootstrap({
    required String language,
    String? branchId,
  }) async {
    return Success(
      MobileBootstrap(
        branches: const [],
        catalog: CatalogModel.fromJson(const {'categories': <Object?>[]}),
        paymentMethods: const [],
        client: ClientProfile.fromJson(const {
          'id': 'client-1',
          'fullName': 'Ali',
          'phoneNumber': '+998901234567',
          'language': 'en',
        }),
      ),
    );
  }

  @override
  Future<Result<CustomerOrderModel>> getOrder({required String id}) {
    return pendingDetail ?? Future.value(Success(reviewed ?? detail!));
  }

  @override
  Future<Result<CustomerOrderModel>> submitOrderReview({
    required String orderId,
    required int rating,
    String? comment,
    required List<String> photoPaths,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    sentRating = rating;
    return Success(reviewed!);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => Completer<Never>().future;
}

/// The preview is judged by eye, so it needs the app's real fonts and icons
/// instead of the test font's boxes.
Future<void> _loadAppFonts(WidgetTester tester) async {
  await tester.runAsync(() async {
    Future<ByteData> read(String path) async =>
        ByteData.sublistView(await File(path).readAsBytes());
    final flutterBin = File(Platform.resolvedExecutable).parent.path;
    final fonts = <String, String>{
      'Manrope': 'assets/fonts/Manrope-Variable.ttf',
      'GolosText': 'assets/fonts/GolosText-Variable.ttf',
      'MaterialIcons':
          '$flutterBin/../../material_fonts/MaterialIcons-Regular.otf',
    };
    for (final MapEntry(key: family, value: path) in fonts.entries) {
      if (!File(path).existsSync()) continue;
      await (FontLoader(family)..addFont(read(path))).load();
    }
  });
}
