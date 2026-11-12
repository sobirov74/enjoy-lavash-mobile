import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:enjoy_lavash_mobile/core/services/yandex_geocoder_service.dart';
import 'package:enjoy_lavash_mobile/features/checkout/checkout_requests.dart';

enum LocationStatus { initial, loading, granted, denied, error }

class LocationController extends ChangeNotifier {
  LocationController(this._geocoderService);

  final YandexGeocoderService _geocoderService;

  LocationStatus _status = LocationStatus.initial;
  LocationStatus get status => _status;

  String _addressName = '';
  String get addressName => _addressName;

  String _district = '';
  String get district => _district;

  double? _latitude;
  double? get latitude => _latitude;

  double? _longitude;
  double? get longitude => _longitude;

  String _houseNumber = '';
  String get houseNumber => _houseNumber;

  String _entrance = '';
  String get entrance => _entrance;

  String _floor = '';
  String get floor => _floor;

  String _apartment = '';
  String get apartment => _apartment;

  String _comment = '';
  String get comment => _comment;

  /// Counts the points the customer chose themselves (map, address search)
  /// and sign-outs. A position lookup that started before one of these must
  /// not replace it when it finishes.
  int _pointRevision = 0;

  /// The point known on this device with its details, for checkout: one the
  /// customer picked, or the phone's position. Its coordinates and address
  /// always describe the same place; the phone's position has no address
  /// when the lookup failed. Null until a location is known.
  DeliveryPoint? get deliveryPoint {
    final latitude = _latitude;
    final longitude = _longitude;
    if (latitude == null || longitude == null) return null;
    return (
      latitude: latitude,
      longitude: longitude,
      addressName: _addressName,
      fullAddress: fullAddress,
      houseNumber: _houseNumber,
      apartment: _apartment,
      entrance: _entrance,
      floor: _floor,
      comment: _comment,
    );
  }

  String get fullAddress {
    final parts = <String>[_addressName];
    if (_houseNumber.isNotEmpty) parts.add(_houseNumber);
    return parts.join(', ');
  }

  /// Asks for location permission when it is undecided, then finds the
  /// current position and its address. [onPermissionAnswered] runs once the
  /// permission is known to be granted, before the lookup (which can take
  /// ten seconds), for callers that must not show another permission dialog
  /// on top of this one but need not wait for the position.
  Future<void> requestPermissionAndLocate({
    VoidCallback? onPermissionAnswered,
  }) async {
    if (_status == LocationStatus.loading) return;

    _setStatus(LocationStatus.loading);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setStatus(LocationStatus.error);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setStatus(LocationStatus.denied);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setStatus(LocationStatus.denied);
        return;
      }

      onPermissionAnswered?.call();
      final didLocate = await _fetchCurrentLocation();
      if (didLocate) {
        _setStatus(LocationStatus.granted);
      }
    } catch (error, stackTrace) {
      debugPrint('Location permission flow failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _setStatus(LocationStatus.error);
    }
  }

  Future<bool> _fetchCurrentLocation() => locateAndApply();

  /// Where the phone is now. Tests replace it.
  @protected
  Future<({double latitude, double longitude})> locatePhone() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
    return (latitude: position.latitude, longitude: position.longitude);
  }

  /// Finds the phone's position and its address and makes them the current
  /// point, keeping coordinates and address about the same place:
  /// - a point the customer picked while this ran stays (their choice wins
  ///   over a lookup that started earlier);
  /// - when the address lookup fails and an address is already on screen,
  ///   that address stays with its own coordinates: a position must never
  ///   be sent under another place's name;
  /// - when it fails and there is no address, only the coordinates are kept
  ///   (checkout then prefers a saved address, see `resolveDeliveryTarget`).
  @visibleForTesting
  Future<bool> locateAndApply() async {
    final revision = _pointRevision;
    try {
      final position = await locatePhone();
      final address = await resolveAddressName(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (revision != _pointRevision) return true;

      if (address != null) {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _addressName = address.name;
        _district = address.district;
      } else if (_addressName.trim().isEmpty) {
        _latitude = position.latitude;
        _longitude = position.longitude;
      }
      return true;
    } catch (_) {
      _setStatus(LocationStatus.error);
      return false;
    }
  }

  Future<void> setAddressFromSuggestion(SuggestionResult suggestion) async {
    _pointRevision++;
    _addressName = suggestion.title;
    notifyListeners();

    if (suggestion.uri != null) {
      final result = await resolveAddressName(
        latitude: 0,
        longitude: 0,
        uri: suggestion.uri,
      );
      if (result != null) {
        _addressName = result.name;
        _district = result.district;
        if (result.coords.length == 2) {
          _longitude = result.coords[0];
          _latitude = result.coords[1];
        }
        notifyListeners();
      }
    }
  }

  void setFromMap({
    required double latitude,
    required double longitude,
    required String address,
    String district = '',
  }) {
    _pointRevision++;
    _latitude = latitude;
    _longitude = longitude;
    _addressName = address;
    _district = district;
    notifyListeners();
  }

  /// Address autocomplete through the app-wide geocoder (one HTTP client).
  Future<List<SuggestionResult>> suggestAddresses(String query) {
    return _geocoderService.suggest(query);
  }

  Future<GeocoderResult?> resolveAddressName({
    required double latitude,
    required double longitude,
    String? uri,
  }) {
    return _geocoderService.reverseGeocode(
      latitude: latitude,
      longitude: longitude,
      uri: uri,
    );
  }

  /// Updates the apartment details together, notifying once and only when
  /// something changed. The address sheet commits here when it closes instead
  /// of notifying (and rebuilding the menu) on every keystroke.
  void setAddressDetails({
    required String houseNumber,
    required String entrance,
    required String floor,
    required String apartment,
    required String comment,
  }) {
    if (houseNumber == _houseNumber &&
        entrance == _entrance &&
        floor == _floor &&
        apartment == _apartment &&
        comment == _comment) {
      return;
    }
    _houseNumber = houseNumber;
    _entrance = entrance;
    _floor = floor;
    _apartment = apartment;
    _comment = comment;
    notifyListeners();
  }

  void setHouseNumber(String value) {
    _houseNumber = value;
    notifyListeners();
  }

  void setEntrance(String value) {
    _entrance = value;
    notifyListeners();
  }

  void setFloor(String value) {
    _floor = value;
    notifyListeners();
  }

  void setApartment(String value) {
    _apartment = value;
    notifyListeners();
  }

  void setComment(String value) {
    _comment = value;
    notifyListeners();
  }

  void clearPersonalData() {
    _pointRevision++;
    _status = LocationStatus.initial;
    _addressName = '';
    _district = '';
    _latitude = null;
    _longitude = null;
    _houseNumber = '';
    _entrance = '';
    _floor = '';
    _apartment = '';
    _comment = '';
    notifyListeners();
  }

  void _setStatus(LocationStatus status) {
    _status = status;
    notifyListeners();
  }
}
