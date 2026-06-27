import 'dart:async';

import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/theme/theme_extensions.dart';
import 'package:enjoy_lavash_mobile/widgets/animated_error_message.dart';
import 'package:enjoy_lavash_mobile/widgets/app_snack_bar.dart';
import 'package:enjoy_lavash_mobile/widgets/button.dart';
import 'package:enjoy_lavash_mobile/widgets/confirm_dialog.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:enjoy_lavash_mobile/app/locale_controller.dart';
import 'package:enjoy_lavash_mobile/app/theme_controller.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/address_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/branch_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/cart_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/order_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:enjoy_lavash_mobile/screens/authorization_screen.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';

class Profile extends StatelessWidget {
  const Profile({super.key, this.onRefresh});

  static const int _loyaltyPoints = 1250;

  final Future<void> Function()? onRefresh;

  Future<void> _shareApp(L t) async {
    await SharePlus.instance.share(ShareParams(text: t.shareAppText));
  }

  void _confirmLogout(BuildContext context, L t) {
    showConfirmDialog(
      context: context,
      title: t.logoutTitle,
      confirmText: t.logout,
      cancelText: t.no,
      footerReversed: true,
      onCancel: () {},
      onConfirm: () => unawaited(_logout(context, t)),
      child: TypographyText(
        t.logoutMessage,
        style: const TextStyle(color: BaseColors.textGray, fontSize: 14),
      ),
    );
  }

  Future<void> _logout(BuildContext context, L t) async {
    final result = await context.read<MobileBackendController>().logout();
    if (!context.mounted || result.isSuccess) return;

    ScaffoldMessenger.of(context).showSnackBar(
      appSnackBar(result.failureOrNull?.message ?? t.logoutFailed),
    );
  }

  Future<void> _showAuthorizationModal(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.92,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: const AuthorizationScreen(),
          ),
        );
      },
    );
  }

  void _openAllOrders(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const _AllOrdersScreen()));
  }

  String _formatAddress(ClientAddress address) {
    final parts = <String>[address.street];
    if (address.houseNumber?.isNotEmpty == true) {
      parts.add(address.houseNumber!);
    }
    return parts.join(', ');
  }

  String _formatPoints(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeController = context.read<ThemeController>();
    final localeController = context.watch<LocaleController>();
    final mobileBackend = context.watch<MobileBackendController>();
    final t = L.of(context);
    final client = mobileBackend.client;
    final isAuthorized = client != null;
    final displayName = client?.fullName.isNotEmpty == true
        ? client!.fullName
        : (isAuthorized ? t.guest : t.authorization);
    final phoneNumber = client?.phoneNumber.isNotEmpty == true
        ? client!.phoneNumber
        : '';
    final profileSubtitle = phoneNumber.isNotEmpty
        ? phoneNumber
        : t.tapToSignIn;
    final loyaltyPoints = client?.bonusBalance ?? _loyaltyPoints;
    final recentOrders = mobileBackend.orders.take(5).toList(growable: false);
    final hasMoreOrders = mobileBackend.orders.length > recentOrders.length;
    final backendFailure = mobileBackend.failure;

    return RefreshIndicator(
      color: BaseColors.primary,
      onRefresh: onRefresh ?? () async {},
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TypographyText(
                    t.profile,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: isAuthorized
                        ? null
                        : () => unawaited(_showAuthorizationModal(context)),
                    child: _SurfaceCard(
                      isDark: isDark,
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 76,
                            height: 76,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: <Color>[
                                  Color(0xFFFFC107),
                                  BaseColors.primary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.circular(24),
                              ),
                            ),
                            child: const TypographyText(
                              '👤',
                              style: TextStyle(fontSize: 34),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                TypographyText(
                                  displayName,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TypographyText(
                                  profileSubtitle,
                                  style: const TextStyle(
                                    color: BaseColors.textGray,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, size: 28),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (backendFailure != null) ...[
                    AnimatedErrorMessage(
                      failure: backendFailure,
                      compact: true,
                      onRetry: onRefresh == null
                          ? null
                          : () => unawaited(onRefresh!()),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // -- Theme toggle
                  _SurfaceCard(
                    isDark: isDark,
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: MainButton(
                            title: TypographyText(
                              t.lightTheme,
                              style: TextStyle(color: context.colors.text),
                            ),
                            icon: Icon(
                              Icons.light_mode_rounded,
                              color: context.colors.text,
                            ),
                            onPressed: () =>
                                themeController.setTheme(ThemeMode.light),
                            elevation: 0,
                            backgroundColor: !isDark
                                ? BaseColors.primary
                                : BaseColors.black600,
                            foregroundColor: !isDark
                                ? Colors.white
                                : const Color(0xFF14110F),
                            borderRadius: BorderRadius.circular(20),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: MainButton(
                            title: TypographyText(
                              t.darkTheme,
                              style: TextStyle(color: context.colors.text),
                            ),
                            icon: Icon(
                              Icons.dark_mode_rounded,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF14110F),
                            ),
                            onPressed: () =>
                                themeController.setTheme(ThemeMode.dark),
                            elevation: 0,
                            backgroundColor: isDark
                                ? BaseColors.primary
                                : const Color(0xFFF3F0EB),
                            foregroundColor: isDark
                                ? Colors.white
                                : const Color(0xFF14110F),
                            borderRadius: BorderRadius.circular(20),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // -- Language selector
                  _SurfaceCard(
                    isDark: isDark,
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: <Widget>[
                        for (final entry in [
                          (locale: const Locale('uz'), label: "O'zbekcha"),
                          (locale: const Locale('ru'), label: 'Русский'),
                          (locale: const Locale('en'), label: 'English'),
                        ]) ...[
                          if (entry.locale != const Locale('uz'))
                            const SizedBox(width: 8),
                          Expanded(
                            child: _LangChip(
                              label: entry.label,
                              isActive: localeController.locale == entry.locale,
                              isDark: isDark,
                              onTap: () =>
                                  localeController.setLocale(entry.locale),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // -- Loyalty card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: <Color>[BaseColors.primary, Color(0xFFFF7043)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        TypographyText(
                          t.loyaltyCard,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TypographyText(
                          t.accumulatedPoints,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 18),
                        TypographyText(
                          _formatPoints(loyaltyPoints),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Column(
                            children: <Widget>[
                              Icon(
                                Icons.qr_code_2_rounded,
                                size: 180,
                                color: Colors.grey.shade900,
                              ),
                              const SizedBox(height: 8),
                              TypographyText(
                                'ENJOY-LAVASH-$loyaltyPoints',
                                style: const TextStyle(
                                  letterSpacing: 2.4,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        TypographyText(
                          t.showCodeForPoints,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // -- Personal info
                  if (isAuthorized)
                    _SectionCard(
                      isDark: isDark,
                      title: t.personalInfo,
                      child: Column(
                        children: <Widget>[
                          _InfoRow(
                            icon: Icons.phone_outlined,
                            title: t.phoneNumber,
                            value: client.phoneNumber,
                          ),
                          if (mobileBackend.addresses.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            _InfoRow(
                              icon: Icons.location_on_outlined,
                              title: t.address,
                              value: _formatAddress(
                                mobileBackend.addresses.first,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  if (isAuthorized) const SizedBox(height: 16),

                  // -- Order history
                  if (mobileBackend.orders.isNotEmpty) ...[
                    _SectionCard(
                      isDark: isDark,
                      title: t.orderHistory,
                      padding: const EdgeInsets.all(14),
                      titleBottomSpacing: 12,
                      child: Column(
                        children: <Widget>[
                          for (int i = 0; i < recentOrders.length; i++) ...[
                            if (i > 0) const SizedBox(height: 8),
                            _OrderRow(
                              order: recentOrders[i],
                              locale: localeController.locale.languageCode,
                              branches: mobileBackend.branches,
                              addresses: mobileBackend.addresses,
                            ),
                          ],
                          if (hasMoreOrders) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: BaseColors.primary,
                                  side: const BorderSide(
                                    color: BaseColors.primary,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () => _openAllOrders(context),
                                icon: const Icon(Icons.receipt_long_rounded),
                                label: TypographyText(
                                  _orderText(
                                    t,
                                    en: 'See all orders',
                                    ru: 'Все заказы',
                                    uz: "Barcha buyurtmalar",
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // -- Cashback system
                  _SectionCard(
                    isDark: isDark,
                    title: t.cashbackSystem,
                    child: Column(
                      children: <Widget>[
                        _StatLine(label: t.perOrder, value: t.perOrderValue),
                        const SizedBox(height: 10),
                        _StatLine(
                          label: t.onePointEquals,
                          value: t.onePointValue,
                        ),
                        const SizedBox(height: 10),
                        _StatLine(label: t.canSpend, value: t.canSpendValue),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // -- Share button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: BaseColors.primary,
                        side: const BorderSide(color: BaseColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () => _shareApp(t),
                      icon: const Icon(Icons.share_outlined),
                      label: TypographyText(t.shareApp),
                    ),
                  ),
                  if (client != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: BaseColors.danger,
                          side: const BorderSide(color: BaseColors.danger),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () => _confirmLogout(context, t),
                        icon: const Icon(Icons.logout_rounded),
                        label: TypographyText(t.logout),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllOrdersScreen extends StatefulWidget {
  const _AllOrdersScreen();

  @override
  State<_AllOrdersScreen> createState() => _AllOrdersScreenState();
}

class _AllOrdersScreenState extends State<_AllOrdersScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _query = '';
  MobileOrderType? _typeFilter;
  MobileOrderStatus? _statusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CustomerOrderModel> _filteredOrders({
    required List<CustomerOrderModel> orders,
    required List<BranchModel> branches,
    required List<ClientAddress> addresses,
    required L t,
  }) {
    final query = _query.trim().toLowerCase();

    return orders
        .where((order) {
          if (_typeFilter != null && order.type != _typeFilter) return false;
          if (_statusFilter != null && order.status != _statusFilter) {
            return false;
          }
          if (query.isEmpty) return true;

          final destination =
              _orderDestination(order, branches, addresses, t) ?? '';
          final products = order.items
              .map((item) => _orderProductTitle(item, t))
              .join(' ');
          final haystack = <String>[
            order.id,
            _shortOrderId(order.id),
            _statusLabel(order.status, t),
            _orderTypeLabel(order.type, t),
            _formatOrderAmount(order.totalAmount),
            destination,
            products,
          ].join(' ').toLowerCase();

          return haystack.contains(query);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = L.of(context);
    final locale = context.watch<LocaleController>().locale.languageCode;
    final backend = context.watch<MobileBackendController>();
    final orders = backend.orders;
    final statuses = ({for (final order in orders) order.status}.toList()
      ..sort((a, b) => a.index.compareTo(b.index)));
    final filteredOrders = _filteredOrders(
      orders: orders,
      branches: backend.branches,
      addresses: backend.addresses,
      t: t,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 16, 8),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: TypographyText(
                      _orderText(
                        t,
                        en: 'All orders',
                        ru: 'Все заказы',
                        uz: 'Barcha buyurtmalar',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: BaseColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: TypographyText(
                      '${filteredOrders.length}/${orders.length}',
                      style: const TextStyle(
                        color: BaseColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: _OrdersSearchField(
                controller: _searchController,
                isDark: isDark,
                hintText: _orderText(
                  t,
                  en: 'Search by product, status, or order ID',
                  ru: 'Поиск по товару, статусу или номеру',
                  uz: 'Mahsulot, holat yoki buyurtma raqami',
                ),
                onChanged: (value) => setState(() => _query = value),
                onClear: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                children: <Widget>[
                  _OrderFilterChip(
                    label: _orderText(t, en: 'All', ru: 'Все', uz: 'Barchasi'),
                    selected: _typeFilter == null,
                    onTap: () => setState(() => _typeFilter = null),
                  ),
                  const SizedBox(width: 8),
                  _OrderFilterChip(
                    label: t.delivery,
                    selected: _typeFilter == MobileOrderType.delivery,
                    onTap: () =>
                        setState(() => _typeFilter = MobileOrderType.delivery),
                  ),
                  const SizedBox(width: 8),
                  _OrderFilterChip(
                    label: t.pickup,
                    selected: _typeFilter == MobileOrderType.pickup,
                    onTap: () =>
                        setState(() => _typeFilter = MobileOrderType.pickup),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                itemCount: statuses.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _OrderFilterChip(
                      label: _orderText(
                        t,
                        en: 'Any status',
                        ru: 'Любой статус',
                        uz: 'Har qanday holat',
                      ),
                      selected: _statusFilter == null,
                      onTap: () => setState(() => _statusFilter = null),
                    );
                  }

                  final status = statuses[index - 1];
                  return _OrderFilterChip(
                    label: _statusLabel(status, t),
                    selected: _statusFilter == status,
                    onTap: () => setState(() => _statusFilter = status),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: backend.failure != null && orders.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                      child: Center(
                        child: AnimatedErrorMessage(
                          failure: backend.failure,
                          onRetry: () => unawaited(
                            context
                                .read<MobileBackendController>()
                                .refreshCustomerData(),
                          ),
                        ),
                      ),
                    )
                  : filteredOrders.isEmpty
                  ? _OrdersEmptyState(isDark: isDark)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      physics: const BouncingScrollPhysics(),
                      itemCount: filteredOrders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        return _OrderRow(
                          order: filteredOrders[index],
                          locale: locale,
                          branches: backend.branches,
                          addresses: backend.addresses,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersSearchField extends StatelessWidget {
  const _OrdersSearchField({
    required this.controller,
    required this.isDark,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool isDark;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final hasQuery = value.text.trim().isNotEmpty;

        return Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1D1A18) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.05),
                blurRadius: 22,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.search_rounded,
                color: BaseColors.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  textInputAction: TextInputAction.search,
                  cursorColor: BaseColors.primary,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: hintText,
                    hintStyle: TextStyle(
                      color: isDark
                          ? const Color(0xFF9E9790)
                          : BaseColors.textGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onChanged: onChanged,
                ),
              ),
              if (hasQuery)
                IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                )
              else
                const SizedBox(width: 40),
            ],
          ),
        );
      },
    );
  }
}

class _OrderFilterChip extends StatelessWidget {
  const _OrderFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      label: TypographyText(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: selected || isDark ? Colors.white : const Color(0xFF14110F),
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
      backgroundColor: isDark
          ? const Color(0xFF201C19)
          : const Color(0xFFF1EDE7),
      selectedColor: BaseColors.primary,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );
  }
}

class _OrdersEmptyState extends StatelessWidget {
  const _OrdersEmptyState({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.receipt_long_outlined,
              size: 46,
              color: isDark ? BaseColors.lightTextGray : BaseColors.textGray,
            ),
            const SizedBox(height: 14),
            TypographyText(
              _orderText(
                t,
                en: 'No orders match your filters',
                ru: 'Нет заказов по выбранным фильтрам',
                uz: "Filtrlarga mos buyurtma yo'q",
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? BaseColors.lightTextGray : BaseColors.textGray,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Language chip button
// ---------------------------------------------------------------------------

class _LangChip extends StatelessWidget {
  const _LangChip({
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isActive
              ? BaseColors.primary
              : (isDark ? BaseColors.black600 : const Color(0xFFF3F0EB)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: TypographyText(
          label,
          style: TextStyle(
            color: isActive
                ? Colors.white
                : (isDark ? Colors.white : const Color(0xFF14110F)),
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable private widgets
// ---------------------------------------------------------------------------

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    required this.isDark,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final bool isDark;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D1A18) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.isDark,
    required this.title,
    required this.child,
    this.padding,
    this.titleBottomSpacing = 16,
  });

  final bool isDark;
  final String title;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double titleBottomSpacing;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      isDark: isDark,
      padding: padding ?? const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TypographyText(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: titleBottomSpacing),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: BaseColors.surfaceTint,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: BaseColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TypographyText(
                title,
                style: const TextStyle(
                  color: BaseColors.textGray,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              TypographyText(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _orderText(
  L t, {
  required String en,
  required String ru,
  required String uz,
}) {
  return switch (t.localeName.split('_').first) {
    'ru' => ru,
    'uz' => uz,
    _ => en,
  };
}

String _formatOrderAmount(int amount) {
  final text = amount.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(text[i]);
  }
  buffer.write(" so'm");
  return buffer.toString();
}

String _formatOrderDate(DateTime? date, String locale) {
  if (date == null) return '';
  return DateFormat.yMMMMd(locale).format(date.toLocal());
}

String _formatOrderDateTime(DateTime? date, String locale) {
  if (date == null) return '';
  return DateFormat.yMMMd(locale).add_Hm().format(date.toLocal());
}

String _shortOrderId(String id) {
  final value = id.trim();
  if (value.length <= 8) return value;
  return value.substring(value.length - 8).toUpperCase();
}

String _statusLabel(MobileOrderStatus status, L t) {
  return switch (status) {
    MobileOrderStatus.newOrder => t.statusNew,
    MobileOrderStatus.confirmed => t.statusAccepted,
    MobileOrderStatus.cooking => _orderText(
      t,
      en: 'Cooking',
      ru: 'Готовится',
      uz: 'Tayyorlanmoqda',
    ),
    MobileOrderStatus.ready => _orderText(
      t,
      en: 'Ready',
      ru: 'Готов',
      uz: 'Tayyor',
    ),
    MobileOrderStatus.courierAssigned => _orderText(
      t,
      en: 'Courier assigned',
      ru: 'Курьер назначен',
      uz: 'Kuryer biriktirildi',
    ),
    MobileOrderStatus.onTheWay => _orderText(
      t,
      en: 'On the way',
      ru: 'В пути',
      uz: "Yo'lda",
    ),
    MobileOrderStatus.delivered => t.statusCompleted,
    MobileOrderStatus.cancelled => t.statusCancelled,
    MobileOrderStatus.refunded => t.statusFailed,
    MobileOrderStatus.unknown => _orderText(
      t,
      en: 'Unknown',
      ru: 'Неизвестно',
      uz: "Noma'lum",
    ),
  };
}

({Color bg, Color text}) _statusColors(MobileOrderStatus status) {
  return switch (status) {
    MobileOrderStatus.delivered || MobileOrderStatus.ready => (
      bg: const Color(0xFFE7F6EA),
      text: BaseColors.success,
    ),
    MobileOrderStatus.cancelled || MobileOrderStatus.refunded => (
      bg: const Color(0xFFFDE8E8),
      text: BaseColors.danger,
    ),
    MobileOrderStatus.unknown => (
      bg: const Color(0xFFEDEAE6),
      text: BaseColors.textGray,
    ),
    _ => (bg: const Color(0xFFFFF3E0), text: const Color(0xFFE65100)),
  };
}

({Color bg, Color border, Color accent}) _statusSurfaceColors(
  MobileOrderStatus status,
  bool isDark,
) {
  final accent = switch (status) {
    MobileOrderStatus.newOrder => const Color(0xFF3B82F6),
    MobileOrderStatus.confirmed => const Color(0xFF22C55E),
    MobileOrderStatus.cooking => const Color(0xFFF59E0B),
    MobileOrderStatus.ready => const Color(0xFF10B981),
    MobileOrderStatus.courierAssigned => const Color(0xFF38BDF8),
    MobileOrderStatus.onTheWay => const Color(0xFF6366F1),
    MobileOrderStatus.delivered => const Color(0xFF16A34A),
    MobileOrderStatus.cancelled => BaseColors.danger,
    MobileOrderStatus.refunded => const Color(0xFFEC4899),
    MobileOrderStatus.unknown => BaseColors.textGray,
  };
  final base = isDark ? const Color(0xFF2A2522) : Colors.white;

  return (
    bg: Color.alphaBlend(accent.withValues(alpha: isDark ? 0.18 : 0.09), base),
    border: accent.withValues(alpha: isDark ? 0.36 : 0.22),
    accent: accent,
  );
}

String _orderTypeLabel(MobileOrderType type, L t) {
  return switch (type) {
    MobileOrderType.delivery => t.delivery,
    MobileOrderType.pickup => t.pickup,
  };
}

IconData _orderTypeIcon(MobileOrderType type) {
  return switch (type) {
    MobileOrderType.delivery => Icons.delivery_dining_rounded,
    MobileOrderType.pickup => Icons.store_mall_directory_rounded,
  };
}

String _paymentMethodLabel(MobilePaymentMethod method, L t) {
  return switch (method) {
    MobilePaymentMethod.cash => _orderText(
      t,
      en: 'Cash',
      ru: 'Наличные',
      uz: 'Naqd',
    ),
    MobilePaymentMethod.cardTerminal => _orderText(
      t,
      en: 'Card terminal',
      ru: 'Терминал',
      uz: 'Terminal',
    ),
    MobilePaymentMethod.payme => 'Payme',
    MobilePaymentMethod.click => 'Click',
    MobilePaymentMethod.unknown => _orderText(
      t,
      en: 'Unknown',
      ru: 'Неизвестно',
      uz: "Noma'lum",
    ),
  };
}

String _orderProductTitle(CustomerOrderItemModel item, L t) {
  final language = t.localeName.split('_').first;
  final name = item.localizedName(language);
  if (name != null && name.isNotEmpty) return name;

  final productId = item.productId.trim();
  final fallback = _orderText(t, en: 'Product', ru: 'Товар', uz: 'Mahsulot');
  if (productId.isEmpty) return fallback;
  return '$fallback $productId';
}

String _orderProductSummary(CustomerOrderModel order, L t) {
  if (order.items.isEmpty) {
    return _orderText(
      t,
      en: 'No products in this order',
      ru: 'В заказе нет товаров',
      uz: "Buyurtmada mahsulot yo'q",
    );
  }

  final items = order.items
      .map((item) => '${_orderProductTitle(item, t)} x${item.quantity}')
      .toList(growable: false);
  final visibleItems = items.take(2).toList(growable: false);
  final extraCount = items.length - visibleItems.length;
  if (extraCount <= 0) return visibleItems.join(', ');
  return '${visibleItems.join(', ')} +$extraCount';
}

BranchModel? _findBranch(List<BranchModel> branches, String? id) {
  final branchId = id?.trim();
  if (branchId == null || branchId.isEmpty) return null;
  for (final branch in branches) {
    if (branch.id == branchId) return branch;
  }
  return null;
}

ClientAddress? _findAddress(List<ClientAddress> addresses, String? id) {
  final addressId = id?.trim();
  if (addressId == null || addressId.isEmpty) return null;
  for (final address in addresses) {
    if (address.id == addressId) return address;
  }
  return null;
}

String _formatOrderAddress(ClientAddress address, L t) {
  final primaryParts = <String>[
    if (address.street.trim().isNotEmpty) address.street.trim(),
    if (address.houseNumber?.trim().isNotEmpty == true)
      address.houseNumber!.trim(),
  ];
  final detailParts = <String>[
    if (address.apartmentNumber?.trim().isNotEmpty == true)
      '${t.apartmentLabel} ${address.apartmentNumber!.trim()}',
    if (address.entrance?.trim().isNotEmpty == true)
      '${t.entranceLabel} ${address.entrance!.trim()}',
    if (address.floor?.trim().isNotEmpty == true)
      '${t.floorLabel} ${address.floor!.trim()}',
  ];

  final primary = primaryParts.isEmpty
      ? address.label.trim()
      : primaryParts.join(', ');
  if (detailParts.isEmpty) return primary;
  return '$primary\n${detailParts.join(', ')}';
}

String? _orderDestination(
  CustomerOrderModel order,
  List<BranchModel> branches,
  List<ClientAddress> addresses,
  L t,
) {
  if (order.type == MobileOrderType.pickup) {
    final branch = _findBranch(branches, order.branchId);
    if (branch == null) return order.branchId;

    final address = branch.address?.trim();
    if (address == null || address.isEmpty) return branch.name;
    return '${branch.name}\n$address';
  }

  final address = _findAddress(addresses, order.addressId);
  if (address == null) return order.addressId;
  return _formatOrderAddress(address, t);
}

List<OrderStatusLogModel> _statusEntries(CustomerOrderModel order) {
  if (order.statusLog.isNotEmpty) return order.statusLog;
  return <OrderStatusLogModel>[
    OrderStatusLogModel(
      status: order.status,
      changedAt: order.updatedAt ?? order.createdAt,
    ),
  ];
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({
    required this.order,
    required this.locale,
    required this.branches,
    required this.addresses,
  });

  final CustomerOrderModel order;
  final String locale;
  final List<BranchModel> branches;
  final List<ClientAddress> addresses;

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _OrderDetailsSheet(
          order: order,
          locale: locale,
          branches: branches,
          addresses: addresses,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final colors = _statusColors(order.status);
    final date = _formatOrderDate(order.createdAt, locale);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = _statusSurfaceColors(order.status, isDark);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: surface.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: surface.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: surface.accent.withValues(alpha: isDark ? 0.12 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showDetails(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: surface.accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: surface.accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          TypographyText(
                            '#${_shortOrderId(order.id)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (date.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: <Widget>[
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 13,
                                  color: BaseColors.textGray,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: TypographyText(
                                    date,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: BaseColors.textGray,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _OrderStatusChip(
                      label: _statusLabel(order.status, t),
                      colors: colors,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(
                      Icons.fastfood_outlined,
                      size: 17,
                      color: BaseColors.textGray,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: TypographyText(
                        _orderProductSummary(order, t),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0x1A8C8278)),
                const SizedBox(height: 9),
                Row(
                  children: <Widget>[
                    Flexible(
                      child: _OrderMiniBadge(
                        icon: _orderTypeIcon(order.type),
                        label: _orderTypeLabel(order.type, t),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TypographyText(
                      _formatOrderAmount(order.totalAmount),
                      style: const TextStyle(
                        color: BaseColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: BaseColors.textGray,
                      size: 22,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderStatusChip extends StatelessWidget {
  const _OrderStatusChip({required this.label, required this.colors});

  final String label;
  final ({Color bg, Color text}) colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 136),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: TypographyText(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: colors.text,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _OrderMiniBadge extends StatelessWidget {
  const _OrderMiniBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: BaseColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: BaseColors.primary, size: 16),
          const SizedBox(width: 5),
          Flexible(
            child: TypographyText(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: BaseColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderDetailsSheet extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final t = L.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _statusColors(order.status);
    final destination = _orderDestination(order, branches, addresses, t);
    final statusEntries = _statusEntries(order);
    final createdAt = _formatOrderDateTime(order.createdAt, locale);
    final scheduledFor = _formatOrderDateTime(order.scheduledFor, locale);
    final updatedAt = _formatOrderDateTime(order.updatedAt, locale);

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
                        _orderText(
                          t,
                          en: 'Order details',
                          ru: 'Детали заказа',
                          uz: 'Buyurtma tafsilotlari',
                        ),
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
                          _orderText(
                            t,
                            en: 'Current status',
                            ru: 'Текущий статус',
                            uz: 'Joriy holat',
                          ),
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
              label: _orderText(
                t,
                en: 'Order type',
                ru: 'Тип заказа',
                uz: 'Buyurtma turi',
              ),
              value: _orderTypeLabel(order.type, t),
            ),
            if (createdAt.isNotEmpty) ...[
              const SizedBox(height: 8),
              _OrderInfoPill(
                icon: Icons.event_available_rounded,
                label: _orderText(
                  t,
                  en: 'Created',
                  ru: 'Создан',
                  uz: 'Yaratilgan',
                ),
                value: createdAt,
              ),
            ],
            if (scheduledFor.isNotEmpty) ...[
              const SizedBox(height: 8),
              _OrderInfoPill(
                icon: Icons.schedule_rounded,
                label: _orderText(
                  t,
                  en: 'Scheduled for',
                  ru: 'Запланирован',
                  uz: 'Rejalashtirilgan',
                ),
                value: scheduledFor,
              ),
            ],
            if (updatedAt.isNotEmpty) ...[
              const SizedBox(height: 8),
              _OrderInfoPill(
                icon: Icons.update_rounded,
                label: _orderText(
                  t,
                  en: 'Last update',
                  ru: 'Последнее обновление',
                  uz: 'Oxirgi yangilanish',
                ),
                value: updatedAt,
              ),
            ],
            const SizedBox(height: 8),
            _OrderInfoPill(
              icon: Icons.payments_outlined,
              label: _orderText(t, en: 'Payment', ru: 'Оплата', uz: "To'lov"),
              value: _paymentMethodLabel(order.paymentMethod, t),
            ),
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
              title: _orderText(
                t,
                en: 'Products',
                ru: 'Товары',
                uz: 'Mahsulotlar',
              ),
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
              title: _orderText(
                t,
                en: 'Status history',
                ru: 'История статусов',
                uz: 'Holatlar tarixi',
              ),
              children: <Widget>[
                for (int i = 0; i < statusEntries.length; i++) ...[
                  _OrderStatusLogLine(entry: statusEntries[i], locale: locale),
                  if (i < statusEntries.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
            if (order.promoCode?.trim().isNotEmpty == true ||
                order.comment?.trim().isNotEmpty == true ||
                order.iikoOrderId?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 12),
              _OrderDetailSection(
                title: _orderText(
                  t,
                  en: 'Additional info',
                  ru: 'Дополнительно',
                  uz: "Qo'shimcha ma'lumot",
                ),
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
                      label: _orderText(
                        t,
                        en: 'Kitchen order',
                        ru: 'Заказ кухни',
                        uz: 'Oshxona buyurtmasi',
                      ),
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

class _OrderInfoPill extends StatelessWidget {
  const _OrderInfoPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2522) : const Color(0xFFF8F4EF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: BaseColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TypographyText(
                  label,
                  style: const TextStyle(
                    color: BaseColors.textGray,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                TypographyText(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
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

class _OrderDetailSection extends StatelessWidget {
  const _OrderDetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
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
          TypographyText(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _OrderProductDetailLine extends StatelessWidget {
  const _OrderProductDetailLine({required this.item});

  final CustomerOrderItemModel item;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final amount = item.amount > 0 ? _formatOrderAmount(item.amount) : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          constraints: const BoxConstraints(minWidth: 34),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: BaseColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: TypographyText(
            '${item.quantity}x',
            style: const TextStyle(
              color: BaseColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TypographyText(
                _orderProductTitle(item, t),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              if (item.comment?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 4),
                TypographyText(
                  item.comment!.trim(),
                  style: const TextStyle(
                    color: BaseColors.textGray,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (amount != null) ...[
          const SizedBox(width: 8),
          TypographyText(
            amount,
            style: const TextStyle(
              color: BaseColors.textGray,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }
}

class _OrderStatusLogLine extends StatelessWidget {
  const _OrderStatusLogLine({required this.entry, required this.locale});

  final OrderStatusLogModel entry;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final colors = _statusColors(entry.status);
    final changedAt = _formatOrderDateTime(entry.changedAt, locale);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: colors.bg, shape: BoxShape.circle),
          child: Icon(Icons.check_rounded, color: colors.text, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TypographyText(
                _statusLabel(entry.status, t),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (changedAt.isNotEmpty) ...[
                const SizedBox(height: 2),
                TypographyText(
                  changedAt,
                  style: const TextStyle(
                    color: BaseColors.textGray,
                    fontSize: 12,
                  ),
                ),
              ],
              if (entry.comment?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 4),
                TypographyText(
                  entry.comment!.trim(),
                  style: const TextStyle(
                    color: BaseColors.textGray,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _OrderTextDetail extends StatelessWidget {
  const _OrderTextDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TypographyText(
          label,
          style: const TextStyle(
            color: BaseColors.textGray,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        TypographyText(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: TypographyText(
            label,
            style: const TextStyle(color: BaseColors.textGray),
          ),
        ),
        TypographyText(
          value,
          style: const TextStyle(
            color: BaseColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
