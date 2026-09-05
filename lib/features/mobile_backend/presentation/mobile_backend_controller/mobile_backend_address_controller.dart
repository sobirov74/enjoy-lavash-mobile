part of '../mobile_backend_controller.dart';

extension _MobileBackendAddressController on MobileBackendController {
  Future<Result<List<ClientAddress>>> _refreshAddresses() async {
    final result = await _repository.getAddresses();
    switch (result) {
      case Success(:final data):
        _addresses = _sortedAddresses(data);
        _addressesFailure = null;
        _failure = null;
        _notifyListeners();
      case Error(:final failure):
        _addressesFailure = failure;
        _applyFailure(failure);
    }
    return result;
  }

  Future<Result<ClientAddress>> _createAddress(
    ClientAddressInput request,
  ) async {
    if (_addressesUpdating) {
      return const Error(
        ConflictFailure('An address update is already in progress.'),
      );
    }

    _addressesUpdating = true;
    _addressesFailure = null;
    _notifyListeners();
    try {
      final result = await _repository.createAddress(request);
      switch (result) {
        case Success(:final data):
          _upsertAddress(data);
          _failure = null;
        case Error(:final failure):
          _addressesFailure = failure;
          _applyFailure(failure, notify: false);
      }
      return result;
    } finally {
      _addressesUpdating = false;
      _notifyListeners();
    }
  }

  Future<Result<ClientAddress>> _updateAddress({
    required String id,
    required ClientAddressInput request,
  }) async {
    if (_addressesUpdating) {
      return const Error(
        ConflictFailure('An address update is already in progress.'),
      );
    }

    _addressesUpdating = true;
    _addressesFailure = null;
    _notifyListeners();
    try {
      final result = await _repository.updateAddress(id: id, request: request);
      switch (result) {
        case Success(:final data):
          _upsertAddress(data);
          _failure = null;
        case Error(:final failure):
          _addressesFailure = failure;
          _applyFailure(failure, notify: false);
      }
      return result;
    } finally {
      _addressesUpdating = false;
      _notifyListeners();
    }
  }

  Future<Result<void>> _deleteAddress({required String id}) async {
    if (_addressesUpdating) {
      return const Error(
        ConflictFailure('An address update is already in progress.'),
      );
    }

    _addressesUpdating = true;
    _addressesFailure = null;
    _notifyListeners();
    try {
      final result = await _repository.deleteAddress(id: id);
      switch (result) {
        case Success():
          _addresses = List<ClientAddress>.unmodifiable(
            _addresses.where((address) => address.id != id),
          );
          _failure = null;
        case Error(:final failure):
          _addressesFailure = failure;
          _applyFailure(failure, notify: false);
      }
      return result;
    } finally {
      _addressesUpdating = false;
      _notifyListeners();
    }
  }

  void _upsertAddress(ClientAddress updatedAddress) {
    final next = <ClientAddress>[
      updatedAddress,
      ..._addresses
          .where((address) => address.id != updatedAddress.id)
          .map(
            (address) => updatedAddress.isDefault
                ? _addressWithDefault(address, false)
                : address,
          ),
    ];
    _addresses = _sortedAddresses(next);
  }

  ClientAddress _addressWithDefault(ClientAddress address, bool isDefault) {
    return ClientAddress(
      id: address.id,
      label: address.label,
      street: address.street,
      houseNumber: address.houseNumber,
      apartmentNumber: address.apartmentNumber,
      entrance: address.entrance,
      floor: address.floor,
      doorCode: address.doorCode,
      latitude: address.latitude,
      longitude: address.longitude,
      comment: address.comment,
      isDefault: isDefault,
      createdAt: address.createdAt,
      updatedAt: address.updatedAt,
    );
  }

  List<ClientAddress> _sortedAddresses(Iterable<ClientAddress> addresses) {
    final next = addresses.toList(growable: false);
    next.sort((left, right) {
      if (left.isDefault == right.isDefault) return 0;
      return left.isDefault ? -1 : 1;
    });
    return List<ClientAddress>.unmodifiable(next);
  }
}
