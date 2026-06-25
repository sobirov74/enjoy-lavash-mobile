import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:enjoy_lavash_mobile/core/services/yandex_geocoder_service.dart';

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

  String get fullAddress {
    final parts = <String>[_addressName];
    if (_houseNumber.isNotEmpty) parts.add(_houseNumber);
    return parts.join(', ');
  }

  Future<void> requestPermissionAndLocate() async {
    _status = LocationStatus.loading;
    notifyListeners();

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _status = LocationStatus.error;
      notifyListeners();
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _status = LocationStatus.denied;
        notifyListeners();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _status = LocationStatus.denied;
      notifyListeners();
      return;
    }

    _status = LocationStatus.granted;
    notifyListeners();

    await _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      _latitude = position.latitude;
      _longitude = position.longitude;

      final result = await resolveAddressName(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (result != null) {
        _addressName = result.name;
        _district = result.district;
      }

      notifyListeners();
    } catch (_) {
      _status = LocationStatus.error;
      notifyListeners();
    }
  }

  Future<void> setAddressFromSuggestion(SuggestionResult suggestion) async {
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
    _latitude = latitude;
    _longitude = longitude;
    _addressName = address;
    _district = district;
    notifyListeners();
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
}
