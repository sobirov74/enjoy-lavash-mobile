part of 'package:enjoy_lavash_mobile/navigation/main_tabs.dart';

/// The checkout sheet's actions: destination pickers, payment and points
/// choices, branch working hours, and confirming the order.
extension _CheckoutSheetActions on _OrderConfirmationSheetState {
  Future<void> _confirmOrder() async {
    if (!_previewMatchesCurrentInput) {
      final didPreview = await _loadPreview();
      if (!didPreview || !mounted) return;
    }

    final branchId = _orderingBranchIdForCurrentInput;
    final loadedAt = _orderingStatusLoadedAt;
    final isStale =
        loadedAt == null ||
        DateTime.now().toUtc().difference(loadedAt) >
            const Duration(minutes: 2);
    if (branchId != null && isStale) {
      await _loadOrderingStatus(branchId, force: true);
      if (!mounted) return;
    }
    if (_relevantOrderingAvailability?.isOpen == false) return;

    Navigator.of(context).pop(
      _OrderCreationResult(
        orderType: _orderType,
        paymentMethod: _currentPaymentMethod,
        loyaltyRedemptionAmount: _requestedPoints,
        promoCode: _promoCodeForOrder,
        comment: _normalizedComment,
        deliveryTarget: _orderType == MobileOrderType.delivery
            ? _previewDetails?.deliveryTarget
            : null,
      ),
    );
  }

  Future<void> _showDeliveryAddressPicker() async {
    if (_isChangingDestination) return;

    if (_orderType != MobileOrderType.delivery) {
      _updateState(() {
        _orderType = MobileOrderType.delivery;
        _clearOrderingStatusState();
      });
    }

    _isChangingDestination = true;
    await showAddressBottomSheet(context);
    if (!mounted) return;
    _isChangingDestination = false;
    _previewInputVersion++;
    final deliveryAddressText = _currentDeliveryAddressText();

    if (!_hasDeliveryAddressInput()) {
      _updateState(() => _deliveryAddressText = deliveryAddressText);
      _showPreviewError(L.of(context).selectDeliveryAddressFirst);
      return;
    }

    _updateState(() => _deliveryAddressText = deliveryAddressText);
    unawaited(_loadPreview());
  }

  Future<void> _showPickupBranchPicker() async {
    if (_isChangingDestination) return;

    _isChangingDestination = true;
    final branch = await showBranchBottomSheet(
      context,
      selectedBranchId: _pickupBranchId,
    );
    if (!mounted) return;
    _isChangingDestination = false;
    if (branch == null) return;

    await widget.onBranchSelected(branch);
    if (!mounted) return;
    _previewInputVersion++;
    _updateState(() {
      _orderType = MobileOrderType.pickup;
      _pickupBranchId = branch.id;
      _pickupBranchText =
          trimmedOrNull(branch.name) ?? trimmedOrNull(branch.address);
    });
    unawaited(_loadOrderingStatus(branch.id, force: true));
    unawaited(_loadPreview());
  }

  void _clearOrderingStatusState() {
    _orderingStatusRefreshTimer?.cancel();
    _orderingStatusRefreshTimer = null;
    _orderingStatusRequestVersion++;
    _orderingStatus = null;
    _orderingStatusFailure = null;
    _orderingStatusBranchId = null;
    _orderingStatusLoadedAt = null;
    _orderingStatusLoading = false;
    _previewFailureBranchId = null;
  }

  Future<void> _loadOrderingStatus(
    String? branchId, {
    bool force = false,
  }) async {
    final normalized = branchId?.trim();
    if (normalized == null || normalized.isEmpty) return;
    if (!force &&
        _orderingStatusBranchId == normalized &&
        (_orderingStatus != null || _orderingStatusLoading)) {
      return;
    }

    _orderingStatusRefreshTimer?.cancel();
    _orderingStatusRefreshTimer = null;
    final requestVersion = ++_orderingStatusRequestVersion;
    _updateState(() {
      _orderingStatusBranchId = normalized;
      _orderingStatusLoading = true;
      _orderingStatusFailure = null;
      if (_orderingStatus?.branchId != normalized) {
        _orderingStatus = null;
        _orderingStatusLoadedAt = null;
      }
    });
    final result = await context
        .read<MobileBackendController>()
        .getBranchOrderingStatus(branchId: normalized);
    if (!mounted || requestVersion != _orderingStatusRequestVersion) return;
    switch (result) {
      case Success(:final data):
        _updateState(() {
          _orderingStatus = data;
          _orderingStatusFailure = null;
          _orderingStatusLoading = false;
          _orderingStatusLoadedAt = DateTime.now().toUtc();
        });
        _scheduleOrderingStatusRefresh(data, normalized);
      case Error(:final failure):
        _updateState(() {
          _orderingStatus = null;
          _orderingStatusFailure = failure;
          _orderingStatusLoading = false;
          _orderingStatusLoadedAt = DateTime.now().toUtc();
        });
    }
  }

  void _scheduleOrderingStatusRefresh(
    OrderingStatusModel status,
    String branchId,
  ) {
    _orderingStatusRefreshTimer?.cancel();
    _orderingStatusRefreshTimer = null;
    if (_orderingBranchIdForCurrentInput != branchId) return;

    final availability = _orderType == MobileOrderType.pickup
        ? status.pickup
        : status.delivery;
    if (availability.isOpen) return;

    const maximumDelay = Duration(minutes: 2);
    var delay = maximumDelay;
    final nextOpeningAt = availability.nextOpeningAt;
    if (nextOpeningAt != null) {
      final untilOpening = nextOpeningAt.difference(DateTime.now().toUtc());
      if (untilOpening > Duration.zero && untilOpening < maximumDelay) {
        delay = untilOpening + const Duration(seconds: 1);
      }
    }

    _orderingStatusRefreshTimer = Timer(delay, () {
      if (!mounted || _orderingBranchIdForCurrentInput != branchId) return;
      unawaited(_loadOrderingStatus(branchId, force: true));
    });
  }

  void _selectPaymentMethod(MobilePaymentMethod method) {
    if (_paymentMethod == method) return;
    _updateState(() => _paymentMethod = method);
    unawaited(_loadPreview());
  }

  void _useMaximumPoints() {
    final maximum =
        _previewDetails?.preview.loyalty?.maxPointsToSpend ??
        _maximumPointsToSpend;
    _pointsController.text = maximum.toString();
    _pointsController.selection = TextSelection.collapsed(
      offset: _pointsController.text.length,
    );
  }

  void _clearPoints() {
    _pointsController.text = '0';
    _pointsController.selection = const TextSelection.collapsed(offset: 1);
  }

  void _setUsePointsBalance(bool value) {
    if (_usePointsBalance == value) return;
    _updateState(() => _usePointsBalance = value);
    if (value) {
      _useMaximumPoints();
    } else {
      _clearPoints();
    }
  }

  Future<void> _retryPaymentMethods() async {
    final backend = context.read<MobileBackendController>();
    final branchId = _orderType == MobileOrderType.pickup
        ? _pickupBranchId
        : backend.paymentMethodsBranchId;
    await backend.refreshPaymentMethods(
      language: context.read<LocaleController>().locale.languageCode,
      branchId: branchId,
    );
    if (!mounted || backend.paymentMethods.isEmpty) return;
    unawaited(_loadPreview());
  }
}
