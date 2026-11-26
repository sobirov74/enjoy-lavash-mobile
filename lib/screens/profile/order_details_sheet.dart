part of 'package:enjoy_lavash_mobile/screens/profile.dart';

const double _sheetHeightFactor = 0.9;
const double _sheetGutter = 18;
const double _sectionGap = 12;

class _OrderDetailsSheet extends StatefulWidget {
  const _OrderDetailsSheet({
    required this.order,
    required this.locale,
    required this.branches,
    required this.addresses,
  });

  final CustomerOrderModel order;
  final String locale;
  final List<BranchModel> branches;
  final List<ClientAddress> addresses;

  @override
  State<_OrderDetailsSheet> createState() => _OrderDetailsSheetState();
}

class _OrderDetailsSheetState extends State<_OrderDetailsSheet>
    with WidgetsBindingObserver {
  late CustomerOrderModel _order;
  bool _isRetryingPayment = false;
  bool _isRefreshingOrder = false;
  // The review was sent from this sheet: the card thanks the customer.
  bool _justReviewed = false;
  final GlobalKey _reviewCardKey = GlobalKey();
  Timer? _orderPollTimer;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_refreshOrderFromServer());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _orderPollTimer?.cancel();
    super.dispose();
  }

  /// No polling while the app is in the background; resuming refreshes at
  /// once (which re-arms the timer if the order is still active).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshOrderFromServer());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _orderPollTimer?.cancel();
    }
  }

  bool get _canRetryPayment =>
      _order.totalAmount > 0 && _order.paymentRetryAvailable;

  bool get _shouldPollOrder {
    if (_order.paymentStatus == MobilePaymentStatus.pending) return true;
    return switch (_order.status) {
      MobileOrderStatus.newOrder ||
      MobileOrderStatus.confirmed ||
      MobileOrderStatus.cooking ||
      MobileOrderStatus.ready ||
      MobileOrderStatus.courierAssigned ||
      MobileOrderStatus.onTheWay => true,
      _ => false,
    };
  }

  void _scheduleOrderPolling() {
    _orderPollTimer?.cancel();
    if (!_shouldPollOrder) return;
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) return;
    _orderPollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      unawaited(_refreshOrderFromServer());
    });
  }

  Future<void> _refreshOrderFromServer() async {
    if (_isRefreshingOrder) return;
    final backend = context.read<MobileBackendController>();
    // Signed out (or the session expired): stop instead of hitting a
    // protected endpoint every few seconds.
    if (!backend.isAuthenticated) {
      _orderPollTimer?.cancel();
      return;
    }
    _isRefreshingOrder = true;
    final result = await backend.refreshOrder(id: _order.id);
    _isRefreshingOrder = false;
    if (!mounted) return;

    switch (result) {
      case Success(:final data):
        // Every 8 s while the order is active; most polls change nothing.
        if (!_isSameOrder(data)) setState(() => _order = data);
      case Error(failure: AuthFailure()):
        _orderPollTimer?.cancel();
        return;
      case Error():
    }
    _scheduleOrderPolling();
  }

  bool _isSameOrder(CustomerOrderModel order) {
    return identical(order, _order) ||
        jsonEncode(order.raw) == jsonEncode(_order.raw);
  }

  Future<void> _retryPayment() async {
    if (_isRetryingPayment) return;
    final t = L.of(context);

    setState(() => _isRetryingPayment = true);
    final result = await context
        .read<MobileBackendController>()
        .retryOrderPayment(id: _order.id);
    if (!mounted) return;

    setState(() => _isRetryingPayment = false);
    switch (result) {
      case Success(:final data):
        setState(() => _order = data);
        _scheduleOrderPolling();
        final paymentUrl = data.paymentUrl?.trim();
        if (paymentUrl?.isNotEmpty != true) {
          _showOrderSnack(t.paymentLinkUnavailable);
          return;
        }

        final opened = await ExternalUrlLauncher.open(
          paymentUrl!,
          allowedHosts: paymentLinkHosts,
        );
        if (!mounted) return;
        _showOrderSnack(
          opened ? t.completePaymentOnline : t.paymentPageOpenFailed,
        );
      case Error(:final failure):
        _showOrderSnack(
          failureMessage(t, failure, fallback: t.retryPaymentFailed),
        );
    }
  }

  /// Opens the review form, with the star tapped on the card already chosen
  /// ([rating] is 0 when the card itself was tapped).
  Future<void> _rateOrder(int rating) async {
    final updated = await showOrderReviewSheet(
      context,
      _order,
      initialRating: rating,
    );
    if (!mounted || updated == null) return;
    setState(() {
      _order = updated;
      _justReviewed = true;
    });
    // The card now holds the saved review: bring it into view in case the
    // customer had scrolled past it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final card = _reviewCardKey.currentContext;
      if (!mounted || card == null) return;
      unawaited(
        Scrollable.ensureVisible(
          card,
          alignment: 0.1,
          duration: AppMotion.duration(context, AppMotion.state),
          curve: AppMotion.enter,
        ),
      );
    });
  }

  void _showOrderSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(appSnackBar(message));
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final order = _order;
    final destination = _orderDestination(
      order,
      widget.branches,
      widget.addresses,
      t,
    )?.trim();
    final createdAt = _formatOrderDateTime(order.createdAt, widget.locale);
    final scheduledFor = _formatOrderDateTime(
      order.scheduledFor,
      widget.locale,
    );
    final paymentStatus = order.paymentStatus;
    final promoCode = order.promoCode?.trim() ?? '';
    final comment = order.comment?.trim() ?? '';
    final kitchenOrder = order.iikoOrderId?.trim() ?? '';
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * _sheetHeightFactor,
      ),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppDesignTokens.surface(context),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDesignTokens.radiusSheet),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const AppBottomSheetDragHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              _sheetGutter,
              0,
              _sheetGutter - 6,
              _sectionGap,
            ),
            child: _OrderSheetHeader(
              title: t.orderDetails,
              subtitle: <String>[
                '#${_shortOrderId(order.id)}',
                if (createdAt.isNotEmpty) createdAt,
              ].join(' · '),
              onClose: () => Navigator.of(context).pop(),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                _sheetGutter,
                0,
                _sheetGutter,
                _sheetGutter + (_canRetryPayment ? 0 : bottomInset),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _OrderStatusHero(order: order, locale: widget.locale),
                  _OrderReviewCard(
                    key: _reviewCardKey,
                    order: order,
                    justSent: _justReviewed,
                    onRate: (rating) => unawaited(_rateOrder(rating)),
                  ),
                  const SizedBox(height: _sectionGap),
                  _OrderFactsCard(
                    facts: <_OrderFact>[
                      if (destination?.isNotEmpty == true)
                        _OrderFact(
                          icon: order.type == MobileOrderType.delivery
                              ? Icons.location_on_rounded
                              : Icons.storefront_rounded,
                          label: order.type == MobileOrderType.delivery
                              ? t.deliveryAddress
                              : t.pickupBranch,
                          value: destination!,
                        ),
                      if (scheduledFor.isNotEmpty)
                        _OrderFact(
                          icon: Icons.schedule_rounded,
                          label: t.scheduledFor,
                          value: scheduledFor,
                        ),
                      _OrderFact(
                        icon: Icons.payments_rounded,
                        label: t.payment,
                        value: paymentMethodLabel(order.paymentMethod, t),
                        badge:
                            paymentStatus == null ||
                                paymentStatus == MobilePaymentStatus.unknown
                            ? null
                            : _PaymentStatusBadge(status: paymentStatus),
                      ),
                    ],
                  ),
                  const SizedBox(height: _sectionGap),
                  _OrderReceiptCard(order: order),
                  const SizedBox(height: _sectionGap),
                  _OrderTimelineCard(
                    title: t.statusHistory,
                    entries: _statusEntries(order),
                    locale: widget.locale,
                  ),
                  if (promoCode.isNotEmpty ||
                      comment.isNotEmpty ||
                      kitchenOrder.isNotEmpty) ...[
                    const SizedBox(height: _sectionGap),
                    _OrderNotesCard(
                      title: t.additionalInfo,
                      notes: <({String label, String value})>[
                        if (promoCode.isNotEmpty)
                          (label: t.promoCode, value: promoCode),
                        if (comment.isNotEmpty)
                          (label: t.commentLabel, value: comment),
                        if (kitchenOrder.isNotEmpty)
                          (label: t.kitchenOrder, value: kitchenOrder),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_canRetryPayment)
            _OrderSheetActionBar(
              bottomInset: bottomInset,
              child: FilledButton.icon(
                key: const ValueKey<String>('details-retry-payment'),
                style: FilledButton.styleFrom(
                  backgroundColor: BaseColors.primary,
                  foregroundColor: BaseColors.white,
                  minimumSize: const Size.fromHeight(
                    AppDesignTokens.primaryButtonHeight,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppDesignTokens.radiusPill,
                    ),
                  ),
                ),
                onPressed: _isRetryingPayment
                    ? null
                    : () => unawaited(_retryPayment()),
                icon: _isRetryingPayment
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: BaseColors.white,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, size: 20),
                label: Text(
                  t.retryPayment,
                  style: AppTextStyles.display(
                    size: 16,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
