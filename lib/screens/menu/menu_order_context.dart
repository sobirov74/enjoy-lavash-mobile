part of 'package:enjoy_lavash_mobile/screens/menu_screen.dart';

/// The order-context pill: delivery address or pickup branch, and its picker.
extension _MenuOrderContext on _MenuScreenState {
  /// Delivery address shown on the order-context pill, the same text Home
  /// and checkout show ([deliveryAddressText]). Selected in slices so the
  /// menu rebuilds only when the address itself changes.
  String? _watchedDeliverySubtitle(BuildContext context) {
    final (addressName, fullAddress) = context
        .select<LocationController, (String, String)>(
          (location) => (location.addressName, location.fullAddress),
        );
    // Saved addresses matter only when nothing was picked on this device.
    if (addressName.trim().isNotEmpty) {
      return deliveryAddressText(
        addressName: addressName,
        fullAddress: fullAddress,
        savedAddresses: const <ClientAddress>[],
      );
    }
    final addresses = context
        .select<MobileBackendController, List<ClientAddress>>(
          (backend) => backend.addresses,
        );
    return deliveryAddressText(
      addressName: addressName,
      fullAddress: fullAddress,
      savedAddresses: addresses,
    );
  }

  String? _currentDeliverySubtitle() {
    final location = context.read<LocationController>();
    return deliveryAddressText(
      addressName: location.addressName,
      fullAddress: location.fullAddress,
      savedAddresses: context.read<MobileBackendController>().addresses,
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
