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

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  bool get _canRetryPayment => _order.paymentRetryAvailable;

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
          failure.message.isNotEmpty
              ? failure.message
              : t.retryPaymentFailed,
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
              child: Row(
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
            Row(
              children: <Widget>[
                Expanded(
                  child: TypographyText(
                    t.total,
                    style: const TextStyle(
                      color: BaseColors.textGray,
                      fontSize: 15,
                    ),
                  ),
                ),
                TypographyText(
                  _formatOrderAmount(order.totalAmount),
                  style: const TextStyle(
                    color: BaseColors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
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
