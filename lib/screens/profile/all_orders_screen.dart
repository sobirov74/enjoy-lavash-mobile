part of 'package:enjoy_lavash_mobile/screens/profile.dart';

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
  bool _isRefreshing = false;

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

  Future<void> _refreshOrders() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    try {
      await context.read<MobileBackendController>().refreshCustomerData();
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Widget _scrollableFill({
    required Widget child,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: <Widget>[
        SliverPadding(
          padding: padding,
          sliver: SliverFillRemaining(hasScrollBody: false, child: child),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = L.of(context);
    final locale = context.watch<LocaleController>().locale.languageCode;
    final backend = context.watch<MobileBackendController>();
    final orders = backend.orders;
    final failure = backend.failure;
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
                      t.allOrders,
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
                  IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).refreshIndicatorSemanticLabel,
                    onPressed: _isRefreshing
                        ? null
                        : () => unawaited(_refreshOrders()),
                    icon: _isRefreshing
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: BaseColors.primary,
                            ),
                          )
                        : const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: _OrdersSearchField(
                controller: _searchController,
                isDark: isDark,
                hintText: t.ordersSearchHint,
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
                    label: t.all,
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
                      label: t.anyStatus,
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
              child: RefreshIndicator(
                color: BaseColors.primary,
                onRefresh: _refreshOrders,
                child:
                    failure != null && failure is! AuthFailure && orders.isEmpty
                    ? _scrollableFill(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                        child: Center(
                          child: AnimatedErrorMessage(
                            failure: failure,
                            onRetry: () => unawaited(_refreshOrders()),
                          ),
                        ),
                      )
                    : filteredOrders.isEmpty
                    ? _scrollableFill(child: _OrdersEmptyState(isDark: isDark))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
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
              t.noOrdersMatchFilters,
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
