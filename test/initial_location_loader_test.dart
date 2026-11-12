import 'dart:async';

import 'package:enjoy_lavash_mobile/app/app.dart';
import 'package:enjoy_lavash_mobile/app/locale_controller.dart';
import 'package:enjoy_lavash_mobile/app/location_controller.dart';
import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/services/mobile_push_notification_service.dart';
import 'package:enjoy_lavash_mobile/core/services/yandex_geocoder_service.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/repositories/mobile_backend_repository.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  late _TrackingLocationController locationController;
  late _TrackingBackendController backendController;
  late List<String> calls;

  setUp(() {
    calls = <String>[];
    locationController = _TrackingLocationController(calls);
    backendController = _TrackingBackendController(calls);
  });

  tearDown(() => backendController.dispose());

  Future<void> pumpLoader(WidgetTester tester) {
    return tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LocationController>.value(
            value: locationController,
          ),
          ChangeNotifierProvider<LocaleController>(
            create: (_) => LocaleController(),
          ),
          ChangeNotifierProvider<MobileBackendController>.value(
            value: backendController,
          ),
        ],
        child: const InitialLocationLoader(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(),
          ),
        ),
      ),
    );
  }

  testWidgets('loads the current location once after the first frame', (
    tester,
  ) async {
    await pumpLoader(tester);

    expect(locationController.requestCount, 1);

    await tester.pump();
    await tester.pump();

    expect(locationController.requestCount, 1);
  });

  testWidgets(
    'asks for notification permission once the location flow finished',
    (tester) async {
      await pumpLoader(tester);

      // The location dialog is still open: no second OS prompt yet.
      expect(backendController.permissionRequests, 0);

      locationController.finishLocation();
      await tester.pump();

      expect(backendController.permissionRequests, 1);
      expect(backendController.requestedLocale, 'uz');
      expect(calls, ['location', 'notifications']);

      await tester.pump();
      expect(backendController.permissionRequests, 1);
    },
  );
}

class _TrackingLocationController extends LocationController {
  _TrackingLocationController(this.calls) : super(YandexGeocoderService());

  final List<String> calls;
  int requestCount = 0;
  // Created inside the test's zone so completing it resumes the loader in
  // the same (fake async) zone.
  late final Completer<void> _location;

  void finishLocation() => _location.complete();

  @override
  Future<void> requestPermissionAndLocate({
    VoidCallback? onPermissionAnswered,
  }) {
    requestCount += 1;
    calls.add('location');
    _location = Completer<void>();
    return _location.future;
  }
}

class _TrackingBackendController extends MobileBackendController {
  _TrackingBackendController(this.calls)
    : super(
        _InertRepository(),
        MobilePushNotificationService(
          ApiClient(baseUrl: 'https://example.test'),
        ),
      );

  final List<String> calls;
  int permissionRequests = 0;
  String? requestedLocale;

  @override
  Future<void> requestPushNotificationPermission({String? locale}) async {
    permissionRequests += 1;
    requestedLocale = locale;
    calls.add('notifications');
  }
}

/// The loader never talks to the backend itself; any call fails loudly.
class _InertRepository implements MobileBackendRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError(invocation.memberName.toString());
  }
}
