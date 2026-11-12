part of 'package:enjoy_lavash_mobile/navigation/main_tabs.dart';

class _CheckoutPreviewSummary extends StatelessWidget {
  const _CheckoutPreviewSummary({
    required this.isLoading,
    required this.onRetry,
    this.details,
    this.errorText,
  });

  final bool isLoading;
  final _CheckoutPreviewDetails? details;
  final String? errorText;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppDesignTokens.inset(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: isLoading && details == null
            ? const _PreviewLoadingState(key: ValueKey<String>('loading'))
            : details == null
            ? _PreviewErrorState(
                key: const ValueKey<String>('error'),
                message: errorText ?? t.couldNotCalculateTotal,
                onRetry: onRetry,
              )
            : _PreviewTotals(
                key: const ValueKey<String>('totals'),
                details: details!,
                isRefreshing: isLoading,
              ),
      ),
    );
  }
}

class _PreviewLoadingState extends StatelessWidget {
  const _PreviewLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);

    return Row(
      children: <Widget>[
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: BaseColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TypographyText(
            t.calculatingTotal,
            style: const TextStyle(
              color: BaseColors.textGray,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewErrorState extends StatelessWidget {
  const _PreviewErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(
              Icons.info_outline_rounded,
              color: BaseColors.danger,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TypographyText(
                message,
                style: const TextStyle(
                  color: BaseColors.danger,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: BaseColors.primary,
            side: const BorderSide(color: BaseColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: TypographyText(t.recalculate),
        ),
      ],
    );
  }
}

class _PreviewTotals extends StatelessWidget {
  const _PreviewTotals({
    super.key,
    required this.details,
    required this.isRefreshing,
  });

  final _CheckoutPreviewDetails details;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final preview = details.preview;
    final appliedPromotion = preview.appliedPromotion;
    final promoCode = appliedPromotion?.code?.trim();
    final promoTitle = appliedPromotion?.titleFor(
      Localizations.localeOf(context).languageCode,
    );
    final promotionStatusMessage = _promotionStatusMessage(t, preview);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: TypographyText(
                t.orderPreview,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (isRefreshing)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: BaseColors.primary,
                ),
              ),
            const SizedBox(width: 6),
            IconButton(
              key: const ValueKey<String>('order-preview-details-button'),
              tooltip: t.viewOrderDetails,
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(
                backgroundColor: BaseColors.primary.withValues(alpha: 0.1),
                foregroundColor: BaseColors.primary,
              ),
              onPressed: () => _showCheckoutPreviewDetails(context, details),
              icon: const Icon(Icons.more_horiz_rounded, size: 22),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _PreviewDestination(details: details),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Divider(height: 1, color: Color(0x1A8C8278)),
        ),
        _PreviewAmountRow(
          label: t.items,
          value: formatSum(context, preview.itemsAmount),
        ),
        if (preview.modifiersAmount > 0)
          _PreviewAmountRow(
            label: t.modifiers,
            value: formatSum(context, preview.modifiersAmount),
          ),
        if (preview.discountAmount > 0)
          _PreviewAmountRow(
            label: t.discount,
            value: '-${formatSum(context, preview.discountAmount)}',
            valueColor: BaseColors.primary,
          ),
        if (details.orderType == MobileOrderType.delivery ||
            preview.deliveryAmount > 0)
          _PreviewAmountRow(
            label: t.delivery,
            value: formatSum(context, preview.deliveryAmount),
          ),
        if (preview.promotionDeliveryDiscountAmount > 0)
          _PreviewAmountRow(
            label: '${t.delivery} ${t.discount.toLowerCase()}',
            value:
                '-${formatSum(context, preview.promotionDeliveryDiscountAmount)}',
            valueColor: BaseColors.primary,
          ),
        if (preview.serviceFeeAmount > 0)
          _PreviewAmountRow(
            label: t.serviceFee,
            value: formatSum(context, preview.serviceFeeAmount),
          ),
        if (appliedPromotion != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: BaseColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.local_offer_outlined,
                  color: BaseColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TypographyText(
                    [
                      if (promoCode?.isNotEmpty == true) promoCode!,
                      if (promoTitle?.isNotEmpty == true) promoTitle!,
                    ].join(' - '),
                    style: const TextStyle(
                      color: BaseColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (promotionStatusMessage != null) ...[
          const SizedBox(height: 8),
          _PreviewPromotionStatus(message: promotionStatusMessage),
        ],
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Divider(height: 1, color: Color(0x1A8C8278)),
        ),
        _PreviewAmountRow(
          label: t.orderBeforePoints,
          value: formatSum(context, preview.totalBeforePointsAmount),
        ),
        if ((preview.loyalty?.appliedPoints ?? 0) > 0)
          _PreviewAmountRow(
            label: t.pointsUsed,
            value:
                '-${_formatLoyaltyPoints(context, preview.loyalty!.appliedPoints)}',
            valueColor: BaseColors.primary,
          ),
        _PreviewAmountRow(
          label: t.amountToPay,
          value: formatSum(context, preview.totalAmount),
          isTotal: true,
          valueColor: BaseColors.primary,
        ),
        if (preview.loyalty != null) ...[
          const SizedBox(height: 9),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: BaseColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: BaseColors.success,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      TypographyText(
                        '${t.estimatedPoints}: '
                        '+${_formatLoyaltyPoints(context, preview.loyalty!.estimatedEarnPoints)}',
                        style: const TextStyle(
                          color: BaseColors.success,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      TypographyText(
                        t.estimatedPointsHint,
                        style: const TextStyle(
                          color: BaseColors.textGray,
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String? _promotionStatusMessage(L t, CartPreviewModel preview) {
    if (!preview.hasPromotionStatus ||
        preview.promotionStatus == CartPromotionStatus.none ||
        preview.promotionStatus == CartPromotionStatus.applied) {
      return null;
    }

    final reason = preview.promotionStatusReason?.trim();
    if (reason?.isNotEmpty == true) return reason;
    return switch (preview.promotionStatus) {
      CartPromotionStatus.notFound => t.promoCodeNotFound,
      CartPromotionStatus.inactive => t.promoCodeInactive,
      CartPromotionStatus.notStarted => t.promoCodeNotStarted,
      CartPromotionStatus.expired => t.promoCodeExpired,
      CartPromotionStatus.globalLimitReached => t.promoGlobalLimitReached,
      CartPromotionStatus.clientLimitReached => t.promoClientLimitReached,
      CartPromotionStatus.clientRequired => t.promoClientRequired,
      CartPromotionStatus.conditionsNotMet => t.promoConditionsNotMet,
      CartPromotionStatus.configurationError => t.promoConfigurationError,
      CartPromotionStatus.unknown => t.promoCodeCouldNotBeApplied,
      CartPromotionStatus.none || CartPromotionStatus.applied => null,
    };
  }
}

class _PreviewPromotionStatus extends StatelessWidget {
  const _PreviewPromotionStatus({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: BaseColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.info_outline_rounded,
            color: BaseColors.danger,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TypographyText(
              message,
              style: const TextStyle(
                color: BaseColors.danger,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewAmountRow extends StatelessWidget {
  const _PreviewAmountRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isTotal ? 0 : 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TypographyText(
              label,
              style: TextStyle(
                color: BaseColors.textGray,
                fontSize: isTotal ? 15 : 13,
                fontWeight: isTotal ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          TypographyText(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: isTotal ? 22 : 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
