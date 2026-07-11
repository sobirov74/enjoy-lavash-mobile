part of 'package:enjoy_lavash_mobile/navigation/main_tabs.dart';

class _OrderConfirmationSheet extends StatefulWidget {
  const _OrderConfirmationSheet({
    required this.cartLines,
    required this.initialOrderType,
    required this.initialPromoCode,
    required this.onPreviewRequested,
    required this.onBranchSelected,
    this.initialPickupBranchId,
    this.initialPickupBranchText,
    this.initialDeliveryAddressText,
  });

  final List<CartLine> cartLines;
  final MobileOrderType initialOrderType;
  final String initialPromoCode;
  final _CartPreviewRequester onPreviewRequested;
  final Future<void> Function(BranchModel?) onBranchSelected;
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
  _CheckoutPreviewDetails? _previewDetails;
  MobileOrderType? _lastPreviewOrderType;
  MobilePaymentMethod? _lastPreviewPaymentMethod;
  String? _lastPreviewPromoCode;
  int? _lastPreviewInputVersion;
  int _previewInputVersion = 0;
  String? _deliveryAddressText;
  String? _pickupBranchId;
  String? _pickupBranchText;
  String? _previewErrorText;
  bool _isPreviewLoading = false;
  bool _isChangingDestination = false;

  @override
  void initState() {
    super.initState();
    _orderType = widget.initialOrderType;
    _deliveryAddressText = widget.initialDeliveryAddressText;
    _pickupBranchId = widget.initialPickupBranchId;
    _pickupBranchText = widget.initialPickupBranchText;
    _promoCodeController = TextEditingController(text: widget.initialPromoCode);
    _promoCodeController.addListener(_onPromoCodeChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_loadPreview());
    });
  }

  @override
  void dispose() {
    _promoCodeController.removeListener(_onPromoCodeChanged);
    _promoCodeController.dispose();
    super.dispose();
  }

  String? get _normalizedPromoCode {
    final promoCode = _promoCodeController.text.trim();
    return promoCode.isEmpty ? null : promoCode;
  }

  bool get _hasPromoCodeInput => _normalizedPromoCode != null;

  bool get _previewMatchesCurrentInput {
    return _previewDetails != null &&
        _lastPreviewOrderType == _orderType &&
        _lastPreviewPaymentMethod == _currentPaymentMethod &&
        _lastPreviewPromoCode == _normalizedPromoCode &&
        _lastPreviewInputVersion == _previewInputVersion;
  }

  List<PaymentMethodModel> get _availablePaymentMethods {
    return context.read<MobileBackendController>().paymentMethods;
  }

  MobilePaymentMethod get _currentPaymentMethod {
    final methods = _availablePaymentMethods;
    if (methods.isEmpty) return MobilePaymentMethod.unknown;
    final hasSelected = methods.any((method) => method.code == _paymentMethod);
    return hasSelected ? _paymentMethod : methods.first.code;
  }

  void _onPromoCodeChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<bool> _loadPreview() async {
    if (_isPreviewLoading || _isChangingDestination) return false;
    if (_availablePaymentMethods.isEmpty) {
      return _showPreviewError(L.of(context).paymentMethodsUnavailable);
    }

    final orderType = _orderType;
    final paymentMethod = _currentPaymentMethod;
    final promoCode = _normalizedPromoCode;
    final inputVersion = _previewInputVersion;
    setState(() {
      _isPreviewLoading = true;
      _previewErrorText = null;
      _previewDetails = null;
    });

    final result = await widget.onPreviewRequested(
      orderType: orderType,
      paymentMethod: paymentMethod,
      promoCode: promoCode,
    );
    if (!mounted) return false;

    if (orderType != _orderType ||
        paymentMethod != _currentPaymentMethod ||
        promoCode != _normalizedPromoCode ||
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
        inputVersion,
      ),
      Error(:final failure) => _showPreviewError(failure.message),
    };
  }

  bool _applyPreview(
    _CheckoutPreviewDetails details,
    MobileOrderType orderType,
    MobilePaymentMethod paymentMethod,
    String? promoCode,
    int inputVersion,
  ) {
    setState(() {
      _previewDetails = details;
      _lastPreviewOrderType = orderType;
      _lastPreviewPaymentMethod = paymentMethod;
      _lastPreviewPromoCode = promoCode;
      _lastPreviewInputVersion = inputVersion;
      _previewErrorText = null;
      _isPreviewLoading = false;
    });
    return true;
  }

  bool _showPreviewError(String message) {
    setState(() {
      _previewDetails = null;
      _previewErrorText = message;
      _isPreviewLoading = false;
    });
    return false;
  }

  Future<void> _confirmOrder() async {
    if (!_previewMatchesCurrentInput) {
      final didPreview = await _loadPreview();
      if (!didPreview || !mounted) return;
    }

    Navigator.of(context).pop(
      _OrderCreationResult(
        orderType: _orderType,
        paymentMethod: _currentPaymentMethod,
        promoCode: _normalizedPromoCode,
      ),
    );
  }

  Future<void> _showDeliveryAddressPicker() async {
    if (_isChangingDestination) return;

    if (_orderType != MobileOrderType.delivery) {
      setState(() => _orderType = MobileOrderType.delivery);
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
    unawaited(_loadPreview());
  }

  void _selectPaymentMethod(MobilePaymentMethod method) {
    if (_paymentMethod == method) return;
    setState(() => _paymentMethod = method);
    unawaited(_loadPreview());
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
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final backend = context.watch<MobileBackendController>();
    final paymentMethods = backend.paymentMethods;
    final currentPaymentMethod =
        paymentMethods.any((method) => method.code == _paymentMethod)
        ? _paymentMethod
        : paymentMethods.isEmpty
        ? MobilePaymentMethod.unknown
        : paymentMethods.first.code;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D1A18) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          18,
          10,
          18,
          20 + MediaQuery.paddingOf(context).bottom + bottomInset,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF4A4038)
                      : const Color(0xFFE5DAD0),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: TypographyText(
                    t.createOrderTitle,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TypographyText(
              t.orderType,
              style: const TextStyle(
                color: BaseColors.textGray,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            _OrderTypeToggle(
              orderType: _orderType,
              deliverySubtitle: _deliveryToggleSubtitle(),
              pickupSubtitle: _pickupToggleSubtitle(),
              onDeliveryTap: () => unawaited(_showDeliveryAddressPicker()),
              onPickupTap: () => unawaited(_showPickupBranchPicker()),
            ),
            const SizedBox(height: 14),
            TypographyText(
              t.promoCode,
              style: const TextStyle(
                color: BaseColors.textGray,
                fontSize: 13,
                fontWeight: FontWeight.w800,
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
            _PaymentMethodSelector(
              methods: paymentMethods,
              selectedMethod: currentPaymentMethod,
              isLoading: backend.paymentMethodsLoading,
              errorText: backend.paymentMethodsFailure?.message,
              onRetry: () => unawaited(_retryPaymentMethods()),
              onChanged: _selectPaymentMethod,
            ),
            const SizedBox(height: 14),
            _OrderItemsSection(cartLines: widget.cartLines),
            const SizedBox(height: 14),
            _CheckoutPreviewSummary(
              isLoading: _isPreviewLoading,
              details: _previewDetails,
              errorText: _previewErrorText,
              onRetry: () => unawaited(_loadPreview()),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: BaseColors.textGray,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: TypographyText(t.cancel),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: BaseColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed:
                        _isPreviewLoading ||
                            backend.paymentMethodsLoading ||
                            paymentMethods.isEmpty
                        ? null
                        : () => unawaited(_confirmOrder()),
                    child: TypographyText(
                      t.createOrderAction,
                      style: const TextStyle(color: BaseColors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
