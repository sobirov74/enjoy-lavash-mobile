part of 'package:enjoy_lavash_mobile/navigation/main_tabs.dart';

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
    final formatted = dateFormat(
      locale,
      'd MMM, HH:mm',
      (locale) => DateFormat('d MMM, HH:mm', locale),
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
