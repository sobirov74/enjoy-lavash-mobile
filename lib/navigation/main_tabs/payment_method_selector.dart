part of 'package:enjoy_lavash_mobile/navigation/main_tabs.dart';

class _PaymentMethodSelector extends StatelessWidget {
  const _PaymentMethodSelector({
    required this.methods,
    required this.selectedMethod,
    required this.onChanged,
  });

  final List<PaymentMethodModel> methods;
  final MobilePaymentMethod selectedMethod;
  final ValueChanged<MobilePaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2522) : const Color(0xFFF8F4EF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.payments_outlined,
                color: BaseColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              TypographyText(
                t.payment,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            children: <Widget>[
              for (int i = 0; i < methods.length; i++) ...[
                _PaymentMethodChip(
                  key: ValueKey<String>(methods[i].id),
                  method: methods[i],
                  selected: methods[i].code == selectedMethod,
                  onTap: () => onChanged(methods[i].code),
                ),
                if (i < methods.length - 1) const SizedBox(height: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodChip extends StatelessWidget {
  const _PaymentMethodChip({
    super.key,
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethodModel method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = method.name.trim().isEmpty
        ? _confirmationPaymentLabel(method.code, t)
        : method.name.trim();
    final selectedColor = isDark
        ? BaseColors.primary.withValues(alpha: 0.2)
        : BaseColors.primary.withValues(alpha: 0.1);
    final idleColor = isDark ? const Color(0xFF201C19) : Colors.white;

    return Material(
      color: selected ? selectedColor : idleColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: selected ? null : onTap,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 62),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? BaseColors.primary
                  : isDark
                  ? const Color(0xFF3A332D)
                  : const Color(0xFFEDE2D7),
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected
                      ? BaseColors.primary
                      : BaseColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _paymentMethodIcon(method.code),
                  color: selected ? BaseColors.white : BaseColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TypographyText(
                      label,
                      style: TextStyle(
                        color: selected
                            ? BaseColors.primary
                            : isDark
                            ? const Color(0xFFF6EFE7)
                            : BaseColors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        _PaymentMethodBadge(
                          label: method.isOnline
                              ? t.onlinePayment
                              : t.payOnReceipt,
                          selected: selected,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: selected
                    ? const Icon(
                        Icons.check_circle_rounded,
                        key: ValueKey<String>('selected'),
                        color: BaseColors.primary,
                        size: 24,
                      )
                    : Icon(
                        Icons.radio_button_unchecked_rounded,
                        key: const ValueKey<String>('idle'),
                        color: isDark
                            ? const Color(0xFF8F867E)
                            : const Color(0xFFC5B8AC),
                        size: 22,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodBadge extends StatelessWidget {
  const _PaymentMethodBadge({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: selected
            ? BaseColors.primary.withValues(alpha: 0.14)
            : BaseColors.textGray.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: TypographyText(
        label,
        style: TextStyle(
          color: selected ? BaseColors.primary : BaseColors.textGray,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

String _confirmationPaymentLabel(MobilePaymentMethod method, L t) {
  return switch (method) {
    MobilePaymentMethod.cash => t.paymentCash,
    MobilePaymentMethod.cardTerminal => t.paymentCardTerminal,
    MobilePaymentMethod.payme => 'Payme',
    MobilePaymentMethod.click => 'Click',
    MobilePaymentMethod.unknown => t.unknown,
  };
}

IconData _paymentMethodIcon(MobilePaymentMethod method) {
  return switch (method) {
    MobilePaymentMethod.cash => Icons.payments_outlined,
    MobilePaymentMethod.cardTerminal => Icons.credit_card_rounded,
    MobilePaymentMethod.payme => Icons.account_balance_wallet_outlined,
    MobilePaymentMethod.click => Icons.touch_app_outlined,
    MobilePaymentMethod.unknown => Icons.help_outline_rounded,
  };
}
