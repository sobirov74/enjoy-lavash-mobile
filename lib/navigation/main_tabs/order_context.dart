part of 'package:enjoy_lavash_mobile/navigation/main_tabs.dart';

/// Delivery or pickup, the pickup branch, and the catalog and payment
/// methods that follow them.
extension _ShellOrderContext on _MainTabsState {
  Future<void> _openOrderContextPicker() {
    return showOrderContextSheet(
      context: context,
      currentType: _orderType,
      selectedBranch: _selectedBranch,
      branches: context.read<MobileBackendController>().branches,
      deliveryAddress: _currentDeliveryAddressText(),
      onTypeChanged: _setOrderType,
      onBranchSelected: _setPickupBranch,
    );
  }

  void _setOrderType(MobileOrderType type) {
    final shouldReloadCatalog =
        type == MobileOrderType.delivery && _selectedBranch != null;

    _updateState(() {
      _orderType = type;
      if (type == MobileOrderType.delivery) {
        _selectedBranch = null;
      } else {
        _deliveryBranchId = null;
      }
    });

    if (shouldReloadCatalog) {
      unawaited(_refreshCatalogForBranch(null));
    }
    if (type == MobileOrderType.delivery) {
      unawaited(_refreshPaymentMethodsForBranch(null));
    }
  }

  Future<void> _setPickupBranch(BranchModel? branch) async {
    _updateState(() {
      _selectedBranch = branch;
      if (branch != null) {
        _orderType = MobileOrderType.pickup;
      }
    });

    await Future.wait<void>([
      _refreshCatalogForBranch(branch?.id),
      _refreshPaymentMethodsForBranch(branch?.id),
    ]);
  }

  Future<void> _refreshCatalogForBranch(String? branchId) async {
    final language = context.read<LocaleController>().locale.languageCode;
    await context.read<MobileBackendController>().refreshCatalog(
      language: language,
      branchId: branchId,
    );
  }

  Future<void> _refreshPaymentMethodsForBranch(String? branchId) async {
    final language = context.read<LocaleController>().locale.languageCode;
    await context.read<MobileBackendController>().refreshPaymentMethods(
      language: language,
      branchId: branchId,
    );
  }

  Future<void> _refreshMenuData() {
    return context.read<MobileBackendController>().bootstrap(
      language: context.read<LocaleController>().locale.languageCode,
      branchId: _selectedBranch?.id,
    );
  }

  Future<void> _refreshProfileData() {
    return context.read<MobileBackendController>().refreshCustomerData();
  }

  String? _currentDeliveryAddressText() {
    final location = context.read<LocationController>();
    return deliveryAddressText(
      addressName: location.addressName,
      fullAddress: location.fullAddress,
      savedAddresses: context.read<MobileBackendController>().addresses,
    );
  }

  BranchModel? _branchById(String? id) {
    final branchId = id?.trim();
    if (branchId == null || branchId.isEmpty) return null;

    final selectedBranch = _selectedBranch;
    if (selectedBranch != null && selectedBranch.id == branchId) {
      return selectedBranch;
    }

    for (final branch in context.read<MobileBackendController>().branches) {
      if (branch.id == branchId) return branch;
    }
    return null;
  }
}
