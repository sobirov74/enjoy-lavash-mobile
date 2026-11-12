// The point the location controller hands to checkout: its coordinates and
// its address always describe the same place.

import 'dart:async';

import 'package:enjoy_lavash_mobile/app/location_controller.dart';
import 'package:enjoy_lavash_mobile/core/services/yandex_geocoder_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a found position and its address are taken together', () async {
    final location = _Controller()
      ..position = (latitude: 41.3, longitude: 69.2)
      ..address = const GeocoderResult(
        name: 'Navoi 5',
        district: 'Shayxontohur',
        coords: [69.2, 41.3],
      );

    expect(await location.locateAndApply(), isTrue);

    expect(location.deliveryPoint!.latitude, 41.3);
    expect(location.addressName, 'Navoi 5');
    expect(location.district, 'Shayxontohur');
  });

  test('a position whose address lookup fails does not go out under the '
      'address already on screen', () async {
    final location = _Controller()
      ..setFromMap(latitude: 41.1, longitude: 69.1, address: 'Street A')
      ..position = (latitude: 41.9, longitude: 69.9)
      ..address = null;

    expect(await location.locateAndApply(), isTrue);

    // "Street A" keeps its own coordinates.
    expect(location.addressName, 'Street A');
    expect(location.deliveryPoint!.latitude, 41.1);
    expect(location.deliveryPoint!.longitude, 69.1);
  });

  test('without any address the bare position is kept', () async {
    final location = _Controller()
      ..position = (latitude: 41.9, longitude: 69.9)
      ..address = null;

    expect(await location.locateAndApply(), isTrue);

    expect(location.addressName, isEmpty);
    expect(location.deliveryPoint!.latitude, 41.9);
  });

  test(
    'a point picked while the phone was being located is not replaced',
    () async {
      final location = _Controller()
        ..address = const GeocoderResult(
          name: 'Where the phone is',
          district: '',
          coords: [69.9, 41.9],
        );
      final found = Completer<({double latitude, double longitude})>();
      location.pendingPosition = found;

      // The start-up lookup is running; the customer picks a point on the map.
      final lookup = location.locateAndApply();
      location.setFromMap(latitude: 41.1, longitude: 69.1, address: 'Picked');
      found.complete((latitude: 41.9, longitude: 69.9));
      await lookup;

      expect(location.addressName, 'Picked');
      expect(location.deliveryPoint!.latitude, 41.1);
    },
  );

  test(
    'a failed position lookup reports an error and changes nothing',
    () async {
      final location = _Controller()
        ..setFromMap(latitude: 41.1, longitude: 69.1, address: 'Street A')
        ..positionError = StateError('no fix');

      expect(await location.locateAndApply(), isFalse);

      expect(location.status, LocationStatus.error);
      expect(location.addressName, 'Street A');
    },
  );
}

class _Controller extends LocationController {
  _Controller() : super(YandexGeocoderService());

  ({double latitude, double longitude}) position = (latitude: 0, longitude: 0);
  Completer<({double latitude, double longitude})>? pendingPosition;
  Object? positionError;
  GeocoderResult? address;

  @override
  Future<({double latitude, double longitude})> locatePhone() async {
    final error = positionError;
    if (error != null) throw error;
    return pendingPosition?.future ?? position;
  }

  @override
  Future<GeocoderResult?> resolveAddressName({
    required double latitude,
    required double longitude,
    String? uri,
  }) async => address;
}
