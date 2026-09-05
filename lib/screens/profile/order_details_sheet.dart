part of 'package:enjoy_lavash_mobile/screens/profile.dart';

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

class _OrderDetailsSheetState extends State<_OrderDetailsSheet> {
  late CustomerOrderModel _order;
  bool _isRetryingPayment = false;
  bool _isRefreshingOrder = false;
  Timer? _orderPollTimer;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_refreshOrderFromServer());
    });
  }

  @override
  void dispose() {
    _orderPollTimer?.cancel();
    super.dispose();
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
    _orderPollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      unawaited(_refreshOrderFromServer());
    });
  }

  Future<void> _refreshOrderFromServer() async {
    if (_isRefreshingOrder) return;
    _isRefreshingOrder = true;
    final result = await context.read<MobileBackendController>().refreshOrder(
      id: _order.id,
    );
    _isRefreshingOrder = false;
    if (!mounted) return;

    if (result case Success(:final data)) {
      setState(() => _order = data);
    }
    _scheduleOrderPolling();
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

        final opened = await ExternalUrlLauncher.open(paymentUrl!);
        if (!mounted) return;
        _showOrderSnack(
          opened ? t.completePaymentOnline : t.paymentPageOpenFailed,
        );
      case Error(:final failure):
        _showOrderSnack(
          failure.message.isNotEmpty ? failure.message : t.retryPaymentFailed,
        );
    }
  }

  void _showOrderSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(appSnackBar(message));
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final order = _order;
    final colors = _statusColors(order.status);
    final destination = _orderDestination(
      order,
      widget.branches,
      widget.addresses,
      t,
    );
    final statusEntries = _statusEntries(order);
    final createdAt = _formatOrderDateTime(order.createdAt, widget.locale);
    final scheduledFor = _formatOrderDateTime(
      order.scheduledFor,
      widget.locale,
    );
    final updatedAt = _formatOrderDateTime(order.updatedAt, widget.locale);

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
          22 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const AppBottomSheetDragHandle(),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      TypographyText(
                        t.orderDetails,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TypographyText(
                        '#${_shortOrderId(order.id)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: BaseColors.textGray,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.bg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(Icons.track_changes_rounded, color: colors.text),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            TypographyText(
                              t.currentStatus,
                              style: TextStyle(
                                color: colors.text.withValues(alpha: 0.78),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            TypographyText(
                              _statusLabel(order.status, t),
                              style: TextStyle(
                                color: colors.text,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_supportsOrderJourney(order.type, order.status)) ...[
                    const SizedBox(height: 14),
                    OrderProgressJourney(
                      orderType: order.type,
                      status: order.status,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            _OrderInfoPill(
              icon: _orderTypeIcon(order.type),
              label: t.orderType,
              value: _orderTypeLabel(order.type, t),
            ),
            if (createdAt.isNotEmpty) ...[
              const SizedBox(height: 8),
              _OrderInfoPill(
                icon: Icons.event_available_rounded,
                label: t.created,
                value: createdAt,
              ),
            ],
            if (scheduledFor.isNotEmpty) ...[
              const SizedBox(height: 8),
              _OrderInfoPill(
                icon: Icons.schedule_rounded,
                label: t.scheduledFor,
                value: scheduledFor,
              ),
            ],
            if (updatedAt.isNotEmpty) ...[
              const SizedBox(height: 8),
              _OrderInfoPill(
                icon: Icons.update_rounded,
                label: t.lastUpdate,
                value: updatedAt,
              ),
            ],
            const SizedBox(height: 8),
            _OrderInfoPill(
              icon: Icons.payments_outlined,
              label: t.payment,
              value: _paymentMethodLabel(order.paymentMethod, t),
            ),
            if (order.paymentStatus != null &&
                order.paymentStatus != MobilePaymentStatus.unknown) ...[
              const SizedBox(height: 8),
              _OrderInfoPill(
                icon: Icons.verified_outlined,
                label: t.paymentStatus,
                value: _paymentStatusLabel(order.paymentStatus!, t),
              ),
            ],
            if (_canRetryPayment) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: BaseColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isRetryingPayment
                      ? null
                      : () => unawaited(_retryPayment()),
                  icon: _isRetryingPayment
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: BaseColors.white,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded, size: 19),
                  label: TypographyText(
                    t.retryPayment,
                    style: const TextStyle(
                      color: BaseColors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
            if (destination?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 8),
              _OrderInfoPill(
                icon: order.type == MobileOrderType.delivery
                    ? Icons.location_on_outlined
                    : Icons.storefront_rounded,
                label: order.type == MobileOrderType.delivery
                    ? t.deliveryAddress
                    : t.selectBranch,
                value: destination!.trim(),
              ),
            ],
            const SizedBox(height: 14),
            _OrderDetailSection(
              title: t.products,
              children: order.items.isEmpty
                  ? <Widget>[
                      TypographyText(
                        _orderProductSummary(order, t),
                        style: const TextStyle(color: BaseColors.textGray),
                      ),
                    ]
                  : <Widget>[
                      for (int i = 0; i < order.items.length; i++) ...[
                        _OrderProductDetailLine(item: order.items[i]),
                        if (i < order.items.length - 1)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(height: 1, color: Color(0x1A8C8278)),
                          ),
                      ],
                    ],
            ),
            if (order.loyaltyRedeemedAmount > 0 || order.loyalty.eligible) ...[
              const SizedBox(height: 12),
              _OrderLoyaltyDetailSection(order: order),
            ],
            const SizedBox(height: 12),
            _OrderDetailSection(
              title: t.statusHistory,
              children: <Widget>[
                for (int i = 0; i < statusEntries.length; i++) ...[
                  _OrderStatusLogLine(
                    entry: statusEntries[i],
                    locale: widget.locale,
                  ),
                  if (i < statusEntries.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
            if (order.promoCode?.trim().isNotEmpty == true ||
                order.comment?.trim().isNotEmpty == true ||
                order.iikoOrderId?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 12),
              _OrderDetailSection(
                title: t.additionalInfo,
                children: <Widget>[
                  if (order.promoCode?.trim().isNotEmpty == true)
                    _OrderTextDetail(
                      label: t.promoCode,
                      value: order.promoCode!.trim(),
                    ),
                  if (order.comment?.trim().isNotEmpty == true) ...[
                    if (order.promoCode?.trim().isNotEmpty == true)
                      const SizedBox(height: 10),
                    _OrderTextDetail(
                      label: t.commentLabel,
                      value: order.comment!.trim(),
                    ),
                  ],
                  if (order.iikoOrderId?.trim().isNotEmpty == true) ...[
                    if (order.promoCode?.trim().isNotEmpty == true ||
                        order.comment?.trim().isNotEmpty == true)
                      const SizedBox(height: 10),
                    _OrderTextDetail(
                      label: t.kitchenOrder,
                      value: order.iikoOrderId!.trim(),
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 14),
            _OrderAmountDetailLine(
              label: t.amountToPay,
              value: _formatOrderAmount(context, order.totalAmount),
              strong: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderLoyaltyDetailSection extends StatelessWidget {
  const _OrderLoyaltyDetailSection({required this.order});

  final CustomerOrderModel order;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final redemption = order.loyalty.redemption;
    final accrual = order.loyalty.accrual;
    final hasExpired =
        accrual.status == LoyaltyAccrualStatus.earned &&
        accrual.expiresAt != null &&
        accrual.expiresAt!.isBefore(DateTime.now());
    final accrualLabel = hasExpired
        ? t.transactionExpiry
        : switch (accrual.status) {
            LoyaltyAccrualStatus.pending => t.loyaltyPending,
            LoyaltyAccrualStatus.earned =>
              '${t.loyaltyEarned}: '
                  '+${NumberFormat.decimalPattern(Localizations.localeOf(context).toLanguageTag()).format(accrual.creditedAmount)}',
            LoyaltyAccrualStatus.noReward => t.loyaltyNoReward,
            LoyaltyAccrualStatus.reversed => t.loyaltyReversed,
            LoyaltyAccrualStatus.notEligible ||
            LoyaltyAccrualStatus.unknown => null,
          };
    final restored =
        redemption?.status == LoyaltyRedemptionStatus.released ||
        redemption?.status == LoyaltyRedemptionStatus.refunded;

    return _OrderDetailSection(
      title: t.loyaltyWallet,
      children: <Widget>[
        _OrderAmountDetailLine(
          label: t.orderBeforePoints,
          value: _formatOrderAmount(context, order.totalBeforePointsAmount),
        ),
        if (order.loyaltyRedeemedAmount > 0) ...[
          const SizedBox(height: 9),
          _OrderAmountDetailLine(
            label: restored ? t.loyaltyRestored : t.pointsUsed,
            value:
                '${restored ? '+' : '-'}'
                '${NumberFormat.decimalPattern(Localizations.localeOf(context).toLanguageTag()).format(order.loyaltyRedeemedAmount)}',
            valueColor: restored ? BaseColors.success : BaseColors.primary,
          ),
        ],
        const SizedBox(height: 9),
        _OrderAmountDetailLine(
          label: t.amountToPay,
          value: _formatOrderAmount(context, order.totalAmount),
          strong: true,
        ),
        if (accrualLabel != null) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 11),
            child: Divider(height: 1, color: Color(0x1A8C8278)),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                accrual.status == LoyaltyAccrualStatus.reversed
                    ? Icons.undo_rounded
                    : Icons.auto_awesome_rounded,
                color: accrual.status == LoyaltyAccrualStatus.reversed
                    ? BaseColors.danger
                    : BaseColors.success,
                size: 19,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TypographyText(
                  accrualLabel,
                  style: TextStyle(
                    color: accrual.status == LoyaltyAccrualStatus.reversed
                        ? BaseColors.danger
                        : BaseColors.success,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _OrderAmountDetailLine extends StatelessWidget {
  const _OrderAmountDetailLine({
    required this.label,
    required this.value,
    this.valueColor,
    this.strong = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: TypographyText(
            label,
            style: const TextStyle(color: BaseColors.textGray, fontSize: 13),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: TypographyText(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: valueColor ?? (strong ? BaseColors.primary : null),
              fontSize: strong ? 18 : 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

const List<MobileOrderStatus> _deliveryJourneyStages = <MobileOrderStatus>[
  MobileOrderStatus.newOrder,
  MobileOrderStatus.confirmed,
  MobileOrderStatus.cooking,
  MobileOrderStatus.ready,
  MobileOrderStatus.courierAssigned,
  MobileOrderStatus.onTheWay,
  MobileOrderStatus.delivered,
];

const List<MobileOrderStatus> _pickupJourneyStages = <MobileOrderStatus>[
  MobileOrderStatus.newOrder,
  MobileOrderStatus.confirmed,
  MobileOrderStatus.cooking,
  MobileOrderStatus.ready,
  MobileOrderStatus.delivered,
];

List<MobileOrderStatus> _orderJourneyStages(MobileOrderType orderType) {
  return switch (orderType) {
    MobileOrderType.delivery => _deliveryJourneyStages,
    MobileOrderType.pickup => _pickupJourneyStages,
  };
}

bool _supportsOrderJourney(
  MobileOrderType orderType,
  MobileOrderStatus status,
) {
  return _orderJourneyStages(orderType).contains(status);
}

double _orderJourneyProgress(
  MobileOrderType orderType,
  MobileOrderStatus status,
) {
  final stages = _orderJourneyStages(orderType);
  final index = stages.indexOf(status);
  if (index <= 0) return 0;
  return index / (stages.length - 1);
}

/// A quiet, state-driven journey through an order's real lifecycle.
///
/// It starts at the supplied status and only animates when that status changes.
/// There are no timers or repeating effects, so the indicator never implies
/// progress that the server has not reported.
class OrderProgressJourney extends StatefulWidget {
  const OrderProgressJourney({
    super.key,
    required this.orderType,
    required this.status,
  });

  final MobileOrderType orderType;
  final MobileOrderStatus status;

  @override
  State<OrderProgressJourney> createState() => _OrderProgressJourneyState();
}

class _OrderProgressJourneyState extends State<OrderProgressJourney>
    with SingleTickerProviderStateMixin {
  late double _targetProgress;
  late final AnimationController _controller;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _targetProgress = _orderJourneyProgress(widget.orderType, widget.status);
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.spatial,
      value: _targetProgress,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = AppMotion.reduced(context);
    _controller.duration = AppMotion.duration(context, AppMotion.spatial);
    if (_reduceMotion) {
      _controller.value = _targetProgress;
    }
  }

  @override
  void didUpdateWidget(covariant OrderProgressJourney oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderType == widget.orderType &&
        oldWidget.status == widget.status) {
      return;
    }

    final nextProgress = _orderJourneyProgress(widget.orderType, widget.status);
    _targetProgress = nextProgress;
    _controller.stop();

    if (_reduceMotion ||
        !_supportsOrderJourney(widget.orderType, widget.status)) {
      _controller.value = nextProgress;
      return;
    }

    _controller.animateTo(nextProgress, curve: AppMotion.enter);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stages = _orderJourneyStages(widget.orderType);
    final currentIndex = stages.indexOf(widget.status);
    if (currentIndex < 0) return const SizedBox.shrink();

    final t = L.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = BaseColors.primary;
    final trackColor = isDark
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.black.withValues(alpha: 0.12);
    final idleDotColor = isDark
        ? const Color(0xFF665D56)
        : const Color(0xFFD8CEC5);

    return Semantics(
      key: const ValueKey<String>('order-progress-journey'),
      container: true,
      label: '${t.currentStatus}: ${_statusLabel(widget.status, t)}',
      child: ExcludeSemantics(
        child: Column(
          children: <Widget>[
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final journeyPosition = _controller.value * (stages.length - 1);
                return Row(
                  children: <Widget>[
                    for (int index = 0; index < stages.length; index++) ...[
                      _OrderJourneyDot(
                        key: ValueKey<String>('order-progress-dot-$index'),
                        progress: index == 0
                            ? 1
                            : (journeyPosition - (index - 1))
                                  .clamp(0.0, 1.0)
                                  .toDouble(),
                        current: index == currentIndex,
                        accent: accent,
                        idleColor: idleDotColor,
                      ),
                      if (index < stages.length - 1)
                        Expanded(
                          child: _OrderJourneySegment(
                            index: index,
                            progress: (journeyPosition - index)
                                .clamp(0.0, 1.0)
                                .toDouble(),
                            accent: accent,
                            trackColor: trackColor,
                          ),
                        ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 7),
            Row(
              children: <Widget>[
                Expanded(
                  child: TypographyText(
                    _statusLabel(stages.first, t),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFB8AEA5)
                          : BaseColors.textGray,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TypographyText(
                    _statusLabel(stages.last, t),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFB8AEA5)
                          : BaseColors.textGray,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
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

class _OrderJourneySegment extends StatelessWidget {
  const _OrderJourneySegment({
    required this.index,
    required this.progress,
    required this.accent,
    required this.trackColor,
  });

  final int index;
  final double progress;
  final Color accent;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          height: 3,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              ColoredBox(color: trackColor),
              Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  key: ValueKey<String>('order-progress-segment-$index-fill'),
                  widthFactor: progress,
                  heightFactor: 1,
                  child: ColoredBox(color: accent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderJourneyDot extends StatelessWidget {
  const _OrderJourneyDot({
    super.key,
    required this.progress,
    required this.current,
    required this.accent,
    required this.idleColor,
  });

  final double progress;
  final bool current;
  final Color accent;
  final Color idleColor;

  @override
  Widget build(BuildContext context) {
    final fill = Color.lerp(idleColor, accent, progress)!;

    return SizedBox.square(
      dimension: 18,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: current
              ? Border.all(color: accent.withValues(alpha: 0.38), width: 3)
              : null,
        ),
        child: Center(
          child: Container(
            width: current ? 9 : 7,
            height: current ? 9 : 7,
            decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}
