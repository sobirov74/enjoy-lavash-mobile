part of 'package:enjoy_lavash_mobile/navigation/main_tabs.dart';

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
                                  fillColor: AppDesignTokens.surface(context),
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
