part of 'package:enjoy_lavash_mobile/navigation/main_tabs.dart';

/// Checkout: preview and order requests, the confirmation sheet, order
/// creation with its error dialog, and the success screen.
extension _ShellCheckout on _MainTabsState {
  /// Where a delivery goes now (see [resolveDeliveryTarget]). With nothing
  /// to go by, the address sheet is shown once so the customer can choose.
  Future<DeliveryTarget?> _deliveryTargetOrAsk() async {
    DeliveryTarget? current() => resolveDeliveryTarget(
      point: context.read<LocationController>().deliveryPoint,
      savedAddresses: context.read<MobileBackendController>().addresses,
    );

    final target = current();
    if (target != null) return target;
    await showAddressBottomSheet(context);
    if (!mounted) return null;
    return current();
  }

  /// [previewed] with the latest door details when the phone still stands
  /// for the same place. The details (apartment, entrance, comment) may be
  /// edited after the preview, which is priced by coordinates only; the
  /// place itself must stay the one that was priced.
  DeliveryPoint _withLatestDetails(DeliveryPoint previewed) {
    final current = context.read<LocationController>().deliveryPoint;
    return current != null &&
            current.latitude == previewed.latitude &&
            current.longitude == previewed.longitude
        ? current
        : previewed;
  }

  _CheckoutAddressDetails? _checkoutAddressDetails(CartPreviewRequest request) {
    final addresses = context.read<MobileBackendController>().addresses;
    final requestedAddressId = trimmedOrNull(request.addressId);
    if (requestedAddressId != null) {
      for (final address in addresses) {
        if (address.id == requestedAddressId) {
          return _CheckoutAddressDetails(
            label: trimmedOrNull(address.label),
            text: clientAddressText(address),
          );
        }
      }
    }

    final input = request.address;
    if (input == null) return null;

    final location = context.read<LocationController>();
    if (_coordinatesMatch(
      input.latitude,
      input.longitude,
      location.latitude,
      location.longitude,
    )) {
      final label = trimmedOrNull(location.addressName);
      final text = trimmedOrNull(location.fullAddress) ?? label;
      if (label != null || text != null) {
        return _CheckoutAddressDetails(label: label, text: text);
      }
    }

    for (final address in addresses) {
      if (_coordinatesMatch(
        input.latitude,
        input.longitude,
        address.latitude,
        address.longitude,
      )) {
        return _CheckoutAddressDetails(
          label: trimmedOrNull(address.label),
          text: clientAddressText(address),
        );
      }
    }

    // A point without an address is only sent when nothing is saved (see
    // resolveDeliveryTarget); its coordinates are all there is to show.
    return _CheckoutAddressDetails(
      text:
          '${input.latitude.toStringAsFixed(5)}, '
          '${input.longitude.toStringAsFixed(5)}',
    );
  }

  bool _coordinatesMatch(
    double latitude,
    double longitude,
    double? otherLatitude,
    double? otherLongitude,
  ) {
    if (otherLatitude == null || otherLongitude == null) return false;
    return (latitude - otherLatitude).abs() < 0.000001 &&
        (longitude - otherLongitude).abs() < 0.000001;
  }

  _CheckoutPreviewDetails _checkoutPreviewDetails({
    required CartPreviewRequest request,
    required CartPreviewModel preview,
    required DeliveryTarget? deliveryTarget,
  }) {
    final branchId = request.type == MobileOrderType.pickup
        ? request.branchId
        : preview.branchId;
    final branch = _branchById(branchId);

    return _CheckoutPreviewDetails(
      preview: preview,
      orderType: request.type,
      branchName: trimmedOrNull(branch?.name),
      branchAddress: trimmedOrNull(branch?.address),
      address: request.type == MobileOrderType.delivery
          ? _checkoutAddressDetails(request)
          : null,
      deliveryTarget: deliveryTarget,
    );
  }

  Future<_OrderFailureAction> _showOrderCreationError(
    Failure failure, {
    bool allowRetry = false,
    bool allowRemovePoints = false,
  }) async {
    if (!mounted) return _OrderFailureAction.close;

    final t = L.of(context);
    final title = switch (failure) {
      AuthFailure() => t.errorAuthorizationExpired,
      NetworkFailure() => t.errorConnectionProblem,
      TimeoutFailure() => t.errorSlowNetwork,
      ServerFailure(errorCode: orderingClosedErrorCode) => t.orderingClosed,
      ServerFailure() => t.errorBackend,
      _ => t.errorGenericTitle,
    };
    final orderingClosedMessage =
        failure is ServerFailure && failure.errorCode == orderingClosedErrorCode
        ? _orderingClosedMessage(failure)
        : null;
    final message =
        orderingClosedMessage ??
        failureDetail(t, failure, fallback: t.orderCreateFailed);

    return await showDialog<_OrderFailureAction>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            scrollable: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            title: Row(
              children: <Widget>[
                const Icon(
                  Icons.error_outline_rounded,
                  color: BaseColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TypographyText(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            content: SelectableText(
              message,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
            actions: <Widget>[
              TextButton.icon(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(_OrderFailureAction.close),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: TypographyText(t.close),
              ),
              if (allowRemovePoints)
                TextButton.icon(
                  onPressed: () => Navigator.of(
                    dialogContext,
                  ).pop(_OrderFailureAction.removePoints),
                  icon: const Icon(Icons.stars_outlined, size: 18),
                  label: TypographyText(t.continueWithoutPoints),
                ),
              if (allowRetry)
                FilledButton.icon(
                  onPressed: () => Navigator.of(
                    dialogContext,
                  ).pop(_OrderFailureAction.retry),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: TypographyText(t.retry),
                ),
            ],
          ),
        ) ??
        _OrderFailureAction.close;
  }

  String _orderingClosedMessage(ServerFailure failure) {
    final metadata = OrderingClosedMetadataModel.fromJson(failure.metadata);
    return _nextOpeningText(
      context,
      nextOpeningAt: metadata.nextOpeningAt,
      timezone: metadata.timezone,
    );
  }

  /// The preview request and, for delivery, the target it is priced for.
  Future<({CartPreviewRequest request, DeliveryTarget? deliveryTarget})?>
  _buildCartPreviewRequest(
    List<CartLine> cartLines, {
    required MobileOrderType orderType,
    required MobilePaymentMethod paymentMethod,
    int loyaltyRedemptionAmount = 0,
    String? promoCode,
  }) async {
    final t = L.of(context);
    final items = checkoutItems(cartLines);
    final normalizedPromoCode = trimmedOrNull(promoCode);

    if (orderType == MobileOrderType.pickup) {
      var branch = _selectedBranch;
      if (branch == null) {
        branch = await showBranchBottomSheet(context);
        if (!mounted) return null;
        if (branch != null) {
          await _setPickupBranch(branch);
        }
      }

      if (branch == null) {
        _showSnack(t.selectPickupBranchFirst);
        return null;
      }

      return (
        request: CartPreviewRequest(
          type: MobileOrderType.pickup,
          branchId: branch.id,
          items: items,
          paymentMethod: paymentMethod,
          promoCode: normalizedPromoCode,
          loyaltyRedemptionAmount: loyaltyRedemptionAmount,
        ),
        deliveryTarget: null,
      );
    }

    final target = await _deliveryTargetOrAsk();
    if (!mounted) return null;
    if (target == null) {
      _showSnack(t.selectDeliveryAddressFirst);
      return null;
    }

    final point = target.point;
    return (
      request: CartPreviewRequest(
        type: MobileOrderType.delivery,
        addressId: target.addressId,
        address: point == null ? null : previewDeliveryAddress(point),
        items: items,
        paymentMethod: paymentMethod,
        promoCode: normalizedPromoCode,
        loyaltyRedemptionAmount: loyaltyRedemptionAmount,
      ),
      deliveryTarget: target,
    );
  }

  Future<Result<_CheckoutPreviewDetails>?> _previewCartForCheckout(
    List<CartLine> cartLines, {
    required MobileOrderType orderType,
    required MobilePaymentMethod paymentMethod,
    required int loyaltyRedemptionAmount,
    String? promoCode,
  }) async {
    final built = await _buildCartPreviewRequest(
      cartLines,
      orderType: orderType,
      paymentMethod: paymentMethod,
      promoCode: promoCode,
      loyaltyRedemptionAmount: loyaltyRedemptionAmount,
    );
    if (!mounted || built == null) return null;
    final request = built.request;

    _logOrderPreview('request', request.toJson());
    final backend = context.read<MobileBackendController>();
    final result = await backend.previewCart(request);
    if (result case Success(:final data)) {
      _logOrderPreview('response', _cartPreviewLogPayload(data));
      final branchId = data.branchId?.trim();
      if (orderType == MobileOrderType.delivery) {
        _deliveryBranchId = branchId?.isNotEmpty == true ? branchId : null;
        final paymentMethodsBranchId = backend.paymentMethodsBranchId?.trim();
        if (_deliveryBranchId != null &&
            paymentMethodsBranchId != _deliveryBranchId) {
          unawaited(_refreshPaymentMethodsForBranch(_deliveryBranchId));
        }
      }
      return Success(
        _checkoutPreviewDetails(
          request: request,
          preview: data,
          deliveryTarget: built.deliveryTarget,
        ),
      );
    }
    if (result case Error(:final failure)) {
      _logOrderPreview('error', {
        'type': failure.runtimeType.toString(),
        'message': failure.message,
      });
      return Error<_CheckoutPreviewDetails>(failure);
    }
    return null;
  }

  void _logOrderPreview(String label, Object? payload) {
    _logCheckoutPayload('OrderPreview', label, payload);
  }

  void _logOrderCreation(String label, Object? payload) {
    _logCheckoutPayload('OrderCreate', label, payload);
  }

  /// Debug builds only. Checkout payloads carry the delivery address, door
  /// code and payment link, which must never reach the device log in release.
  void _logCheckoutPayload(String scope, String label, Object? payload) {
    if (!kDebugMode) return;
    final redacted = redactSensitiveLogFields(payload);
    try {
      const encoder = JsonEncoder.withIndent('  ');
      debugPrint('[$scope] $label:\n${encoder.convert(redacted)}');
    } catch (_) {
      debugPrint('[$scope] $label: $redacted');
    }
  }

  Map<String, Object?> _cartPreviewLogPayload(CartPreviewModel preview) {
    return {
      'branchId': preview.branchId,
      'deliveryDistanceMeters': preview.deliveryDistanceMeters,
      'deliveryDistanceSource': preview.deliveryDistanceSource.value,
      'itemsAmount': preview.itemsAmount,
      'modifiersAmount': preview.modifiersAmount,
      'discountAmount': preview.discountAmount,
      'deliveryAmount': preview.deliveryAmount,
      'promotionDeliveryDiscountAmount':
          preview.promotionDeliveryDiscountAmount,
      'serviceFeeAmount': preview.serviceFeeAmount,
      'totalAmount': preview.totalAmount,
      'totalBeforePointsAmount': preview.totalBeforePointsAmount,
      'loyalty': preview.loyalty == null
          ? null
          : {
              'requestedPoints': preview.loyalty!.requestedPoints,
              'appliedPoints': preview.loyalty!.appliedPoints,
              'maxPointsToSpend': preview.loyalty!.maxPointsToSpend,
              'estimatedEarnPoints': preview.loyalty!.estimatedEarnPoints,
            },
      'promotionStatus': preview.hasPromotionStatus
          ? preview.promotionStatus.value
          : null,
      'promotionStatusReason': preview.promotionStatusReason,
      'bonusItems': preview.bonusItems,
      'appliedPromotion': preview.appliedPromotion == null
          ? null
          : {
              'id': preview.appliedPromotion!.id,
              'code': preview.appliedPromotion!.code,
              'title': preview.appliedPromotion!.title,
              'discountAmount': preview.appliedPromotion!.discountAmount,
            },
    };
  }

  Future<CreateOrderRequest?> _buildCreateOrderRequest(
    List<CartLine> cartLines, {
    required MobileOrderType orderType,
    required MobilePaymentMethod paymentMethod,
    int loyaltyRedemptionAmount = 0,
    String? promoCode,
    String? comment,
    DeliveryTarget? previewedTarget,
  }) async {
    final t = L.of(context);
    final items = checkoutItems(cartLines);
    final normalizedPromoCode = trimmedOrNull(promoCode);
    final normalizedComment = trimmedOrNull(comment);

    if (orderType == MobileOrderType.pickup) {
      var branch = _selectedBranch;
      if (branch == null) {
        branch = await showBranchBottomSheet(context);
        if (!mounted) return null;
        if (branch != null) {
          await _setPickupBranch(branch);
        }
      }

      if (branch == null) {
        _showSnack(t.selectPickupBranchFirst);
        return null;
      }

      return CreateOrderRequest(
        type: MobileOrderType.pickup,
        branchId: branch.id,
        items: items,
        paymentMethod: paymentMethod,
        promoCode: normalizedPromoCode,
        comment: normalizedComment,
        loyaltyRedemptionAmount: loyaltyRedemptionAmount,
      );
    }

    // The order goes where the confirmed preview was priced for. The
    // phone's position may have changed since (the start-up GPS fix can
    // land while the sheet is open), and the fee and branch would not match.
    final target = previewedTarget ?? await _deliveryTargetOrAsk();
    if (!mounted) return null;
    if (target == null) {
      _showSnack(t.selectDeliveryAddressFirst);
      return null;
    }

    final point = target.point;
    return CreateOrderRequest(
      type: MobileOrderType.delivery,
      address: point == null
          ? null
          : inlineOrderAddress(_withLatestDetails(point)),
      addressId: target.addressId,
      branchId: point == null ? null : _deliveryBranchId,
      items: items,
      paymentMethod: paymentMethod,
      promoCode: normalizedPromoCode,
      comment: normalizedComment,
      loyaltyRedemptionAmount: loyaltyRedemptionAmount,
    );
  }

  Future<_OrderCreationResult?> _showOrderConfirmation(
    List<CartLine> cartLines,
  ) async {
    return Navigator.of(context).push<_OrderCreationResult>(
      MaterialPageRoute<_OrderCreationResult>(
        builder: (context) => _OrderConfirmationSheet(
          cartLines: cartLines,
          initialOrderType: _orderType,
          initialPromoCode: _promoCode,
          initialComment: _orderType == MobileOrderType.delivery
              ? trimmedOrNull(context.read<LocationController>().comment)
              : null,
          initialPickupBranchId: _selectedBranch?.id,
          initialPickupBranchText: trimmedOrNull(_selectedBranch?.name),
          initialDeliveryAddressText: _currentDeliveryAddressText(),
          onBranchSelected: _setPickupBranch,
          onPreviewRequested:
              ({
                required MobileOrderType orderType,
                required MobilePaymentMethod paymentMethod,
                required int loyaltyRedemptionAmount,
                String? promoCode,
              }) {
                return _previewCartForCheckout(
                  cartLines,
                  orderType: orderType,
                  paymentMethod: paymentMethod,
                  loyaltyRedemptionAmount: loyaltyRedemptionAmount,
                  promoCode: promoCode,
                );
              },
        ),
      ),
    );
  }

  Future<void> _handleCheckout(List<CartLine> requestedLines) async {
    if (requestedLines.isEmpty || _isCheckingOut.value) return;

    var cartLines = requestedLines;
    var backend = context.read<MobileBackendController>();
    if (!backend.isAuthenticated) {
      // The app may not know yet whether the customer is signed in (the
      // start-up request is running over the saved menu). The button shows
      // progress and takes no second tap meanwhile.
      _isCheckingOut.value = true;
      var sessionKnown = false;
      try {
        sessionKnown = await _sessionKnown();
      } finally {
        if (mounted) _isCheckingOut.value = false;
      }
      if (!sessionKnown || !mounted) return;
      // The customer may have left the cart while waiting.
      if (!_tabsAreOnTop || _currentIndex != _cartPageIndex) return;
      // The network catalog has just replaced the saved one and the cart is
      // checked against it after this frame; order what is in it then.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      cartLines = _cart.snapshot(backend.menuProducts).lines;
      if (cartLines.isEmpty) return;
    }
    if (!backend.isAuthenticated) {
      final didAuthenticate = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(builder: (_) => const AuthorizationScreen()),
      );
      if (!mounted) return;

      backend = context.read<MobileBackendController>();
      if (didAuthenticate != true && !backend.isAuthenticated) {
        return;
      }
    }

    final orderDetails = await _showOrderConfirmation(cartLines);
    if (!mounted || orderDetails == null) return;

    _promoCode = orderDetails.promoCode ?? '';

    final request = await _buildCreateOrderRequest(
      cartLines,
      orderType: orderDetails.orderType,
      paymentMethod: orderDetails.paymentMethod,
      promoCode: orderDetails.promoCode,
      comment: orderDetails.comment,
      loyaltyRedemptionAmount: orderDetails.loyaltyRedemptionAmount,
      previewedTarget: orderDetails.deliveryTarget,
    );
    if (!mounted || request == null) return;

    if (_orderType != orderDetails.orderType) {
      _setOrderType(orderDetails.orderType);
    }

    _logOrderCreation('request', request.toJson());
    _isCheckingOut.value = true;
    final idempotencyKey = _orderSubmissionKeys.keyFor(request.toJson());
    late Result<CustomerOrderModel> result;
    var creationErrorShown = false;
    var removePointsRequested = false;
    do {
      creationErrorShown = false;
      result = await backend.createOrder(
        request,
        idempotencyKey: idempotencyKey,
      );
      if (!mounted) return;
      if (result case Error(:final failure)) {
        if (OrderSubmissionKeys.isOutcomeUnknown(failure)) {
          creationErrorShown = true;
          final canRemovePoints =
              request.loyaltyRedemptionAmount > 0 &&
              failure is ServerFailure &&
              pointsUnavailableErrorCodes.contains(failure.errorCode);
          final action = await _showOrderCreationError(
            failure,
            allowRetry: true,
            allowRemovePoints: canRemovePoints,
          );
          if (action == _OrderFailureAction.retry) {
            continue;
          }
          removePointsRequested = action == _OrderFailureAction.removePoints;
        }
      }
      break;
    } while (true);
    _orderSubmissionKeys.resolve(
      succeeded: result.isSuccess,
      failure: result.failureOrNull,
    );
    if (result case Error(
      :final failure,
    ) when OrderSubmissionKeys.isOutcomeUnknown(failure)) {
      // The order may exist even though the request failed; reload history so
      // it shows up instead of the customer ordering again.
      unawaited(backend.refreshCustomerData());
    }
    if (result case Success(:final data)) {
      _logOrderCreation('response', data.raw);
    }
    if (result case Error(:final failure)) {
      _logOrderCreation('error', {
        'type': failure.runtimeType.toString(),
        'message': failure.message,
      });
    }
    if (!mounted) return;

    _isCheckingOut.value = false;
    switch (result) {
      case Success(:final data):
        _cart.clear();
        _promoCode = '';
        _selectTab(_profileTabIndex);
        final paymentUrl = data.totalAmount == 0
            ? null
            : data.paymentUrl?.trim();
        await Navigator.of(context).push<void>(
          PageRouteBuilder<void>(
            transitionDuration: AppMotion.duration(context, AppMotion.state),
            reverseTransitionDuration: AppMotion.duration(
              context,
              AppMotion.micro,
            ),
            pageBuilder: (_, _, _) => OrderSuccessScreen(
              order: data,
              openPaymentPage: paymentUrl?.isNotEmpty == true
                  ? () => ExternalUrlLauncher.open(
                      paymentUrl!,
                      allowedHosts: paymentLinkHosts,
                    )
                  : null,
              onTrackOrder: () => _openCreatedOrder(data),
              onBackHome: () => _selectTab(_homeTabIndex),
            ),
            transitionsBuilder: (_, animation, _, child) =>
                CurvedFadeTransition(
                  animation: animation,
                  curve: AppMotion.enter,
                  reverseCurve: AppMotion.exit,
                  child: child,
                ),
          ),
        );
      case Error(:final failure):
        final loyaltyCode = failure is ServerFailure ? failure.errorCode : null;
        final resetLoyalty = loyaltyResetErrorCodes.contains(loyaltyCode);
        if (resetLoyalty) {
          await context.read<MobileBackendController>().refreshLoyaltyWallet();
        }
        if (!creationErrorShown) {
          await _showOrderCreationError(failure);
        }
        if (!mounted) return;
        if (failure is AuthFailure) {
          await Navigator.of(context).push<bool>(
            MaterialPageRoute<bool>(
              builder: (_) => const AuthorizationScreen(),
            ),
          );
          return;
        }
        if (resetLoyalty || removePointsRequested) {
          unawaited(_handleCheckout(cartLines));
        }
    }
  }

  void _openCreatedOrder(CustomerOrderModel createdOrder) {
    if (!mounted) return;

    _selectTab(_profileTabIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final backend = context.read<MobileBackendController>();
      var order = createdOrder;
      for (final candidate in backend.orders) {
        if (candidate.id == createdOrder.id) {
          order = candidate;
          break;
        }
      }

      unawaited(
        showProfileOrderDetailsSheet(
          context: context,
          order: order,
          locale: context.read<LocaleController>().locale.languageCode,
          branches: backend.branches,
          addresses: backend.addresses,
        ),
      );
    });
  }
}
