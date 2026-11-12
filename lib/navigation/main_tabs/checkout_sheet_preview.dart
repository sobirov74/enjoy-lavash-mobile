part of 'package:enjoy_lavash_mobile/navigation/main_tabs.dart';

/// The checkout sheet's price preview: debounced reloads on input changes,
/// stale-answer checks, and its error states.
extension _CheckoutSheetPreview on _OrderConfirmationSheetState {
  void _onPromoCodeChanged() {
    if (!mounted) return;
    _invalidateAndSchedulePreview();
  }

  void _onPointsChanged() {
    if (!mounted) return;
    _invalidateAndSchedulePreview();
  }

  void _invalidateAndSchedulePreview() {
    _previewInputVersion++;
    _updateState(() {
      _previewErrorText = null;
      _previewFailure = null;
      _previewFailureBranchId = null;
      _previewDetails = null;
    });
    _previewDebounce?.cancel();
    _previewDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted || _isChangingDestination) return;
      unawaited(_loadPreview());
    });
  }

  Future<bool> _loadPreview() async {
    if (_isPreviewLoading || _isChangingDestination) return false;
    _previewDebounce?.cancel();

    final orderType = _orderType;
    final paymentMethod = _currentPaymentMethod;
    if (!_isUsablePaymentMethod(paymentMethod)) {
      return _showPreviewError(L.of(context).paymentMethodsUnavailable);
    }
    final promoCode = _normalizedPromoCode;
    final loyaltyRedemptionAmount = _requestedPoints;
    final inputVersion = _previewInputVersion;
    _updateState(() {
      _isPreviewLoading = true;
      _previewErrorText = null;
      _previewFailure = null;
      _previewFailureBranchId = null;
      _previewDetails = null;
    });

    final result = await widget.onPreviewRequested(
      orderType: orderType,
      paymentMethod: paymentMethod,
      promoCode: promoCode,
      loyaltyRedemptionAmount: loyaltyRedemptionAmount,
    );
    if (!mounted) return false;

    if (orderType != _orderType ||
        paymentMethod != _currentPaymentMethod ||
        promoCode != _normalizedPromoCode ||
        loyaltyRedemptionAmount != _requestedPoints ||
        inputVersion != _previewInputVersion) {
      _updateState(() => _isPreviewLoading = false);
      if (!_isChangingDestination) {
        unawaited(_loadPreview());
      }
      return false;
    }

    if (result == null) {
      _updateState(() => _isPreviewLoading = false);
      return false;
    }

    return switch (result) {
      Success(:final data) => _applyPreview(
        data,
        orderType,
        paymentMethod,
        promoCode,
        loyaltyRedemptionAmount,
        inputVersion,
      ),
      Error(:final failure) => _showPreviewFailure(failure),
    };
  }

  bool _applyPreview(
    _CheckoutPreviewDetails details,
    MobileOrderType orderType,
    MobilePaymentMethod paymentMethod,
    String? promoCode,
    int loyaltyRedemptionAmount,
    int inputVersion,
  ) {
    final maximumPointsToSpend = details.preview.loyalty?.maxPointsToSpend ?? 0;
    _updateState(() {
      _paymentMethod = paymentMethod;
      _previewDetails = details;
      _maximumPointsToSpend = maximumPointsToSpend;
      _lastPreviewOrderType = orderType;
      _lastPreviewPaymentMethod = paymentMethod;
      _lastPreviewPromoCode = promoCode;
      _lastPreviewLoyaltyPoints = loyaltyRedemptionAmount;
      _lastPreviewInputVersion = inputVersion;
      _previewErrorText = null;
      _previewFailure = null;
      _previewFailureBranchId = null;
      _isPreviewLoading = false;
    });
    final previewBranchId = details.preview.branchId?.trim();
    if (previewBranchId?.isNotEmpty == true &&
        previewBranchId != _orderingStatusBranchId) {
      unawaited(_loadOrderingStatus(previewBranchId));
    }
    return true;
  }

  bool _showPreviewError(String message) {
    _updateState(() {
      _previewDetails = null;
      _previewErrorText = message;
      _previewFailure = null;
      _previewFailureBranchId = null;
      _isPreviewLoading = false;
    });
    return false;
  }

  bool _showPreviewFailure(Failure failure) {
    final metadata =
        failure is ServerFailure && failure.errorCode == orderingClosedErrorCode
        ? OrderingClosedMetadataModel.fromJson(failure.metadata)
        : null;
    final branchId = trimmedOrNull(metadata?.branchId);
    _updateState(() {
      _previewDetails = null;
      _previewErrorText = null;
      _previewFailure = failure;
      _previewFailureBranchId = branchId;
      _isPreviewLoading = false;
    });
    if (branchId != null) {
      unawaited(_loadOrderingStatus(branchId, force: true));
    }
    return false;
  }

  String _previewFailureMessage(Failure failure) {
    final t = L.of(context);
    if (failure is ServerFailure &&
        failure.errorCode == orderingClosedErrorCode) {
      final metadata = OrderingClosedMetadataModel.fromJson(failure.metadata);
      return _nextOpeningText(
        context,
        nextOpeningAt: metadata.nextOpeningAt,
        timezone: metadata.timezone,
      );
    }
    return failureMessage(t, failure, fallback: t.couldNotCalculateTotal);
  }
}
