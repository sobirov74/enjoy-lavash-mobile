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
    _promoCodeController.addListener(_onPromoCodeChanged);
    _pointsController.addListener(_onPointsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<MobileBackendController>().refreshLoyaltyWallet());
      unawaited(_loadOrderingStatus(_pickupBranchId));
      unawaited(_loadPreview());
    });
  }

  @override
  void dispose() {
    _promoCodeController.removeListener(_onPromoCodeChanged);
    _pointsController.removeListener(_onPointsChanged);
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
    setState(() {
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
    setState(() {
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
      setState(() => _isPreviewLoading = false);
      if (!_isChangingDestination) {
        unawaited(_loadPreview());
      }
      return false;
    }

    if (result == null) {
      setState(() => _isPreviewLoading = false);
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
    setState(() {
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
    setState(() {
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
        failure is ServerFailure && failure.errorCode == 'ORDERING_CLOSED'
        ? OrderingClosedMetadataModel.fromJson(failure.metadata)
        : null;
    final branchId = _trimmedOrNull(metadata?.branchId);
    setState(() {
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
    if (failure is ServerFailure && failure.errorCode == 'ORDERING_CLOSED') {
      final metadata = OrderingClosedMetadataModel.fromJson(failure.metadata);
      final nextOpening = metadata.nextOpeningAt;
      if (nextOpening == null) return t.orderingClosedAction;
      final locale = Localizations.localeOf(context).languageCode;
      final formatted = DateFormat(
        'd MMM, HH:mm',
        locale,
      ).format(nextOpening.toLocal());
      final timezone = metadata.timezone.trim();
      return timezone.isEmpty
          ? t.orderingNextOpening(formatted)
          : '${t.orderingNextOpening(formatted)} · $timezone';
    }
    final message = failure.message.trim();
    return message.isEmpty ? t.couldNotCalculateTotal : message;
  }

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
      ),
    );
  }

  Future<void> _showDeliveryAddressPicker() async {
    if (_isChangingDestination) return;

    if (_orderType != MobileOrderType.delivery) {
      setState(() {
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
      setState(() => _deliveryAddressText = deliveryAddressText);
      _showPreviewError(L.of(context).selectDeliveryAddressFirst);
      return;
    }

    setState(() => _deliveryAddressText = deliveryAddressText);
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
    setState(() {
      _orderType = MobileOrderType.pickup;
      _pickupBranchId = branch.id;
      _pickupBranchText =
          _trimmedOrNull(branch.name) ?? _trimmedOrNull(branch.address);
    });
    unawaited(_loadOrderingStatus(branch.id, force: true));
    unawaited(_loadPreview());
  }

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
    setState(() {
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
        setState(() {
          _orderingStatus = data;
          _orderingStatusFailure = null;
          _orderingStatusLoading = false;
          _orderingStatusLoadedAt = DateTime.now().toUtc();
        });
        _scheduleOrderingStatusRefresh(data, normalized);
      case Error(:final failure):
        setState(() {
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
    setState(() => _paymentMethod = method);
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
    setState(() => _usePointsBalance = value);
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

  String? _trimmedOrNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  bool _hasDeliveryAddressInput() {
    final location = context.read<LocationController>();
    if (location.latitude != null && location.longitude != null) {
      return true;
    }
    return context.read<MobileBackendController>().addresses.isNotEmpty;
  }

  ClientAddress? _defaultAddress(List<ClientAddress> addresses) {
    if (addresses.isEmpty) return null;

    for (final address in addresses) {
      if (address.isDefault) return address;
    }
    return addresses.first;
  }

  String? _formatClientAddressText(ClientAddress address) {
    final parts = <String>[
      if (address.street.trim().isNotEmpty) address.street.trim(),
      if (address.houseNumber?.trim().isNotEmpty == true)
        address.houseNumber!.trim(),
      if (address.apartmentNumber?.trim().isNotEmpty == true)
        address.apartmentNumber!.trim(),
    ];
    if (parts.isEmpty) return _trimmedOrNull(address.label);
    return parts.join(', ');
  }

  String? _currentDeliveryAddressText() {
    final location = context.read<LocationController>();
    final addressName = _trimmedOrNull(location.addressName);
    final fullAddress = _trimmedOrNull(location.fullAddress) ?? addressName;
    if (fullAddress != null) return fullAddress;

    final savedAddress = _defaultAddress(
      context.read<MobileBackendController>().addresses,
    );
    if (savedAddress == null) return null;
    return _formatClientAddressText(savedAddress);
  }

  String? _addressSummary(_CheckoutAddressDetails? address) {
    return _trimmedOrNull(address?.text) ?? _trimmedOrNull(address?.label);
  }

  String? _pickupToggleSubtitle() {
    final details = _previewDetails;
    if (details?.orderType == MobileOrderType.pickup) {
      return _trimmedOrNull(details?.branchName) ??
          _trimmedOrNull(details?.branchAddress) ??
          _trimmedOrNull(_pickupBranchText);
    }
    return _trimmedOrNull(_pickupBranchText);
  }

  String? _deliveryToggleSubtitle() {
    final details = _previewDetails;
    if (details?.orderType == MobileOrderType.delivery) {
      return _addressSummary(details?.address) ??
          _trimmedOrNull(_deliveryAddressText);
    }
    return _trimmedOrNull(_deliveryAddressText);
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backend = context.watch<MobileBackendController>();
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
                        errorText: backend.paymentMethodsFailure?.message,
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

class _CheckoutStepLabel extends StatelessWidget {
  const _CheckoutStepLabel({required this.index, required this.label});

  final int index;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TypographyText(
      '$index · ${label.toUpperCase()}',
      style: AppTextStyles.ui(
        size: 11,
        weight: FontWeight.w600,
        color: AppDesignTokens.tertiaryText(context),
      ),
    );
  }
}

class _CheckoutDestinationCard extends StatelessWidget {
  const _CheckoutDestinationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.changeLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String changeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppDesignTokens.surface(context),
      borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppDesignTokens.actionSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: AppDesignTokens.action),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TypographyText(
                      title,
                      style: AppTextStyles.ui(
                        size: 14,
                        weight: FontWeight.w600,
                        color: AppDesignTokens.primaryText(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    TypographyText(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.ui(
                        size: 12,
                        color: AppDesignTokens.secondaryText(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TypographyText(
                changeLabel,
                style: AppTextStyles.ui(
                  size: 12,
                  weight: FontWeight.w600,
                  color: AppDesignTokens.action,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderingStatusCard extends StatelessWidget {
  const _OrderingStatusCard({
    required this.status,
    required this.failure,
    required this.isLoading,
    required this.relevantType,
    required this.onRetry,
  });

  final OrderingStatusModel? status;
  final Failure? failure;
  final bool isLoading;
  final MobileOrderType relevantType;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = AppDesignTokens.hairline(context);

    return Semantics(
      container: true,
      label: t.orderingAvailability,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppDesignTokens.surface(context),
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
          border: Border.all(color: borderColor),
        ),
        child: AnimatedSwitcher(
          duration: AppMotion.duration(context, AppMotion.micro),
          child: status == null && (isLoading || failure == null)
              ? Row(
                  key: const ValueKey<String>('ordering-status-loading'),
                  children: <Widget>[
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(t.orderingChecking)),
                  ],
                )
              : failure != null && status == null
              ? Row(
                  key: const ValueKey<String>('ordering-status-error'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: AppDesignTokens.secondaryText(context),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        t.orderingStatusUnavailable,
                        style: AppTextStyles.ui(
                          size: 12.5,
                          height: 1.35,
                          color: AppDesignTokens.secondaryText(context),
                        ),
                      ),
                    ),
                    TextButton(onPressed: onRetry, child: Text(t.retry)),
                  ],
                )
              : _OrderingAvailabilityContent(
                  key: ValueKey<String>(
                    'ordering-status-${status?.branchId ?? 'empty'}',
                  ),
                  status: status!,
                  relevantType: relevantType,
                  isDark: isDark,
                  isRefreshing: isLoading,
                  onRefresh: onRetry,
                ),
        ),
      ),
    );
  }
}

class _OrderingAvailabilityContent extends StatelessWidget {
  const _OrderingAvailabilityContent({
    super.key,
    required this.status,
    required this.relevantType,
    required this.isDark,
    required this.isRefreshing,
    required this.onRefresh,
  });

  final OrderingStatusModel status;
  final MobileOrderType relevantType;
  final bool isDark;
  final bool isRefreshing;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final relevant = relevantType == MobileOrderType.pickup
        ? status.pickup
        : status.delivery;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: TypographyText(
                t.orderingAvailability,
                style: AppTextStyles.ui(
                  size: 13,
                  weight: FontWeight.w600,
                  color: AppDesignTokens.primaryText(context),
                ),
              ),
            ),
            TypographyText(
              status.timezone,
              style: AppTextStyles.ui(
                size: 10.5,
                color: AppDesignTokens.tertiaryText(context),
              ),
            ),
            const SizedBox(width: 4),
            if (isRefreshing)
              const SizedBox(
                width: 32,
                height: 32,
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                key: const ValueKey<String>('ordering-status-refresh'),
                onPressed: onRefresh,
                tooltip: t.retry,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.refresh_rounded, size: 18),
              ),
          ],
        ),
        const SizedBox(height: 10),
        _OrderingAvailabilityRow(
          label: t.pickupAvailability,
          availability: status.pickup,
          emphasized: relevantType == MobileOrderType.pickup,
        ),
        const SizedBox(height: 7),
        _OrderingAvailabilityRow(
          label: t.deliveryAvailability,
          availability: status.delivery,
          emphasized: relevantType == MobileOrderType.delivery,
        ),
        if (!relevant.isOpen) ...<Widget>[
          const SizedBox(height: 10),
          Text(
            _closedDetail(context, relevant),
            style: AppTextStyles.ui(
              size: 12,
              height: 1.35,
              weight: FontWeight.w600,
              color: isDark ? const Color(0xFFFFB4AB) : AppDesignTokens.danger,
            ),
          ),
        ],
      ],
    );
  }

  String _closedDetail(
    BuildContext context,
    OrderingAvailabilityModel availability,
  ) {
    final t = L.of(context);
    final nextOpening = availability.nextOpeningAt;
    if (nextOpening == null) return t.orderingClosedAction;
    final locale = Localizations.localeOf(context).languageCode;
    final formatted = DateFormat(
      'd MMM, HH:mm',
      locale,
    ).format(nextOpening.toLocal());
    return '${t.orderingNextOpening(formatted)} · ${availability.timezone}';
  }
}

class _OrderingAvailabilityRow extends StatelessWidget {
  const _OrderingAvailabilityRow({
    required this.label,
    required this.availability,
    required this.emphasized,
  });

  final String label;
  final OrderingAvailabilityModel availability;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final color = availability.isOpen
        ? AppDesignTokens.success
        : AppDesignTokens.danger;
    return Semantics(
      selected: emphasized,
      label:
          '$label, ${availability.isOpen ? t.orderingOpen : t.orderingClosed}',
      child: Row(
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.ui(
                size: 12.5,
                weight: emphasized ? FontWeight.w600 : FontWeight.w500,
                color: AppDesignTokens.primaryText(context),
              ),
            ),
          ),
          Text(
            availability.isOpen ? t.orderingOpen : t.orderingClosed,
            style: AppTextStyles.ui(
              size: 12,
              weight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoyaltyRedemptionControl extends StatelessWidget {
  const _LoyaltyRedemptionControl({
    required this.controller,
    required this.wallet,
    required this.preview,
    required this.debtAmount,
    required this.enabled,
    required this.selected,
    required this.maximumPoints,
    required this.isLoading,
    required this.onSelectedChanged,
    required this.onUseMaximum,
  });

  final TextEditingController controller;
  final LoyaltyWalletModel? wallet;
  final CartLoyaltyPreviewModel? preview;
  final int debtAmount;
  final bool enabled;
  final bool selected;
  final int maximumPoints;
  final bool isLoading;
  final ValueChanged<bool> onSelectedChanged;
  final VoidCallback onUseMaximum;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final available =
        preview?.spendableBalance ?? wallet?.spendableBalance ?? 0;
    final canUsePoints = enabled && maximumPoints > 0;
    final hasRequestedPoints = (int.tryParse(controller.text.trim()) ?? 0) > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected
            ? (isDark ? const Color(0xFF2A2522) : const Color(0xFFFFF3EC))
            : (isDark ? const Color(0xFF24211F) : const Color(0xFFF8F4EF)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected
              ? BaseColors.primary.withValues(alpha: 0.55)
              : BaseColors.primary.withValues(alpha: 0.12),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: BaseColors.primary.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.stars_rounded,
                  color: BaseColors.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TypographyText(
                      t.usePoints,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    TypographyText(
                      '${t.pointsAvailable}: '
                      '${_formatLoyaltyPoints(context, available)}',
                      style: const TextStyle(
                        color: BaseColors.textGray,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(
                key: const ValueKey<String>('use-points-switch'),
                value: selected,
                activeTrackColor: BaseColors.primary,
                onChanged: selected || canUsePoints ? onSelectedChanged : null,
              ),
            ],
          ),
          const SizedBox(height: 7),
          TypographyText(
            t.loyaltyPointValueInfo,
            style: const TextStyle(
              color: BaseColors.textGray,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: selected
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Expanded(
                              child: TextField(
                                key: const ValueKey<String>(
                                  'points-amount-field',
                                ),
                                controller: controller,
                                enabled: enabled,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                  TextInputFormatter.withFunction((
                                    oldValue,
                                    newValue,
                                  ) {
                                    final value = int.tryParse(newValue.text);
                                    return value == null ||
                                            value <= maximumPoints
                                        ? newValue
                                        : oldValue;
                                  }),
                                ],
                                decoration: InputDecoration(
                                  labelText: t.pointsInputHint,
                                  prefixIcon: const Icon(Icons.toll_rounded),
                                  filled: true,
                                  fillColor: isDark
                                      ? const Color(0xFF1D1A18)
                                      : Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              key: const ValueKey<String>('use-maximum-points'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 48),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              onPressed:
                                  canUsePoints &&
                                      !isLoading &&
                                      (!hasRequestedPoints ||
                                          controller.text !=
                                              maximumPoints.toString())
                                  ? onUseMaximum
                                  : null,
                              icon: const Icon(Icons.bolt_rounded, size: 17),
                              label: TypographyText(t.useMaximum),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: TypographyText(
                                '${t.useMaximum}: '
                                '${_formatLoyaltyPoints(context, maximumPoints)}',
                                style: const TextStyle(
                                  color: BaseColors.textGray,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            if (isLoading)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: BaseColors.primary,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (debtAmount > 0) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(
                  Icons.warning_amber_rounded,
                  color: BaseColors.danger,
                  size: 18,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: TypographyText(
                    '${t.pointsDebtCheckout} ${t.loyaltyDebt}: '
                    '${_formatLoyaltyPoints(context, debtAmount)}',
                    style: const TextStyle(
                      color: BaseColors.danger,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (!enabled) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(
                  Icons.info_outline_rounded,
                  color: BaseColors.textGray,
                  size: 18,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: TypographyText(
                    wallet?.programEnabled == false
                        ? t.loyaltyProgramUnavailable
                        : t.loyaltyRedemptionUnavailable,
                    style: const TextStyle(
                      color: BaseColors.textGray,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FullyPaidWithPointsCard extends StatelessWidget {
  const _FullyPaidWithPointsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BaseColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.check_circle_rounded, color: BaseColors.success),
          const SizedBox(width: 9),
          Expanded(
            child: TypographyText(
              L.of(context).fullyPaidWithPoints,
              style: const TextStyle(
                color: BaseColors.success,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCommentField extends StatelessWidget {
  const _OrderCommentField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2522) : const Color(0xFFF8F4EF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF3A332D) : const Color(0xFFEDE2D7),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 11),
            child: Icon(Icons.notes_rounded, color: BaseColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.newline,
              cursorColor: BaseColors.primary,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: t.commentHint,
                hintStyle: TextStyle(
                  color: isDark ? const Color(0xFF9E9790) : BaseColors.textGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
