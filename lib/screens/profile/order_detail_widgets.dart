part of 'package:enjoy_lavash_mobile/screens/profile.dart';

const double _detailCardPadding = 16;
const double _detailIconBox = 36;
const double _heroBadgeExtent = 48;
const double _timelineRailWidth = 24;
const double _timelineDot = 10;
const double _timelineCurrentDot = 14;
const double _productAmountWidthShare = 0.38;

/// The brand colour that stays readable on the dark sheet.
Color _detailAccent(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? BaseColors.primaryOnDark
    : BaseColors.primary;

/// Title and order number, with the close button.
class _OrderSheetHeader extends StatelessWidget {
  const _OrderSheetHeader({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  final String title;
  final String subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: AppTextStyles.display(
                  size: 22,
                  weight: FontWeight.w800,
                  color: AppDesignTokens.primaryText(context),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: AppTextStyles.ui(
                  size: 13,
                  weight: FontWeight.w500,
                  color: AppDesignTokens.secondaryText(context),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          key: const ValueKey<String>('order-details-close'),
          tooltip: L.of(context).close,
          onPressed: onClose,
          style: IconButton.styleFrom(
            backgroundColor: AppDesignTokens.inset(context),
            foregroundColor: AppDesignTokens.primaryText(context),
          ),
          icon: const Icon(Icons.close_rounded, size: 22),
        ),
      ],
    );
  }
}

/// The order's current status, tinted like its row in the history, with the
/// journey underneath while the order is on its way.
class _OrderStatusHero extends StatelessWidget {
  const _OrderStatusHero({required this.order, required this.locale});

  final CustomerOrderModel order;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = _statusSurfaceColors(order.status, isDark);
    final updatedAt = _formatOrderDateTime(order.updatedAt, locale);

    return Container(
      padding: const EdgeInsets.all(_detailCardPadding),
      decoration: BoxDecoration(
        color: surface.bg,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusHero),
        border: Border.all(color: surface.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: _heroBadgeExtent,
                height: _heroBadgeExtent,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: surface.accent.withValues(alpha: isDark ? 0.26 : 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _statusIcon(order.status),
                  color: isDark
                      ? Color.lerp(surface.accent, Colors.white, 0.35)
                      : surface.accent,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      t.currentStatus,
                      style: AppTextStyles.ui(
                        size: 12,
                        weight: FontWeight.w600,
                        color: AppDesignTokens.secondaryText(context),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _statusLabel(order.status, t),
                      style: AppTextStyles.display(
                        size: 20,
                        height: 1.15,
                        weight: FontWeight.w800,
                        color: AppDesignTokens.primaryText(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_supportsOrderJourney(order.type, order.status)) ...[
            const SizedBox(height: 16),
            OrderProgressJourney(orderType: order.type, status: order.status),
          ],
          const SizedBox(height: 14),
          // Wraps under each other when the text is large.
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 8,
              children: <Widget>[
                _OrderTypeChip(type: order.type),
                if (updatedAt.isNotEmpty)
                  Text(
                    '${t.lastUpdate}: $updatedAt',
                    style: AppTextStyles.ui(
                      size: 12,
                      color: AppDesignTokens.secondaryText(context),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderTypeChip extends StatelessWidget {
  const _OrderTypeChip({required this.type});

  final MobileOrderType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppDesignTokens.surface(context),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
        border: Border.all(color: AppDesignTokens.hairline(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(_orderTypeIcon(type), size: 16, color: _detailAccent(context)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              _orderTypeLabel(type, L.of(context)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.ui(
                size: 12,
                weight: FontWeight.w700,
                color: AppDesignTokens.primaryText(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A card set into the sheet. Every section below the status uses it.
class _OrderDetailCard extends StatelessWidget {
  const _OrderDetailCard({required this.child, this.title, this.trailing});

  final Widget child;
  final String? title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(_detailCardPadding),
      decoration: BoxDecoration(
        color: AppDesignTokens.inset(context),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title != null) ...[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title!,
                    style: AppTextStyles.display(
                      size: 16,
                      weight: FontWeight.w800,
                      color: AppDesignTokens.primaryText(context),
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}

class _OrderFact {
  const _OrderFact({
    required this.icon,
    required this.label,
    required this.value,
    this.badge,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? badge;
}

/// Where, when and how the order is paid: one card, one line each.
class _OrderFactsCard extends StatelessWidget {
  const _OrderFactsCard({required this.facts});

  final List<_OrderFact> facts;

  @override
  Widget build(BuildContext context) {
    return _OrderDetailCard(
      child: Column(
        children: <Widget>[
          for (int i = 0; i < facts.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.only(
                  left: _detailIconBox + 12,
                  top: 12,
                  bottom: 12,
                ),
                child: Divider(
                  height: 1,
                  color: AppDesignTokens.hairline(context),
                ),
              ),
            _OrderFactLine(fact: facts[i]),
          ],
        ],
      ),
    );
  }
}

class _OrderFactLine extends StatelessWidget {
  const _OrderFactLine({required this.fact});

  final _OrderFact fact;

  @override
  Widget build(BuildContext context) {
    final accent = _detailAccent(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: _detailIconBox,
          height: _detailIconBox,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusThumb),
          ),
          child: Icon(fact.icon, color: accent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                fact.label,
                style: AppTextStyles.ui(
                  size: 12,
                  weight: FontWeight.w500,
                  color: AppDesignTokens.secondaryText(context),
                ),
              ),
              const SizedBox(height: 2),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: <Widget>[
                  Text(
                    fact.value,
                    style: AppTextStyles.ui(
                      size: 14.5,
                      height: 1.3,
                      weight: FontWeight.w700,
                      color: AppDesignTokens.primaryText(context),
                    ),
                  ),
                  ?fact.badge,
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentStatusBadge extends StatelessWidget {
  const _PaymentStatusBadge({required this.status});

  final MobilePaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      MobilePaymentStatus.paid => AppDesignTokens.successText(context),
      MobilePaymentStatus.pending => AppDesignTokens.goldText(context),
      MobilePaymentStatus.failed => AppDesignTokens.dangerText(context),
      MobilePaymentStatus.refunded ||
      MobilePaymentStatus.unknown => AppDesignTokens.tertiaryText(context),
    };
    return Container(
      key: const ValueKey<String>('order-payment-status'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
      ),
      child: Text(
        _paymentStatusLabel(status, L.of(context)),
        style: AppTextStyles.ui(
          size: 12,
          weight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// What was ordered and what it cost, laid out like a receipt: the lines,
/// a tear line, then the points and the amount to pay.
class _OrderReceiptCard extends StatelessWidget {
  const _OrderReceiptCard({required this.order});

  final CustomerOrderModel order;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final pieces = order.items.fold<int>(
      0,
      (total, item) => total + item.quantity,
    );
    final redemption = order.loyalty.redemption;
    final pointsRestored =
        redemption?.status == LoyaltyRedemptionStatus.released ||
        redemption?.status == LoyaltyRedemptionStatus.refunded;
    final points = decimalFormat(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(order.loyaltyRedeemedAmount);
    final showsLoyalty =
        order.loyaltyRedeemedAmount > 0 || order.loyalty.eligible;

    return _OrderDetailCard(
      title: t.products,
      trailing: pieces > 0
          ? Text(
              t.cartItemsCount(pieces),
              style: AppTextStyles.ui(
                size: 12,
                weight: FontWeight.w600,
                color: AppDesignTokens.secondaryText(context),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (order.items.isEmpty)
            Text(
              _orderProductSummary(order, t),
              style: AppTextStyles.ui(
                size: 14,
                color: AppDesignTokens.secondaryText(context),
              ),
            )
          else
            for (int i = 0; i < order.items.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _OrderProductDetailLine(item: order.items[i]),
            ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: _ReceiptTearLine(),
          ),
          if (order.loyaltyRedeemedAmount > 0) ...[
            _OrderAmountDetailLine(
              label: t.orderBeforePoints,
              value: _formatOrderAmount(context, order.totalBeforePointsAmount),
            ),
            const SizedBox(height: 8),
            _OrderAmountDetailLine(
              label: pointsRestored ? t.loyaltyRestored : t.pointsUsed,
              value: '${pointsRestored ? '+' : '-'}$points',
              valueColor: pointsRestored
                  ? AppDesignTokens.successText(context)
                  : _detailAccent(context),
            ),
            const SizedBox(height: 10),
          ],
          _OrderAmountDetailLine(
            label: t.amountToPay,
            value: _formatOrderAmount(context, order.totalAmount),
            strong: true,
          ),
          if (showsLoyalty) _OrderLoyaltyNote(order: order),
        ],
      ),
    );
  }
}

/// What the order did to the customer's points, under the receipt total.
class _OrderLoyaltyNote extends StatelessWidget {
  const _OrderLoyaltyNote({required this.order});

  final CustomerOrderModel order;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final accrual = order.loyalty.accrual;
    final hasExpired =
        accrual.status == LoyaltyAccrualStatus.earned &&
        accrual.expiresAt != null &&
        accrual.expiresAt!.isBefore(DateTime.now());
    final label = hasExpired
        ? t.transactionExpiry
        : switch (accrual.status) {
            LoyaltyAccrualStatus.pending => t.loyaltyPending,
            LoyaltyAccrualStatus.earned =>
              '${t.loyaltyEarned}: '
                  '+${decimalFormat(Localizations.localeOf(context).toLanguageTag()).format(accrual.creditedAmount)}',
            LoyaltyAccrualStatus.noReward => t.loyaltyNoReward,
            LoyaltyAccrualStatus.reversed => t.loyaltyReversed,
            LoyaltyAccrualStatus.notEligible ||
            LoyaltyAccrualStatus.unknown => null,
          };
    if (label == null) return const SizedBox.shrink();

    final reversed = accrual.status == LoyaltyAccrualStatus.reversed;
    final color = reversed
        ? AppDesignTokens.dangerText(context)
        : AppDesignTokens.successText(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        key: const ValueKey<String>('order-loyalty-note'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusInput),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              reversed ? Icons.undo_rounded : Icons.auto_awesome_rounded,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.ui(
                  size: 13,
                  weight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
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
    final primaryText = AppDesignTokens.primaryText(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        // The label keeps its own width; the value takes the rest and sits
        // against the right edge.
        Flexible(
          child: Text(
            label,
            style: AppTextStyles.ui(
              size: strong ? 14.5 : 13,
              weight: strong ? FontWeight.w700 : FontWeight.w500,
              color: strong
                  ? primaryText
                  : AppDesignTokens.secondaryText(context),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTextStyles.display(
              size: strong ? 22 : 14.5,
              weight: FontWeight.w800,
              color:
                  valueColor ?? (strong ? _detailAccent(context) : primaryText),
            ),
          ),
        ),
      ],
    );
  }
}

/// The dashed line a receipt is torn along.
class _ReceiptTearLine extends StatelessWidget {
  const _ReceiptTearLine();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 1.5,
      child: CustomPaint(
        painter: _DashedLinePainter(
          color: AppDesignTokens.controlBorder(context),
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color});

  static const double _dash = 5;
  static const double _gap = 4;

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.height
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    for (double x = 0; x < size.width; x += _dash + _gap) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + _dash, size.width), y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _OrderProductDetailLine extends StatelessWidget {
  const _OrderProductDetailLine({required this.item});

  final CustomerOrderItemModel item;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final accent = _detailAccent(context);
    final amount = item.amount > 0
        ? _formatOrderAmount(context, item.amount)
        : null;
    final comment = item.comment?.trim() ?? '';

    // A long amount in large text wraps instead of pushing the title out.
    return LayoutBuilder(
      builder: (context, constraints) {
        final amountMaxWidth = constraints.maxWidth * _productAmountWidthShare;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              constraints: const BoxConstraints(minWidth: 34),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
              ),
              child: Text(
                '${item.quantity}×',
                style: AppTextStyles.ui(
                  size: 12,
                  weight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _orderProductTitle(item, t),
                      style: AppTextStyles.ui(
                        size: 14.5,
                        height: 1.25,
                        weight: FontWeight.w700,
                        color: AppDesignTokens.primaryText(context),
                      ),
                    ),
                    if (comment.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        comment,
                        style: AppTextStyles.ui(
                          size: 12,
                          height: 1.25,
                          color: AppDesignTokens.secondaryText(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (amount != null) ...[
              const SizedBox(width: 10),
              Container(
                constraints: BoxConstraints(maxWidth: amountMaxWidth),
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  amount,
                  textAlign: TextAlign.end,
                  style: AppTextStyles.ui(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: AppDesignTokens.secondaryText(context),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// The order's status changes as a timeline, oldest first; the last entry is
/// where the order stands now.
class _OrderTimelineCard extends StatelessWidget {
  const _OrderTimelineCard({
    required this.title,
    required this.entries,
    required this.locale,
  });

  final String title;
  final List<OrderStatusLogModel> entries;
  final String locale;

  @override
  Widget build(BuildContext context) {
    return _OrderDetailCard(
      title: title,
      child: Column(
        children: <Widget>[
          for (int i = 0; i < entries.length; i++)
            _OrderTimelineEntry(
              entry: entries[i],
              locale: locale,
              isFirst: i == 0,
              isLast: i == entries.length - 1,
            ),
        ],
      ),
    );
  }
}

class _OrderTimelineEntry extends StatelessWidget {
  const _OrderTimelineEntry({
    required this.entry,
    required this.locale,
    required this.isFirst,
    required this.isLast,
  });

  final OrderStatusLogModel entry;
  final String locale;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _statusSurfaceColors(entry.status, isDark).accent;
    final railColor = AppDesignTokens.controlBorder(context);
    final changedAt = _formatOrderDateTime(entry.changedAt, locale);
    final comment = entry.comment?.trim() ?? '';
    final dot = isLast ? _timelineCurrentDot : _timelineDot;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: _timelineRailWidth,
            child: Column(
              children: <Widget>[
                // The rail runs through the dot, which sits beside the label.
                SizedBox(
                  height: 4,
                  child: isFirst
                      ? null
                      : VerticalDivider(
                          width: 2,
                          thickness: 2,
                          color: railColor,
                        ),
                ),
                Container(
                  width: dot,
                  height: dot,
                  decoration: BoxDecoration(
                    color: isLast ? accent : railColor,
                    shape: BoxShape.circle,
                    border: isLast
                        ? Border.all(
                            color: accent.withValues(alpha: 0.3),
                            width: 3,
                            strokeAlign: BorderSide.strokeAlignOutside,
                          )
                        : null,
                  ),
                ),
                Expanded(
                  child: isLast
                      ? const SizedBox.shrink()
                      : VerticalDivider(
                          width: 2,
                          thickness: 2,
                          color: railColor,
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _statusLabel(entry.status, t),
                    style: AppTextStyles.ui(
                      size: 14.5,
                      weight: isLast ? FontWeight.w800 : FontWeight.w600,
                      color: isLast
                          ? AppDesignTokens.primaryText(context)
                          : AppDesignTokens.tertiaryText(context),
                    ),
                  ),
                  if (changedAt.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      changedAt,
                      style: AppTextStyles.ui(
                        size: 12,
                        color: AppDesignTokens.secondaryText(context),
                      ),
                    ),
                  ],
                  if (comment.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      comment,
                      style: AppTextStyles.ui(
                        size: 12,
                        height: 1.25,
                        color: AppDesignTokens.secondaryText(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Promo code, the customer's comment and the kitchen's order number.
class _OrderNotesCard extends StatelessWidget {
  const _OrderNotesCard({required this.title, required this.notes});

  final String title;
  final List<({String label, String value})> notes;

  @override
  Widget build(BuildContext context) {
    return _OrderDetailCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int i = 0; i < notes.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            Text(
              notes[i].label,
              style: AppTextStyles.ui(
                size: 12,
                weight: FontWeight.w500,
                color: AppDesignTokens.secondaryText(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              notes[i].value,
              style: AppTextStyles.ui(
                size: 14.5,
                height: 1.3,
                weight: FontWeight.w700,
                color: AppDesignTokens.primaryText(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The sheet's pinned action (paying again), always in reach above the
/// system bar.
class _OrderSheetActionBar extends StatelessWidget {
  const _OrderSheetActionBar({required this.child, required this.bottomInset});

  final Widget child;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        _sheetGutter,
        12,
        _sheetGutter,
        12 + bottomInset,
      ),
      decoration: BoxDecoration(
        color: AppDesignTokens.surface(context),
        border: Border(
          top: BorderSide(color: AppDesignTokens.hairline(context)),
        ),
      ),
      child: child,
    );
  }
}
