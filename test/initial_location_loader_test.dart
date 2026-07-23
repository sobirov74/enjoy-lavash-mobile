import 'package:enjoy_lavash_mobile/app/app.dart';
import 'package:enjoy_lavash_mobile/app/location_controller.dart';
import 'package:enjoy_lavash_mobile/core/services/yandex_geocoder_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('loads the current location once after the first frame', (
    tester,
  ) async {
    final locationController = _TrackingLocationController();

    await tester.pumpWidget(
      ChangeNotifierProvider<LocationController>.value(
        value: locationController,
        child: const InitialLocationLoader(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(),
          ),
        ),
      ),
    );

    expect(locationController.requestCount, 1);

    await tester.pump();
    await tester.pump();

    expect(locationController.requestCount, 1);
  });
}

class _TrackingLocationController extends LocationController {
  _TrackingLocationController() : super(YandexGeocoderService());

  int requestCount = 0;

  @override
  Future<void> requestPermissionAndLocate() async {
    requestCount += 1;
  }
}
