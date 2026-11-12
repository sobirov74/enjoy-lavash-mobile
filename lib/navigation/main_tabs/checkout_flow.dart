part of 'package:enjoy_lavash_mobile/navigation/main_tabs.dart';

/// Checkout: preview and order requests, the confirmation sheet, order
/// creation with its error dialog, and the success screen.
extension _ShellCheckout on _MainTabsState {
  /// The point picked on this device, converted by [toInput]; null when no
  /// point was picked.
  T? _mapPoint<T>(
    LocationController location,
    T Function(DeliveryPoint) toInput,
  ) {
    final point = location.deliveryPoint;
    return point == null ? null : toInput(point);
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

    final fallbackAddress = defaultClientAddress(addresses);
    if (fallbackAddress != null) {
      return _CheckoutAddressDetails(
        label: trimmedOrNull(fallbackAddress.label),
        text: clientAddressText(fallbackAddress),
      );
    }

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
    final t = L.of(context);
    final metadata = OrderingClosedMetadataModel.fromJson(failure.metadata);
    final nextOpening = metadata.nextOpeningAt;
    if (nextOpening == null) return t.orderingClosedAction;
    final locale = Localizations.localeOf(context).languageCode;
    final formatted = dateFormat(
      locale,
      'd MMM, HH:mm',
      (locale) => DateFormat('d MMM, HH:mm', locale),
    ).format(nextOpening.toLocal());
    final timezone = metadata.timezone.trim();
    return timezone.isEmpty
        ? t.orderingNextOpening(formatted)
        : '${t.orderingNextOpening(formatted)} · $timezone';
  }

  Future<CartPreviewRequest?> _buildCartPreviewRequest(
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

      return CartPreviewRequest(
        type: MobileOrderType.pickup,
        branchId: branch.id,
        items: items,
        paymentMethod: paymentMethod,
        promoCode: normalizedPromoCode,
        loyaltyRedemptionAmount: loyaltyRedemptionAmount,
      );
    }

    final backend = context.read<MobileBackendController>();
    final location = context.read<LocationController>();
    var address = _mapPoint(location, previewDeliveryAddress);
    String? addressId;
    final savedAddress = defaultClientAddress(backend.addresses);
    if (address == null && savedAddress != null) {
      addressId = savedAddress.id;
    }

    if (address == null && addressId == null) {
      await showAddressBottomSheet(context);
      if (!mounted) return null;
      address = _mapPoint(location, previewDeliveryAddress);
      final fallbackSavedAddress = defaultClientAddress(
        context.read<MobileBackendController>().addresses,
      );
      if (address == null && fallbackSavedAddress != null) {
        addressId = fallbackSavedAddress.id;
      }
    }

    if (address == null && addressId == null) {
      _showSnack(t.selectDeliveryAddressFirst);
      return null;
    }

    return CartPreviewRequest(
      type: MobileOrderType.delivery,
      addressId: addressId,
      address: address,
      items: items,
      paymentMethod: paymentMethod,
      promoCode: normalizedPromoCode,
      loyaltyRedemptionAmount: loyaltyRedemptionAmount,
    );
  }

  Future<Result<_CheckoutPreviewDetails>?> _previewCartForCheckout(
    List<CartLine> cartLines, {
    required MobileOrderType orderType,
    required MobilePaymentMethod paymentMethod,
    required int loyaltyRedemptionAmount,
    String? promoCode,
  }) async {
    final request = await _buildCartPreviewRequest(
      cartLines,
      orderType: orderType,
      paymentMethod: paymentMethod,
      promoCode: promoCode,
      loyaltyRedemptionAmount: loyaltyRedemptionAmount,
    );
    if (!mounted || request == null) return null;

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
      return Success(_checkoutPreviewDetails(request: request, preview: data));
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

    final backend = context.read<MobileBackendController>();
    final location = context.read<LocationController>();
    var address = _mapPoint(location, inlineOrderAddress);
    String? addressId;
    final savedAddress = defaultClientAddress(backend.addresses);
    if (address == null && savedAddress != null) {
      addressId = savedAddress.id;
    }

    if (address == null && addressId == null) {
      await showAddressBottomSheet(context);
      if (!mounted) return null;
      address = _mapPoint(location, inlineOrderAddress);
      final fallbackSavedAddress = defaultClientAddress(
        context.read<MobileBackendController>().addresses,
      );
      if (address == null && fallbackSavedAddress != null) {
        addressId = fallbackSavedAddress.id;
      }
    }

    if (address == null && addressId == null) {
      _showSnack(t.selectDeliveryAddressFirst);
      return null;
    }

    return CreateOrderRequest(
      type: MobileOrderType.delivery,
      address: address,
      addressId: addressId,
      branchId: address == null ? null : _deliveryBranchId,
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

  Future<void> _handleCheckout(List<CartLine> cartLines) async {
    if (cartLines.isEmpty || _isCheckingOut.value) return;

    var backend = context.read<MobileBackendController>();
    if (!backend.isAuthenticated) {
      await backend.whenSessionSettled();
      if (!mounted) return;
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
