import 'dart:async';

import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/loyalty_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/widgets/animated_error_message.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class LoyaltyWalletScreen extends StatefulWidget {
  const LoyaltyWalletScreen({super.key});

  @override
  State<LoyaltyWalletScreen> createState() => _LoyaltyWalletScreenState();
}

class _LoyaltyWalletScreenState extends State<LoyaltyWalletScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreNearEnd);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_refresh());
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadMoreNearEnd)
      ..dispose();
    super.dispose();
  }

  void _loadMoreNearEnd() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.extentAfter > 280) return;
    final backend = context.read<MobileBackendController>();
    if (!backend.hasMoreLoyaltyTransactions ||
        backend.loyaltyTransactionsLoadingMore) {
      return;
    }
    unawaited(backend.loadMoreLoyaltyTransactions());
  }

  Future<void> _refresh() async {
    final backend = context.read<MobileBackendController>();
    await Future.wait<Object?>([
      backend.refreshLoyaltyWallet(),
      backend.refreshLoyaltyTransactions(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final theme = Theme.of(context);
    final backend = context.watch<MobileBackendController>();
    final wallet = backend.loyaltyWallet;
    final transactions = backend.loyaltyTransactions;
    final isInitialLoading =
        wallet == null && backend.loyaltyWalletLoading && transactions.isEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: TypographyText(
          t.loyaltyWallet,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: RefreshIndicator(
        color: BaseColors.primary,
        onRefresh: _refresh,
        child: isInitialLoading
            ? const _WalletSkeleton()
            : CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: <Widget>[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                    sliver: SliverToBoxAdapter(
                      child: wallet == null
                          ? AnimatedErrorMessage(
                              failure: backend.loyaltyWalletFailure,
                              onRetry: () => unawaited(_refresh()),
                            )
                          : _WalletOverview(wallet: wallet),
                    ),
                  ),
                  if (wallet != null)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                      sliver: SliverToBoxAdapter(
                        child: _HowPointsWork(wallet: wallet),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    sliver: SliverToBoxAdapter(
                      child: TypographyText(
                        t.loyaltyHistory,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  if (backend.loyaltyTransactionsLoading &&
                      transactions.isEmpty)
                    const SliverToBoxAdapter(child: _HistorySkeleton())
                  else if (backend.loyaltyTransactionsFailure != null &&
                      transactions.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverToBoxAdapter(
                        child: AnimatedErrorMessage(
                          failure: backend.loyaltyTransactionsFailure,
                          onRetry: () =>
                              unawaited(backend.refreshLoyaltyTransactions()),
                        ),
                      ),
                    )
                  else if (transactions.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 36),
                      sliver: SliverToBoxAdapter(
                        child: _EmptyHistory(message: t.loyaltyHistoryEmpty),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      sliver: SliverList.separated(
                        itemCount: transactions.length,
                        itemBuilder: (context, index) =>
                            _TransactionTile(transaction: transactions[index]),
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                      ),
                    ),
                  if (backend.loyaltyTransactionsLoadingMore)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: BaseColors.primary,
                            strokeWidth: 2.5,
                          ),
                        ),
                      ),
                    ),
                  if (backend.loyaltyTransactionsFailure != null &&
                      transactions.isNotEmpty &&
                      !backend.loyaltyTransactionsLoadingMore)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      sliver: SliverToBoxAdapter(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              unawaited(backend.loadMoreLoyaltyTransactions()),
                          icon: const Icon(Icons.refresh_rounded),
                          label: TypographyText(t.retry),
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
      ),
    );
  }
}

class _WalletOverview extends StatelessWidget {
  const _WalletOverview({required this.wallet});

  final LoyaltyWalletModel wallet;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final expiry = wallet.nextExpiryAt == null
        ? null
        : DateFormat.yMMMd(locale).format(wallet.nextExpiryAt!.toLocal());

    return Column(
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFFFF9A68), Color(0xFFFF6843)],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: BaseColors.primary.withValues(alpha: 0.25),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.stars_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TypographyText(
                      t.spendablePoints,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Semantics(
                label:
                    '${t.spendablePoints}: '
                    '${_formatPoints(context, wallet.spendableBalance)}',
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: TypographyText(
                    _formatPoints(context, wallet.spendableBalance),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TypographyText(
                t.loyaltyPointValueInfo,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.86),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _WalletMetric(
                icon: Icons.lock_clock_outlined,
                label: t.reservedPoints,
                value: _formatPoints(context, wallet.reservedBalance),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _WalletMetric(
                icon: Icons.event_busy_outlined,
                label: wallet.expiringWithinSevenDays > 0
                    ? t.pointsExpiringSoon
                    : t.nextPointsExpiry,
                value: wallet.expiringWithinSevenDays > 0
                    ? _formatPoints(context, wallet.expiringWithinSevenDays)
                    : (expiry ?? '—'),
                accent: wallet.expiringWithinSevenDays > 0,
              ),
            ),
          ],
        ),
        if (wallet.debtBalance > 0) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: BaseColors.danger.withValues(alpha: isDark ? 0.2 : 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: BaseColors.danger.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(
                  Icons.warning_amber_rounded,
                  color: BaseColors.danger,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      TypographyText(
                        '${t.loyaltyDebt}: '
                        '${_formatPoints(context, wallet.debtBalance)}',
                        style: const TextStyle(
                          color: BaseColors.danger,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      TypographyText(
                        t.loyaltyDebtHint,
                        style: const TextStyle(
                          color: BaseColors.textGray,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        if (!wallet.programEnabled || !wallet.redemptionEnabled) ...[
          const SizedBox(height: 10),
          _InfoBanner(
            icon: Icons.info_outline_rounded,
            text: !wallet.programEnabled
                ? t.loyaltyProgramUnavailable
                : t.loyaltyRedemptionUnavailable,
          ),
        ],
      ],
    );
  }
}

class _WalletMetric extends StatelessWidget {
  const _WalletMetric({
    required this.icon,
    required this.label,
    required this.value,
    this.accent = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = accent ? BaseColors.primaryDark : BaseColors.primary;
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D1A18) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent
              ? BaseColors.primary.withValues(alpha: 0.35)
              : const Color(0x1A8C8278),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 9),
          TypographyText(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          TypographyText(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: BaseColors.textGray,
              fontSize: 11,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _HowPointsWork extends StatelessWidget {
  const _HowPointsWork({required this.wallet});

  final LoyaltyWalletModel wallet;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D1A18) : Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TypographyText(
            t.loyaltyHowItWorks,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          _HowItem(
            icon: Icons.equalizer_rounded,
            text: t.loyaltyPointValueInfo,
          ),
          _HowItem(
            icon: Icons.auto_awesome_outlined,
            text: t.loyaltyEarningInfo,
          ),
          _HowItem(
            icon: Icons.calendar_month_outlined,
            text:
                '${t.loyaltyValidityInfo} '
                '${t.validForDays}: ${wallet.validityDays}.',
          ),
          _HowItem(
            icon: Icons.delivery_dining_outlined,
            text: wallet.spendOnDelivery
                ? t.loyaltyFeesDeliveryAllowed
                : t.loyaltyFeesDeliveryNotAllowed,
          ),
          _HowItem(
            icon: Icons.receipt_long_outlined,
            text: wallet.spendOnServiceFee
                ? t.loyaltyFeesServiceAllowed
                : t.loyaltyFeesServiceNotAllowed,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _HowItem extends StatelessWidget {
  const _HowItem({required this.icon, required this.text, this.isLast = false});

  final IconData icon;
  final String text;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: BaseColors.primary, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: TypographyText(
              text,
              style: const TextStyle(fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final LoyaltyTransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appearance = _transactionAppearance(transaction, L.of(context));
    final delta = transaction.displayDelta;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = transaction.createdAt == null
        ? ''
        : DateFormat.yMMMd(
            locale,
          ).add_Hm().format(transaction.createdAt!.toLocal());

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D1A18) : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: appearance.color.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(appearance.icon, color: appearance.color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TypographyText(
                  appearance.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  TypographyText(
                    date,
                    style: const TextStyle(
                      color: BaseColors.textGray,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          TypographyText(
            '${delta > 0 ? '+' : ''}${_formatPoints(context, delta)}',
            style: TextStyle(
              color: delta > 0
                  ? BaseColors.success
                  : delta < 0
                  ? BaseColors.danger
                  : BaseColors.textGray,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

({IconData icon, Color color, String label}) _transactionAppearance(
  LoyaltyTransactionModel transaction,
  L t,
) {
  return switch (transaction.type) {
    LoyaltyTransactionType.earn => (
      icon: Icons.add_circle_outline_rounded,
      color: BaseColors.success,
      label: t.transactionEarn,
    ),
    LoyaltyTransactionType.spendReserve ||
    LoyaltyTransactionType.spendCommit => (
      icon: Icons.shopping_bag_outlined,
      color: BaseColors.primaryDark,
      label: t.transactionSpend,
    ),
    LoyaltyTransactionType.spendRelease ||
    LoyaltyTransactionType.spendRefund => (
      icon: Icons.replay_circle_filled_outlined,
      color: const Color(0xFF1976D2),
      label: t.transactionRelease,
    ),
    LoyaltyTransactionType.expire => (
      icon: Icons.event_busy_outlined,
      color: BaseColors.danger,
      label: t.transactionExpiry,
    ),
    LoyaltyTransactionType.earnReversal => (
      icon: Icons.undo_rounded,
      color: BaseColors.danger,
      label: t.transactionReversal,
    ),
    LoyaltyTransactionType.debtRepayment => (
      icon: Icons.balance_rounded,
      color: const Color(0xFF7B61A8),
      label: t.transactionDebtRepayment,
    ),
    LoyaltyTransactionType.openingBalance => (
      icon: Icons.account_balance_wallet_outlined,
      color: BaseColors.primary,
      label: t.transactionOpeningBalance,
    ),
    LoyaltyTransactionType.accountClosure || LoyaltyTransactionType.unknown => (
      icon: Icons.swap_horiz_rounded,
      color: BaseColors.textGray,
      label: t.transactionBalanceUpdate,
    ),
  };
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Icon(
          Icons.receipt_long_outlined,
          size: 44,
          color: BaseColors.textGray.withValues(alpha: 0.55),
        ),
        const SizedBox(height: 10),
        TypographyText(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: BaseColors.textGray),
        ),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: BaseColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: BaseColors.primary, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: TypographyText(
              text,
              style: const TextStyle(fontSize: 13, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletSkeleton extends StatelessWidget {
  const _WalletSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: const <Widget>[
        _SkeletonBlock(height: 182),
        SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(child: _SkeletonBlock(height: 112)),
            SizedBox(width: 10),
            Expanded(child: _SkeletonBlock(height: 112)),
          ],
        ),
        SizedBox(height: 18),
        _SkeletonBlock(height: 210),
      ],
    );
  }
}

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: <Widget>[
          _SkeletonBlock(height: 68),
          SizedBox(height: 8),
          _SkeletonBlock(height: 68),
          SizedBox(height: 8),
          _SkeletonBlock(height: 68),
        ],
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF25211F) : const Color(0xFFF2EAE5),
        borderRadius: BorderRadius.circular(22),
      ),
    );
  }
}

String _formatPoints(BuildContext context, int value) {
  return NumberFormat.decimalPattern(
    Localizations.localeOf(context).toLanguageTag(),
  ).format(value);
}
