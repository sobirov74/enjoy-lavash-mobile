part of 'package:enjoy_lavash_mobile/screens/menu_screen.dart';

/// The order-context pill: delivery address or pickup branch, and its picker.
extension _MenuOrderContext on _MenuScreenState {
  ClientAddress? _defaultAddress(List<ClientAddress> addresses) {
    if (addresses.isEmpty) return null;

    for (final address in addresses) {
      if (address.isDefault) return address;
    }
    return addresses.first;
  }

  String? _formatSavedAddress(ClientAddress? address) {
    if (address == null) return null;

    final parts = <String>[
      if (address.street.trim().isNotEmpty) address.street.trim(),
      if (address.houseNumber?.trim().isNotEmpty == true)
        address.houseNumber!.trim(),
      if (address.apartmentNumber?.trim().isNotEmpty == true)
        address.apartmentNumber!.trim(),
    ];
    if (parts.isNotEmpty) return parts.join(', ');

    final label = address.label.trim();
    return label.isEmpty ? null : label;
  }

  /// Delivery address shown on the order-context pill. Build code passes
  /// selected slices so the menu rebuilds only when the address itself
  /// changes; event handlers pass values read once.
  String? _deliveryButtonSubtitle({
    required String addressName,
    required String fullAddress,
    required List<ClientAddress> addresses,
  }) {
    if (addressName.trim().isNotEmpty) {
      final full = fullAddress.trim();
      return full.isEmpty ? addressName.trim() : full;
    }
    return _formatSavedAddress(_defaultAddress(addresses));
  }

  String? _watchedDeliverySubtitle(BuildContext context) {
    final (addressName, fullAddress) = context
        .select<LocationController, (String, String)>(
          (location) => (location.addressName, location.fullAddress),
        );
    // Saved addresses matter only when nothing was picked on this device.
    if (addressName.trim().isNotEmpty) {
      return _deliveryButtonSubtitle(
        addressName: addressName,
        fullAddress: fullAddress,
        addresses: const <ClientAddress>[],
      );
    }
    final addresses = context
        .select<MobileBackendController, List<ClientAddress>>(
          (backend) => backend.addresses,
        );
    return _deliveryButtonSubtitle(
      addressName: addressName,
      fullAddress: fullAddress,
      addresses: addresses,
    );
  }

  String? _currentDeliverySubtitle() {
    final location = context.read<LocationController>();
    return _deliveryButtonSubtitle(
      addressName: location.addressName,
      fullAddress: location.fullAddress,
      addresses: context.read<MobileBackendController>().addresses,
    );
  }

  String _orderContextLabel(L t) {
    if (widget.orderType == MobileOrderType.pickup) {
      final branchName = widget.selectedBranch?.name.trim();
      return branchName?.isNotEmpty == true ? branchName! : t.pickupBranch;
    }
    return _watchedDeliverySubtitle(context) ?? t.tapToSelectAddress;
  }

  Future<void> _showOrderContextPicker() async {
    final backend = context.read<MobileBackendController>();
    await showOrderContextSheet(
      context: context,
      currentType: widget.orderType,
      selectedBranch: widget.selectedBranch,
      branches: backend.branches,
      deliveryAddress: _currentDeliverySubtitle(),
      onTypeChanged: widget.onOrderTypeChanged,
      onBranchSelected: widget.onBranchSelected,
    );
  }
}
