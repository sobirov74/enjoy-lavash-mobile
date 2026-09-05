part of 'package:enjoy_lavash_mobile/navigation/main_tabs.dart';

/// A one-shot handoff between checkout and the customer's live order history.
///
/// The actionable content is never gated by animation. If online payment is
/// required, [openPaymentPage] runs after the first frame so this confirmation
/// is already in the navigation stack when the external payment app opens.
class OrderSuccessScreen extends StatefulWidget {
  const OrderSuccessScreen({
    super.key,
    required this.order,
    required this.onTrackOrder,
    this.openPaymentPage,
    this.onBackHome,
  });

  final CustomerOrderModel order;
  final VoidCallback onTrackOrder;
  final Future<bool> Function()? openPaymentPage;
  final VoidCallback? onBackHome;

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

enum _PaymentPageLaunchState { notNeeded, opening, opened, failed }

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _markController = AnimationController(
    vsync: this,
    duration: AppMotion.celebration,
  );
  late _PaymentPageLaunchState _paymentPageState;
  bool _motionConfigured = false;

  @override
  void initState() {
    super.initState();
    _paymentPageState = widget.openPaymentPage == null
        ? _PaymentPageLaunchState.notNeeded
        : _PaymentPageLaunchState.opening;
    if (widget.openPaymentPage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openPaymentPage());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _markController.stop();
      _markController.value = 1;
      _motionConfigured = true;
      return;
    }
    if (_motionConfigured) return;
    _motionConfigured = true;
    _markController.forward();
  }

  Future<void> _openPaymentPage() async {
    final openPaymentPage = widget.openPaymentPage;
    if (openPaymentPage == null) return;

    if (mounted && _paymentPageState != _PaymentPageLaunchState.opening) {
      setState(() => _paymentPageState = _PaymentPageLaunchState.opening);
    }

    var opened = false;
    try {
      opened = await openPaymentPage();
    } catch (_) {
      opened = false;
    }
    if (!mounted) return;
    setState(() {
      _paymentPageState = opened
          ? _PaymentPageLaunchState.opened
          : _PaymentPageLaunchState.failed;
    });
  }

  @override
  void dispose() {
    _markController.dispose();
    super.dispose();
  }

  void _trackOrder() {
    final onTrackOrder = widget.onTrackOrder;
    final navigator = Navigator.of(context);
    if (!navigator.canPop()) {
      onTrackOrder();
      return;
    }

    navigator.pop();
    WidgetsBinding.instance.addPostFrameCallback((_) => onTrackOrder());
  }

  void _backHome() {
    final callback = widget.onBackHome;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
    if (callback != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => callback());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = L.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final orderNumber = _successOrderNumber(widget.order.id);
    final paymentPresentation = _paymentPresentation(t);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
                child: Column(
                  children: <Widget>[
                    ExcludeSemantics(
                      child: AnimatedBuilder(
                        key: const ValueKey<String>('order-success-mark'),
                        animation: _markController,
                        builder: (context, child) {
                          final progress = AppMotion.enter.transform(
                            _markController.value,
                          );
                          return Opacity(
                            opacity: 0.55 + (progress * 0.45),
                            child: Transform.scale(
                              scale: 0.9 + (progress * 0.1),
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          width: 76,
                          height: 76,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppDesignTokens.success.withValues(alpha: 0.2)
                                : AppDesignTokens.successWash,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: AppDesignTokens.success,
                            size: 42,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TypographyText(
                      t.orderSuccessTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TypographyText(
                      t.orderSuccessMessage,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: isDark
                            ? const Color(0xFFC8C0B9)
                            : BaseColors.textGray,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: AppDesignTokens.surface(context),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppDesignTokens.hairline(context),
                        ),
                      ),
                      child: TypographyText(
                        t.orderSuccessNumber(orderNumber),
                        style: TextStyle(
                          color: AppDesignTokens.primaryText(context),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _OrderSuccessPaymentCard(
                      presentation: paymentPresentation,
                      isDark: isDark,
                      title: t.payment,
                    ),
                    if (widget.order.loyaltyRedeemedAmount > 0 ||
                        widget.order.loyalty.eligible) ...[
                      const SizedBox(height: 12),
                      _OrderSuccessLoyaltyCard(order: widget.order),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? const Color(0xFF332D28)
                        : BaseColors.borderLight,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (_paymentPageState ==
                      _PaymentPageLaunchState.failed) ...<Widget>[
                    OutlinedButton.icon(
                      key: const ValueKey<String>(
                        'order-success-retry-payment-button',
                      ),
                      onPressed: _openPaymentPage,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(t.retryPayment),
                    ),
                    const SizedBox(height: 10),
                  ],
                  FilledButton.icon(
                    key: const ValueKey<String>('order-success-track-button'),
                    onPressed: _trackOrder,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(
                        AppDesignTokens.primaryButtonHeight,
                      ),
                      backgroundColor: isDark
                          ? const Color(0xFFF4EEE8)
                          : AppDesignTokens.ink,
                      foregroundColor: isDark
                          ? AppDesignTokens.ink
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDesignTokens.radiusPill,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.route_rounded),
                    label: TypographyText(
                      t.trackOrder,
                      style: TextStyle(
                        color: isDark ? AppDesignTokens.ink : BaseColors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    key: const ValueKey<String>('order-success-home-button'),
                    onPressed: _backHome,
                    child: Text(t.backToHome),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _OrderSuccessPaymentPresentation _paymentPresentation(L t) {
    final status = widget.order.paymentStatus ?? MobilePaymentStatus.unknown;
    final paysOnline =
        widget.order.paymentMethod == MobilePaymentMethod.payme ||
        widget.order.paymentMethod == MobilePaymentMethod.click ||
        widget.openPaymentPage != null;

    if (widget.order.totalAmount == 0 &&
        widget.order.loyaltyRedeemedAmount > 0) {
      return _OrderSuccessPaymentPresentation(
        icon: Icons.stars_rounded,
        accent: BaseColors.success,
        status: t.fullyPaidWithPoints,
        message: t.orderSuccessPaymentPaid,
      );
    }

    if (_paymentPageState == _PaymentPageLaunchState.opening) {
      return _OrderSuccessPaymentPresentation(
        icon: Icons.open_in_new_rounded,
        accent: BaseColors.primary,
        status: t.paymentStatusPending,
        message: t.orderSuccessPaymentOpening,
      );
    }
    if (_paymentPageState == _PaymentPageLaunchState.failed) {
      return _OrderSuccessPaymentPresentation(
        icon: Icons.warning_amber_rounded,
        accent: BaseColors.danger,
        status: status == MobilePaymentStatus.pending
            ? t.paymentStatusPending
            : t.onlinePayment,
        message: t.orderCreatedPaymentPageOpenFailed,
      );
    }

    final statusPresentation = switch (status) {
      MobilePaymentStatus.paid => _OrderSuccessPaymentPresentation(
        icon: Icons.verified_rounded,
        accent: BaseColors.success,
        status: t.paymentStatusPaid,
        message: t.orderSuccessPaymentPaid,
      ),
      MobilePaymentStatus.failed => _OrderSuccessPaymentPresentation(
        icon: Icons.error_outline_rounded,
        accent: BaseColors.danger,
        status: t.paymentStatusFailed,
        message: t.orderSuccessPaymentFailed,
      ),
      MobilePaymentStatus.refunded => _OrderSuccessPaymentPresentation(
        icon: Icons.currency_exchange_rounded,
        accent: BaseColors.textGray,
        status: t.paymentStatusRefunded,
        message: t.orderSuccessPaymentRefunded,
      ),
      MobilePaymentStatus.pending || MobilePaymentStatus.unknown => null,
    };
    if (statusPresentation != null) return statusPresentation;

    if (!paysOnline) {
      return _OrderSuccessPaymentPresentation(
        icon: Icons.payments_outlined,
        accent: BaseColors.primary,
        status: t.payOnReceipt,
        message: t.orderSuccessPayOnReceipt,
      );
    }

    return _OrderSuccessPaymentPresentation(
      icon: Icons.schedule_rounded,
      accent: BaseColors.primary,
      status: status == MobilePaymentStatus.pending
          ? t.paymentStatusPending
          : t.onlinePayment,
      message: _paymentPageState == _PaymentPageLaunchState.opened
          ? t.orderSuccessPaymentOpened
          : t.paymentLinkUnavailable,
    );
  }
}

class _OrderSuccessLoyaltyCard extends StatelessWidget {
  const _OrderSuccessLoyaltyCard({required this.order});

  final CustomerOrderModel order;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accrual = order.loyalty.accrual;
    final accrualText = switch (accrual.status) {
      LoyaltyAccrualStatus.pending => t.loyaltyPending,
      LoyaltyAccrualStatus.earned =>
        '${t.loyaltyEarned}: '
            '+${_formatLoyaltyPoints(context, accrual.creditedAmount)}',
      LoyaltyAccrualStatus.noReward => t.loyaltyNoReward,
      LoyaltyAccrualStatus.reversed => t.loyaltyReversed,
      LoyaltyAccrualStatus.notEligible || LoyaltyAccrualStatus.unknown => null,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D1A18) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x1A8C8278)),
      ),
      child: Column(
        children: <Widget>[
          _OrderSuccessAmountLine(
            label: t.orderBeforePoints,
            value: formatSum(context, order.totalBeforePointsAmount),
          ),
          if (order.loyaltyRedeemedAmount > 0) ...[
            const SizedBox(height: 8),
            _OrderSuccessAmountLine(
              label: t.pointsUsed,
              value:
                  '-${_formatLoyaltyPoints(context, order.loyaltyRedeemedAmount)}',
              color: BaseColors.primary,
            ),
          ],
          const SizedBox(height: 8),
          _OrderSuccessAmountLine(
            label: t.amountToPay,
            value: formatSum(context, order.totalAmount),
            color: BaseColors.primary,
            strong: true,
          ),
          if (accrualText != null) ...[
            const Divider(height: 22),
            Row(
              children: <Widget>[
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: BaseColors.success,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TypographyText(
                    accrualText,
                    style: const TextStyle(
                      color: BaseColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
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

class _OrderSuccessAmountLine extends StatelessWidget {
  const _OrderSuccessAmountLine({
    required this.label,
    required this.value,
    this.color,
    this.strong = false,
  });

  final String label;
  final String value;
  final Color? color;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: TypographyText(
            label,
            style: const TextStyle(color: BaseColors.textGray, fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        TypographyText(
          value,
          style: TextStyle(
            color: color,
            fontSize: strong ? 16 : 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

String _successOrderNumber(String id) {
  final value = id.trim();
  if (value.length <= 8) return value.toUpperCase();
  return value.substring(value.length - 8).toUpperCase();
}

class _OrderSuccessPaymentPresentation {
  const _OrderSuccessPaymentPresentation({
    required this.icon,
    required this.accent,
    required this.status,
    required this.message,
  });

  final IconData icon;
  final Color accent;
  final String status;
  final String message;
}

class _OrderSuccessPaymentCard extends StatelessWidget {
  const _OrderSuccessPaymentCard({
    required this.presentation,
    required this.isDark,
    required this.title,
  });

  final _OrderSuccessPaymentPresentation presentation;
  final bool isDark;
  final String title;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      key: const ValueKey<String>('order-success-payment-card'),
      duration: AppMotion.duration(context, AppMotion.micro),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF27221F) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: presentation.accent.withValues(alpha: isDark ? 0.32 : 0.2),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: presentation.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              presentation.icon,
              color: presentation.accent,
              size: 23,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TypographyText(
                  '$title · ${presentation.status}',
                  style: TextStyle(
                    color: presentation.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                TypographyText(
                  presentation.message,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFC8C0B9)
                        : BaseColors.textGray,
                    fontSize: 14,
                    height: 1.35,
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
