part of 'package:enjoy_lavash_mobile/navigation/main_tabs.dart';

class _OrderConfirmationSheet extends StatefulWidget {
  const _OrderConfirmationSheet({
    required this.cartLines,
    required this.initialOrderType,
    required this.initialPromoCode,
    required this.onPreviewRequested,
    required this.onBranchSelected,
    this.initialComment,
    this.initialPickupBranchId,
    this.initialPickupBranchText,
    this.initialDeliveryAddressText,
  });

  final List<CartLine> cartLines;
  final MobileOrderType initialOrderType;
  final String initialPromoCode;
  final _CartPreviewRequester onPreviewRequested;
  final Future<void> Function(BranchModel?) onBranchSelected;
  final String? initialComment;
  final String? initialPickupBranchId;
  final String? initialPickupBranchText;
  final String? initialDeliveryAddressText;

  @override
  State<_OrderConfirmationSheet> createState() =>
      _OrderConfirmationSheetState();
}

class _OrderConfirmationSheetState extends State<_OrderConfirmationSheet> {
  /// `setState` for this state's part-file extensions, which may not call
  /// the protected member directly.
  void _updateState(VoidCallback change) => setState(change);

  late MobileOrderType _orderType;
  MobilePaymentMethod _paymentMethod = MobilePaymentMethod.cash;
  late final TextEditingController _promoCodeController;
  late final TextEditingController _commentController;
  late final TextEditingController _pointsController;
  Timer? _previewDebounce;
  _CheckoutPreviewDetails? _previewDetails;
  MobileOrderType? _lastPreviewOrderType;
  MobilePaymentMethod? _lastPreviewPaymentMethod;
  String? _lastPreviewPromoCode;
  int? _lastPreviewLoyaltyPoints;
  int? _lastPreviewInputVersion;
  int _previewInputVersion = 0;
  String? _deliveryAddressText;
  String? _pickupBranchId;
  String? _pickupBranchText;
  String? _previewErrorText;
  Failure? _previewFailure;
  String? _previewFailureBranchId;
  bool _isPreviewLoading = false;
  bool _isChangingDestination = false;
  bool _usePointsBalance = false;
  int _maximumPointsToSpend = 0;
  OrderingStatusModel? _orderingStatus;
  Failure? _orderingStatusFailure;
  bool _orderingStatusLoading = false;
  String? _orderingStatusBranchId;
  DateTime? _orderingStatusLoadedAt;
  int _orderingStatusRequestVersion = 0;
  Timer? _orderingStatusRefreshTimer;
  late final VoidCallback _promoCodeListener;
  late final VoidCallback _pointsListener;

  @override
  void initState() {
    super.initState();
    _orderType = widget.initialOrderType;
    _deliveryAddressText = widget.initialDeliveryAddressText;
    _pickupBranchId = widget.initialPickupBranchId;
    _pickupBranchText = widget.initialPickupBranchText;
    _promoCodeController = TextEditingController(text: widget.initialPromoCode);
    _commentController = TextEditingController(text: widget.initialComment);
    _pointsController = TextEditingController(text: '0');
    _promoCodeListener = textChangeListener(
      _promoCodeController,
      _onPromoCodeChanged,
    );
    _pointsListener = textChangeListener(_pointsController, _onPointsChanged);
    _promoCodeController.addListener(_promoCodeListener);
    _pointsController.addListener(_pointsListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<MobileBackendController>().refreshLoyaltyWallet());
      unawaited(_loadOrderingStatus(_pickupBranchId));
      unawaited(_loadPreview());
    });
  }

  @override
  void dispose() {
    _promoCodeController.removeListener(_promoCodeListener);
    _pointsController.removeListener(_pointsListener);
    _previewDebounce?.cancel();
    _orderingStatusRefreshTimer?.cancel();
    _promoCodeController.dispose();
    _commentController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  String? get _normalizedPromoCode {
    final promoCode = _promoCodeController.text.trim();
    return promoCode.isEmpty ? null : promoCode;
  }

  bool get _hasPromoCodeInput => _normalizedPromoCode != null;

  String? get _normalizedComment {
    final comment = _commentController.text.trim();
    return comment.isEmpty ? null : comment;
  }

  int get _requestedPoints {
    return int.tryParse(_pointsController.text.trim()) ?? 0;
  }

  String? get _promoCodeForOrder {
    return _normalizedPromoCode;
  }

  bool get _promoCodeCanBeSubmitted {
    if (!_hasPromoCodeInput) return true;
    final preview = _previewDetails?.preview;
    if (preview == null || !_previewMatchesCurrentInput) return false;
    return preview.acceptsPromoCode(_normalizedPromoCode);
  }

  bool get _previewMatchesCurrentInput {
    return _previewDetails != null &&
        _lastPreviewOrderType == _orderType &&
        _lastPreviewPaymentMethod == _currentPaymentMethod &&
        _lastPreviewPromoCode == _normalizedPromoCode &&
        _lastPreviewLoyaltyPoints == _requestedPoints &&
        _lastPreviewInputVersion == _previewInputVersion;
  }

  List<PaymentMethodModel> get _availablePaymentMethods {
    return context.read<MobileBackendController>().paymentMethods;
  }

  MobilePaymentMethod get _currentPaymentMethod {
    final methods = _availablePaymentMethods;
    if (methods.isEmpty) {
      final previewedMethod = _lastPreviewPaymentMethod;
      if (_isUsablePaymentMethod(previewedMethod)) {
        return previewedMethod!;
      }
      return MobilePaymentMethod.unknown;
    }
    final hasSelected = methods.any((method) => method.code == _paymentMethod);
    return hasSelected ? _paymentMethod : methods.first.code;
  }

  bool _isUsablePaymentMethod(MobilePaymentMethod? method) {
    return method != null && method != MobilePaymentMethod.unknown;
  }

  List<PaymentMethodModel> _paymentMethodsForDisplay(
    List<PaymentMethodModel> methods,
  ) => methods;

  String? get _orderingBranchIdForCurrentInput {
    final branchId = _orderType == MobileOrderType.pickup
        ? _pickupBranchId
        : _previewDetails?.preview.branchId ?? _previewFailureBranchId;
    final normalized = branchId?.trim();
    return normalized?.isNotEmpty == true ? normalized : null;
  }

  OrderingAvailabilityModel? get _relevantOrderingAvailability {
    final status = _orderingStatus;
    final branchId = _orderingBranchIdForCurrentInput;
    if (status == null ||
        branchId == null ||
        status.branchId != branchId ||
        _orderingStatusBranchId != branchId) {
      return null;
    }
    return _orderType == MobileOrderType.pickup
        ? status.pickup
        : status.delivery;
  }

  bool _hasDeliveryAddressInput() {
    final location = context.read<LocationController>();
    if (location.latitude != null && location.longitude != null) {
      return true;
    }
    return context.read<MobileBackendController>().addresses.isNotEmpty;
  }

  String? _currentDeliveryAddressText() {
    final location = context.read<LocationController>();
    return deliveryAddressText(
      addressName: location.addressName,
      fullAddress: location.fullAddress,
      savedAddresses: context.read<MobileBackendController>().addresses,
    );
  }

  String? _addressSummary(_CheckoutAddressDetails? address) {
    return trimmedOrNull(address?.text) ?? trimmedOrNull(address?.label);
  }

  String? _pickupToggleSubtitle() {
    final details = _previewDetails;
    if (details?.orderType == MobileOrderType.pickup) {
      return trimmedOrNull(details?.branchName) ??
          trimmedOrNull(details?.branchAddress) ??
          trimmedOrNull(_pickupBranchText);
    }
    return trimmedOrNull(_pickupBranchText);
  }

  String? _deliveryToggleSubtitle() {
    final details = _previewDetails;
    if (details?.orderType == MobileOrderType.delivery) {
      return _addressSummary(details?.address) ??
          trimmedOrNull(_deliveryAddressText);
    }
    return trimmedOrNull(_deliveryAddressText);
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Only what checkout renders: the sheet (and the shell under it) must not
    // rebuild for unrelated backend updates while the customer is paying.
    final backend = context
        .select<
          MobileBackendController,
          ({
            List<PaymentMethodModel> paymentMethods,
            bool paymentMethodsLoading,
            Failure? paymentMethodsFailure,
            LoyaltyWalletModel? loyaltyWallet,
          })
        >(
          (controller) => (
            paymentMethods: controller.paymentMethods,
            paymentMethodsLoading: controller.paymentMethodsLoading,
            paymentMethodsFailure: controller.paymentMethodsFailure,
            loyaltyWallet: controller.loyaltyWallet,
          ),
        );
    final currentPaymentMethod = _currentPaymentMethod;
    final paymentMethods = _paymentMethodsForDisplay(backend.paymentMethods);
    final loyaltyPreview = _previewDetails?.preview.loyalty;
    final wallet = backend.loyaltyWallet;
    final debtAmount = loyaltyPreview?.debtAmount ?? wallet?.debtBalance ?? 0;
    final pointsEnabled =
        debtAmount == 0 &&
        (wallet?.programEnabled ?? true) &&
        (wallet?.redemptionEnabled ?? true);
    final fullyPaidWithPoints =
        (_previewDetails?.preview.totalAmount ?? -1) == 0 &&
        (loyaltyPreview?.appliedPoints ?? 0) > 0;

    final relevantAvailability = _relevantOrderingAvailability;
    final orderingKnownClosed = relevantAvailability?.isOpen == false;
    final canConfirm =
        !_isPreviewLoading &&
        !_orderingStatusLoading &&
        !orderingKnownClosed &&
        _previewMatchesCurrentInput &&
        _promoCodeCanBeSubmitted &&
        (fullyPaidWithPoints || paymentMethods.isNotEmpty);
    final payableAmount = _previewDetails?.preview.totalAmount;

    return Scaffold(
      backgroundColor: isDark
          ? AppDesignTokens.darkGround
          : AppDesignTokens.lightGround,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
              child: Row(
                children: <Widget>[
                  Material(
                    color: AppDesignTokens.surface(context),
                    shape: const CircleBorder(),
                    elevation: 1,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).backButtonTooltip,
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 17,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TypographyText(
                      t.createOrderTitle,
                      style: AppTextStyles.display(
                        size: 26,
                        height: 1.15,
                        color: AppDesignTokens.primaryText(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  24 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _CheckoutStepLabel(index: 1, label: t.orderType),
                    const SizedBox(height: 8),
                    _OrderTypeToggle(
                      orderType: _orderType,
                      deliverySubtitle: _deliveryToggleSubtitle(),
                      pickupSubtitle: _pickupToggleSubtitle(),
                      onDeliveryTap: () =>
                          unawaited(_showDeliveryAddressPicker()),
                      onPickupTap: () => unawaited(_showPickupBranchPicker()),
                    ),
                    const SizedBox(height: 18),
                    _CheckoutStepLabel(
                      index: 2,
                      label: _orderType == MobileOrderType.delivery
                          ? t.address
                          : t.pickupBranch,
                    ),
                    const SizedBox(height: 8),
                    _CheckoutDestinationCard(
                      icon: _orderType == MobileOrderType.delivery
                          ? Icons.location_on_outlined
                          : Icons.storefront_outlined,
                      title: _orderType == MobileOrderType.delivery
                          ? t.delivery
                          : t.pickup,
                      subtitle: _orderType == MobileOrderType.delivery
                          ? _deliveryToggleSubtitle() ?? t.tapToSelectAddress
                          : _pickupToggleSubtitle() ?? t.pickupBranch,
                      changeLabel: t.change,
                      onTap: _orderType == MobileOrderType.delivery
                          ? () => unawaited(_showDeliveryAddressPicker())
                          : () => unawaited(_showPickupBranchPicker()),
                    ),
                    if (_orderingBranchIdForCurrentInput != null ||
                        _orderingStatusFailure != null ||
                        _orderingStatusLoading) ...<Widget>[
                      const SizedBox(height: 10),
                      _OrderingStatusCard(
                        status: _orderingStatus,
                        failure: _orderingStatusFailure,
                        isLoading: _orderingStatusLoading,
                        relevantType: _orderType,
                        onRetry: () => unawaited(
                          _loadOrderingStatus(
                            _orderingBranchIdForCurrentInput,
                            force: true,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    _CheckoutStepLabel(index: 3, label: t.payment),
                    const SizedBox(height: 8),
                    if (fullyPaidWithPoints)
                      const _FullyPaidWithPointsCard()
                    else
                      _PaymentMethodSelector(
                        methods: paymentMethods,
                        selectedMethod: currentPaymentMethod,
                        isLoading:
                            backend.paymentMethodsLoading &&
                            paymentMethods.isEmpty,
                        errorText: switch (backend.paymentMethodsFailure) {
                          final Failure failure => failureMessage(t, failure),
                          null => null,
                        },
                        onRetry: () => unawaited(_retryPaymentMethods()),
                        onChanged: _selectPaymentMethod,
                      ),
                    const SizedBox(height: 18),
                    _CheckoutStepLabel(index: 4, label: t.usePoints),
                    const SizedBox(height: 8),
                    _LoyaltyRedemptionControl(
                      controller: _pointsController,
                      wallet: wallet,
                      preview: loyaltyPreview,
                      debtAmount: debtAmount,
                      enabled: pointsEnabled,
                      selected: _usePointsBalance,
                      maximumPoints:
                          loyaltyPreview?.maxPointsToSpend ??
                          _maximumPointsToSpend,
                      isLoading: _isPreviewLoading,
                      onSelectedChanged: _setUsePointsBalance,
                      onUseMaximum: _useMaximumPoints,
                    ),
                    const SizedBox(height: 18),
                    TypographyText(
                      t.promoCode,
                      style: AppTextStyles.ui(
                        size: 12,
                        weight: FontWeight.w600,
                        color: AppDesignTokens.tertiaryText(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _PromoCodeField(
                      controller: _promoCodeController,
                      hasPromoCodeInput: _hasPromoCodeInput,
                      isLoading: _isPreviewLoading,
                      onApply: () => unawaited(_loadPreview()),
                    ),
                    const SizedBox(height: 14),
                    TypographyText(
                      t.commentLabel,
                      style: AppTextStyles.ui(
                        size: 12,
                        weight: FontWeight.w600,
                        color: AppDesignTokens.tertiaryText(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _OrderCommentField(controller: _commentController),
                    const SizedBox(height: 14),
                    _OrderItemsSection(
                      cartLines: widget.cartLines,
                      previewItems:
                          _previewDetails?.preview.pricedItems ??
                          const <PricedCartItemModel>[],
                    ),
                    const SizedBox(height: 14),
                    _CheckoutPreviewSummary(
                      isLoading: _isPreviewLoading,
                      details: _previewDetails,
                      errorText: _previewFailure == null
                          ? _previewErrorText
                          : _previewFailureMessage(_previewFailure!),
                      onRetry: () => unawaited(_loadPreview()),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: AppDesignTokens.ground(context),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      AppDesignTokens.radiusPill,
                    ),
                    boxShadow: canConfirm
                        ? AppDesignTokens.actionGlow
                        : const <BoxShadow>[],
                  ),
                  child: FilledButton(
                    onPressed: canConfirm
                        ? () => unawaited(_confirmOrder())
                        : null,
                    child: TypographyText(
                      payableAmount == null
                          ? t.createOrderAction
                          : t.createOrderFor(formatSum(context, payableAmount)),
                      style: const TextStyle(color: BaseColors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
