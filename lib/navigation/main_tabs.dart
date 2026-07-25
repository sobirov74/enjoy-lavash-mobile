import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:enjoy_lavash_mobile/app/locale_controller.dart';
import 'package:enjoy_lavash_mobile/app/location_controller.dart';
import 'package:enjoy_lavash_mobile/core/error/failures.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/core/services/app_share_service.dart';
import 'package:enjoy_lavash_mobile/core/services/external_url_launcher.dart';
import 'package:enjoy_lavash_mobile/core/services/mobile_push_notification_service.dart';
import 'package:enjoy_lavash_mobile/core/storage/cart_storage.dart';
import 'package:enjoy_lavash_mobile/features/models/cart_line.dart';
import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/address_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/branch_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/cart_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/loyalty_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/order_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/screens/address_bottom_sheet.dart';
import 'package:enjoy_lavash_mobile/screens/assigned_promotions_screen.dart';
import 'package:enjoy_lavash_mobile/screens/authorization_screen.dart';
import 'package:enjoy_lavash_mobile/screens/branch_bottom_sheet.dart';
import 'package:enjoy_lavash_mobile/screens/cart_screen.dart';
import 'package:enjoy_lavash_mobile/screens/menu_screen.dart';
import 'package:enjoy_lavash_mobile/screens/notifications_screen.dart';
import 'package:enjoy_lavash_mobile/screens/loyalty_wallet_screen.dart';
import 'package:enjoy_lavash_mobile/screens/profile.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/theme/app_motion.dart';
import 'package:enjoy_lavash_mobile/theme/theme_extensions.dart';
import 'package:enjoy_lavash_mobile/utils/price_formatter.dart';
import 'package:enjoy_lavash_mobile/widgets/app_bottom_sheet_drag_handle.dart';
import 'package:enjoy_lavash_mobile/widgets/app_snack_bar.dart';
import 'package:enjoy_lavash_mobile/widgets/fade_slide_in.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

part 'main_tabs/checkout_models.dart';
part 'main_tabs/main_tabs_bottom_navigation.dart';
part 'main_tabs/main_tabs_drawer.dart';
part 'main_tabs/order_success_screen.dart';
part 'main_tabs/order_confirmation_sheet.dart';
part 'main_tabs/order_type_toggle.dart';
part 'main_tabs/payment_method_selector.dart';
part 'main_tabs/promo_code_field.dart';
part 'main_tabs/order_confirmation_items.dart';
part 'main_tabs/checkout_preview_summary.dart';

String _formatLoyaltyPoints(BuildContext context, int value) {
  return NumberFormat.decimalPattern(
    Localizations.localeOf(context).toLanguageTag(),
  ).format(value);
}

class MainTabs extends StatefulWidget {
  const MainTabs({super.key});

  @override
  State<MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends State<MainTabs> {
  int _currentIndex = 0;
  int _selectedCategoryIndex = 0;
  final Map<String, int> _cart = <String, int>{};
  MobileOrderType _orderType = MobileOrderType.delivery;
  BranchModel? _selectedBranch;
  String? _deliveryBranchId;
  String _promoCode = '';
  bool _isCheckingOut = false;
  bool _cartEditedSinceLaunch = false;
  bool _pushNavigationScheduled = false;

  /// Built once so cart/category updates don't rebuild the profile subtree;
  /// it listens to its providers internally.
  late final Widget _profileTab = Profile(
    onRefresh: _refreshProfileData,
    onPromoSelected: _applyAssignedPromoCode,
  );

  @override
  void initState() {
    super.initState();
    unawaited(_restoreSavedCart());
  }

  Future<void> _restoreSavedCart() async {
    final savedCart = await CartStorage.read();
    if (!mounted || _cartEditedSinceLaunch || savedCart.isEmpty) return;
    setState(() => _cart.addAll(savedCart));
  }

  void _persistCart() {
    unawaited(CartStorage.save(_cart));
  }

  List<CartLine> _buildCartLines(List<MenuProduct> products) {
    final productById = <String, MenuProduct>{
      for (final product in products) product.id: product,
    };
    final lines = <CartLine>[];
    for (final entry in _cart.entries) {
      final product = productById[entry.key];
      if (product == null) continue;
      lines.add(CartLine(product: product, quantity: entry.value));
    }
    return lines;
  }

  int _calculateTotalAmount(List<CartLine> cartLines) {
    return cartLines.fold<int>(
      0,
      (sum, item) => sum + item.product.price * item.quantity,
    );
  }

  int _calculateTotalItems(List<CartLine> cartLines) {
    return cartLines.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  Future<void> _shareApp(L t) async {
    await AppShareService.share(t);
  }

  Future<bool> _ensureAuthenticated() async {
    if (context.read<MobileBackendController>().isAuthenticated) return true;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const AuthorizationScreen()),
    );
    return mounted && context.read<MobileBackendController>().isAuthenticated;
  }

  Future<void> _openNotifications() async {
    if (!await _ensureAuthenticated() || !mounted) return;
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const NotificationsScreen()),
    );
    if (code != null && mounted) {
      _applyAssignedPromoCode(code);
    }
  }

  Future<void> _openAssignedPromotions({String? highlightedCode}) async {
    if (!await _ensureAuthenticated() || !mounted) return;
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => AssignedPromotionsScreen(
          initialShowAll: highlightedCode?.trim().isNotEmpty == true,
          highlightedCode: highlightedCode,
        ),
      ),
    );
    if (code != null && mounted) {
      _applyAssignedPromoCode(code);
    }
  }

  void _applyAssignedPromoCode(String code) {
    final normalized = code.trim();
    if (normalized.isEmpty || !mounted) return;
    final products = context.read<MobileBackendController>().menuProducts;
    final hasCartItems = _buildCartLines(products).isNotEmpty;
    setState(() {
      _promoCode = normalized;
      _currentIndex = hasCartItems ? 1 : 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      appSnackBar(L.of(context).promoReadyForCheckout(normalized)),
    );
  }

  Future<void> _handlePushNavigation(PushNotificationMessage message) async {
    if (!message.openedByUser || !mounted) return;
    if (!await _ensureAuthenticated() || !mounted) return;
    final notificationId = message.notificationId?.trim();
    if (notificationId?.isNotEmpty == true) {
      await context.read<MobileBackendController>().markNotificationRead(
        notificationId: notificationId!,
      );
      if (!mounted) return;
    }

    if (message.opensPromotions) {
      await _openAssignedPromotions(highlightedCode: message.promotionCode);
      return;
    }
    if (message.opensLoyalty) {
      await context.read<MobileBackendController>().refreshLoyaltyWallet();
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => const LoyaltyWalletScreen()),
      );
      return;
    }
    await _openNotifications();
  }

  void _addToCart(MenuProduct product) {
    setState(() {
      _cartEditedSinceLaunch = true;
      _cart.update(product.id, (value) => value + 1, ifAbsent: () => 1);
    });
    _persistCart();
  }

  void _updateCart(MenuProduct product, int delta) {
    final previousQuantity = _cart[product.id] ?? 0;
    var removedLine = false;
    setState(() {
      _cartEditedSinceLaunch = true;
      final next = previousQuantity + delta;
      if (next <= 0) {
        _cart.remove(product.id);
        removedLine = previousQuantity > 0;
      } else {
        _cart[product.id] = next;
      }
    });
    _persistCart();

    if (removedLine) {
      final messenger = ScaffoldMessenger.of(context);
      showAutoClosingAppSnackBar(
        messenger,
        L.of(context).itemRemovedFromCart(product.title),
        actionLabel: L.of(context).undo,
        onAction: () {
          if (!mounted) return;
          setState(() {
            _cartEditedSinceLaunch = true;
            _cart[product.id] = previousQuantity;
          });
          _persistCart();
        },
      );
    }
  }

  void _setSelectedCategory(int index) {
    if (_selectedCategoryIndex == index) {
      return;
    }
    setState(() => _selectedCategoryIndex = index);
  }

  void _selectTab(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  void _setOrderType(MobileOrderType type) {
    final shouldReloadCatalog =
        type == MobileOrderType.delivery && _selectedBranch != null;

    setState(() {
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
    setState(() {
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

  List<CartItemInput> _buildOrderItems(List<CartLine> cartLines) {
    return cartLines
        .map(
          (line) => CartItemInput(
            productId: _orderProductId(line.product),
            quantity: line.quantity,
          ),
        )
        .toList(growable: false);
  }

  String _orderProductId(MenuProduct product) {
    final iikoId = product.iikoId?.trim();
    return iikoId == null || iikoId.isEmpty ? product.id : iikoId;
  }

  CreateOrderAddressInput? _inlineAddressFromLocation(
    LocationController location,
  ) {
    final latitude = location.latitude;
    final longitude = location.longitude;
    if (latitude == null || longitude == null) return null;

    final addressName = _trimmedOrNull(location.addressName);
    final fullAddress = _trimmedOrNull(location.fullAddress) ?? addressName;

    return CreateOrderAddressInput(
      latitude: latitude,
      longitude: longitude,
      label: addressName,
      text: fullAddress,
      street: addressName,
      houseNumber: _trimmedOrNull(location.houseNumber),
      apartmentNumber: _trimmedOrNull(location.apartment),
      entrance: _trimmedOrNull(location.entrance),
      floor: _trimmedOrNull(location.floor),
      comment: _trimmedOrNull(location.comment),
    );
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

  _CheckoutAddressDetails? _checkoutAddressDetails(CartPreviewRequest request) {
    final addresses = context.read<MobileBackendController>().addresses;
    final requestedAddressId = _trimmedOrNull(request.addressId);
    if (requestedAddressId != null) {
      for (final address in addresses) {
        if (address.id == requestedAddressId) {
          return _CheckoutAddressDetails(
            label: _trimmedOrNull(address.label),
            text: _formatClientAddressText(address),
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
      final label = _trimmedOrNull(location.addressName);
      final text = _trimmedOrNull(location.fullAddress) ?? label;
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
          label: _trimmedOrNull(address.label),
          text: _formatClientAddressText(address),
        );
      }
    }

    final fallbackAddress = _defaultAddress(addresses);
    if (fallbackAddress != null) {
      return _CheckoutAddressDetails(
        label: _trimmedOrNull(fallbackAddress.label),
        text: _formatClientAddressText(fallbackAddress),
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
      branchName: _trimmedOrNull(branch?.name),
      branchAddress: _trimmedOrNull(branch?.address),
      address: request.type == MobileOrderType.delivery
          ? _checkoutAddressDetails(request)
          : null,
    );
  }

  String? _trimmedOrNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  String? _normalizePromoCode(String? promoCode) {
    final trimmedPromoCode = promoCode?.trim();
    if (trimmedPromoCode == null || trimmedPromoCode.isEmpty) return null;
    return trimmedPromoCode;
  }

  CartPreviewAddressInput? _previewAddressFromLocation(
    LocationController location,
  ) {
    final latitude = location.latitude;
    final longitude = location.longitude;
    if (latitude == null || longitude == null) return null;

    return CartPreviewAddressInput(latitude: latitude, longitude: longitude);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(appSnackBar(message));
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
      ServerFailure() => t.errorBackend,
      _ => t.errorGenericTitle,
    };
    final message = failure.message.trim().isEmpty
        ? t.orderCreateFailed
        : failure.message.trim();

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

  Future<CartPreviewRequest?> _buildCartPreviewRequest(
    List<CartLine> cartLines, {
    required MobileOrderType orderType,
    required MobilePaymentMethod paymentMethod,
    int loyaltyRedemptionAmount = 0,
    String? promoCode,
  }) async {
    final t = L.of(context);
    final items = _buildOrderItems(cartLines);
    final normalizedPromoCode = _normalizePromoCode(promoCode);

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
    var address = _previewAddressFromLocation(location);
    String? addressId;
    final savedAddress = _defaultAddress(backend.addresses);
    if (address == null && savedAddress != null) {
      addressId = savedAddress.id;
    }

    if (address == null && addressId == null) {
      await showAddressBottomSheet(context);
      if (!mounted) return null;
      address = _previewAddressFromLocation(location);
      final fallbackSavedAddress = _defaultAddress(
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

  void _logCheckoutPayload(String scope, String label, Object? payload) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      debugPrint('[$scope] $label:\n${encoder.convert(payload)}');
    } catch (_) {
      debugPrint('[$scope] $label: $payload');
    }
  }

  Map<String, Object?> _cartPreviewLogPayload(CartPreviewModel preview) {
    return {
      'branchId': preview.branchId,
      'deliveryDistanceMeters': preview.deliveryDistanceMeters,
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
    final items = _buildOrderItems(cartLines);
    final normalizedPromoCode = _normalizePromoCode(promoCode);
    final normalizedComment = _trimmedOrNull(comment);

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
    var address = _inlineAddressFromLocation(location);
    String? addressId;
    final savedAddress = _defaultAddress(backend.addresses);
    if (address == null && savedAddress != null) {
      addressId = savedAddress.id;
    }

    if (address == null && addressId == null) {
      await showAddressBottomSheet(context);
      if (!mounted) return null;
      address = _inlineAddressFromLocation(location);
      final fallbackSavedAddress = _defaultAddress(
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
    return showModalBottomSheet<_OrderCreationResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      showDragHandle: false,
      builder: (context) {
        return _OrderConfirmationSheet(
          cartLines: cartLines,
          initialOrderType: _orderType,
          initialPromoCode: _promoCode,
          initialComment: _orderType == MobileOrderType.delivery
              ? _trimmedOrNull(context.read<LocationController>().comment)
              : null,
          initialPickupBranchId: _selectedBranch?.id,
          initialPickupBranchText: _trimmedOrNull(_selectedBranch?.name),
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
        );
      },
    );
  }

  Future<void> _handleCheckout(List<CartLine> cartLines) async {
    if (cartLines.isEmpty || _isCheckingOut) return;

    var backend = context.read<MobileBackendController>();
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

    setState(() => _promoCode = orderDetails.promoCode ?? '');

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
    setState(() => _isCheckingOut = true);
    final idempotencyKey = _newIdempotencyKey();
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
        final retryable =
            failure is NetworkFailure ||
            failure is TimeoutFailure ||
            (failure is ServerFailure && failure.statusCode >= 500);
        if (retryable) {
          creationErrorShown = true;
          final canRemovePoints =
              request.loyaltyRedemptionAmount > 0 &&
              failure is ServerFailure &&
              const <String>{
                'LOYALTY_UNAVAILABLE',
                'IIKO_LOYALTY_TENDER_UNAVAILABLE',
              }.contains(failure.errorCode);
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

    setState(() => _isCheckingOut = false);
    switch (result) {
      case Success(:final data):
        setState(() {
          _cartEditedSinceLaunch = true;
          _cart.clear();
          _promoCode = '';
          _currentIndex = 2;
        });
        _persistCart();
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
                  ? () => ExternalUrlLauncher.open(paymentUrl!)
                  : null,
              onTrackOrder: () => _openCreatedOrder(data),
            ),
            transitionsBuilder: (_, animation, _, child) => FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: AppMotion.enter,
                reverseCurve: AppMotion.exit,
              ),
              child: child,
            ),
          ),
        );
      case Error(:final failure):
        final loyaltyCode = failure is ServerFailure ? failure.errorCode : null;
        final resetLoyalty = const <String>{
          'LOYALTY_AMOUNT_CHANGED',
          'LOYALTY_DEBT_OUTSTANDING',
          'LOYALTY_REDEMPTION_DISABLED',
          'LOYALTY_PROGRAM_DISABLED',
          'IDEMPOTENCY_KEY_REUSED',
        }.contains(loyaltyCode);
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

  String _newIdempotencyKey() {
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final value = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }

  void _openCreatedOrder(CustomerOrderModel createdOrder) {
    if (!mounted) return;

    if (_currentIndex != 2) {
      setState(() => _currentIndex = 2);
    }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = L.of(context);
    final backend = context.watch<MobileBackendController>();
    final pendingPushMessage = backend.pendingPushMessage;
    if (pendingPushMessage != null && !_pushNavigationScheduled) {
      final message = backend.takePendingPushMessage();
      if (message != null) {
        _pushNavigationScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            await _handlePushNavigation(message);
          } finally {
            if (mounted) {
              setState(() => _pushNavigationScheduled = false);
            } else {
              _pushNavigationScheduled = false;
            }
          }
        });
      }
    }
    final categories = backend.menuCategories;
    final products = backend.menuProducts;
    final promotions = backend.promotions
        .where((promotion) => promotion.isActive)
        .toList(growable: false);
    final cartLines = _buildCartLines(products);
    final totalItems = _calculateTotalItems(cartLines);
    final totalAmount = _calculateTotalAmount(cartLines);
    final selectedCategoryIndex = categories.isEmpty
        ? 0
        : _selectedCategoryIndex.clamp(0, categories.length - 1);

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentIndex != 0) {
          _selectTab(0);
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        drawer: _MainTabsDrawer(
          isDark: isDark,
          t: t,
          onTabSelected: _selectTab,
          onShareApp: () => unawaited(_shareApp(t)),
        ),
        body: SafeArea(
          child: FadeIndexedStack(
            index: _currentIndex,
            children: <Widget>[
              MenuScreen(
                isDark: isDark,
                isMenuLoading:
                    backend.status == MobileBackendStatus.loading &&
                    products.isEmpty,
                menuErrorText:
                    backend.status == MobileBackendStatus.error &&
                        products.isEmpty
                    ? backend.failure?.message
                    : null,
                menuFailure:
                    backend.status == MobileBackendStatus.error &&
                        products.isEmpty
                    ? backend.failure
                    : null,
                selectedCategoryIndex: selectedCategoryIndex,
                categories: categories,
                products: products,
                promotions: promotions,
                orderType: _orderType,
                selectedBranch: _selectedBranch,
                onCategorySelected: _setSelectedCategory,
                onAddToCart: _addToCart,
                onDecreaseFromCart: (product) => _updateCart(product, -1),
                onCartTap: () => _selectTab(1),
                onOrderTypeChanged: _setOrderType,
                onBranchSelected: _setPickupBranch,
                onRefresh: _refreshMenuData,
                onRetryMenu: () =>
                    context.read<MobileBackendController>().bootstrap(
                      language: context
                          .read<LocaleController>()
                          .locale
                          .languageCode,
                      branchId: _selectedBranch?.id,
                    ),
                cartCount: totalItems,
                cartTotal: totalAmount,
                cartQuantities: _cart,
                notificationUnreadCount: backend.notificationUnreadCount,
                onNotificationsTap: () => unawaited(_openNotifications()),
              ),
              CartScreen(
                isDark: isDark,
                items: cartLines,
                totalAmount: totalAmount,
                isCheckingOut: _isCheckingOut,
                onDecrease: (product) => _updateCart(product, -1),
                onIncrease: (product) => _updateCart(product, 1),
                onBrowseMenu: () => _selectTab(0),
                onCheckout: () => unawaited(_handleCheckout(cartLines)),
              ),
              _profileTab,
            ],
          ),
        ),
        bottomNavigationBar: _MainTabsBottomNavigation(
          theme: theme,
          isDark: isDark,
          currentIndex: _currentIndex,
          totalItems: totalItems,
          t: t,
          onDestinationSelected: _selectTab,
        ),
      ),
    );
  }
}
