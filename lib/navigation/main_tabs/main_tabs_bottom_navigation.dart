part of 'package:enjoy_lavash_mobile/navigation/main_tabs.dart';

class _MainTabsBottomNavigation extends StatelessWidget {
  const _MainTabsBottomNavigation({
    required this.isDark,
    required this.cartIconKey,
    required this.cartArrival,
    required this.currentIndex,
    required this.totalItems,
    required this.totalAmount,
    required this.showCartPill,
    required this.t,
    required this.onCartTap,
    required this.onDestinationSelected,
  });

  final bool isDark;
  final GlobalKey cartIconKey;
  final int cartArrival;
  final int currentIndex;
  final int totalItems;
  final int totalAmount;
  final bool showCartPill;
  final L t;
  final VoidCallback onCartTap;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    // Colors and dimensions from enjoy-lavash-handoff.html, in both themes.
    final background = isDark
        ? const Color(0xFF0E0C09)
        : const Color(0xFFF6F4F0);
    final accent = isDark ? const Color(0xFFE8B558) : const Color(0xFF8A5F12);
    final muted = isDark ? const Color(0xFFA29A8C) : const Color(0xFF6B6558);
    final border = isDark
        ? const Color(0xFFF7F3EC).withValues(alpha: 0.09)
        : const Color(0xFF17150F).withValues(alpha: 0.10);
    final labels = <String>[
      t.tabHome,
      t.tabMenu,
      t.filterPromotions,
      t.tabCart,
      t.tabProfile,
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AnimatedSize(
          duration: AppMotion.duration(context, AppMotion.state),
          curve: AppMotion.enter,
          child: showCartPill
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: CartPill(
                    itemCount: totalItems,
                    totalLabel: formatSum(context, totalAmount),
                    label: t.cartOpen,
                    onTap: onCartTap,
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Material(
          key: const ValueKey<String>('main-bottom-navigation'),
          color: background,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: border)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 7, 4, 10),
                child: Row(
                  children: <Widget>[
                    for (var index = 0; index < labels.length; index++)
                      Expanded(
                        child: _MainTabDestination(
                          key: ValueKey<String>('main-tab-$index'),
                          index: index,
                          cartIconKey: index == 3 ? cartIconKey : null,
                          cartArrival: cartArrival,
                          cartCount: totalItems,
                          label: labels[index],
                          selected: currentIndex == index,
                          color: currentIndex == index ? accent : muted,
                          onTap: () => onDestinationSelected(index),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MainTabDestination extends StatefulWidget {
  const _MainTabDestination({
    required this.index,
    this.cartIconKey,
    this.cartArrival = 0,
    this.cartCount = 0,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
    super.key,
  });

  final int index;
  final GlobalKey? cartIconKey;
  final int cartArrival;
  final int cartCount;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_MainTabDestination> createState() => _MainTabDestinationState();
}

class _MainTabDestinationState extends State<_MainTabDestination> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.duration(
      context,
      const Duration(milliseconds: 160),
    );
    return Semantics(
      container: true,
      button: true,
      selected: widget.selected,
      label: widget.index == 3
          ? '${widget.label}, ${L.of(context).cartItemsCount(widget.cartCount)}'
          : widget.label,
      onTap: widget.onTap,
      excludeSemantics: true,
      child: Tooltip(
        message: widget.label,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (pressed) => setState(() => _pressed = pressed),
          borderRadius: BorderRadius.circular(14),
          splashColor: widget.color.withValues(alpha: 0.08),
          highlightColor: widget.color.withValues(alpha: 0.04),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: AnimatedScale(
              scale: _pressed && !AppMotion.reduced(context) ? 0.92 : 1,
              duration: duration,
              curve: AppMotion.enter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (widget.index == 3)
                      CartArrivalFeedback(
                        revision: widget.cartArrival,
                        child: Badge(
                          isLabelVisible: widget.cartCount > 0,
                          label: Text('${widget.cartCount}'),
                          child: SizedBox(
                            key: widget.cartIconKey,
                            width: 20,
                            height: 20,
                            child: _MainTabIcon(
                              index: widget.index,
                              selected: widget.selected,
                              color: widget.color,
                            ),
                          ),
                        ),
                      )
                    else
                      _MainTabIcon(
                        index: widget.index,
                        selected: widget.selected,
                        color: widget.color,
                      ),
                    const SizedBox(height: 5),
                    AnimatedDefaultTextStyle(
                      duration: duration,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 9.5,
                        height: 1,
                        fontWeight: widget.selected
                            ? FontWeight.w800
                            : FontWeight.w700,
                        color: widget.color,
                      ),
                      child: Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 5),
                    AnimatedContainer(
                      duration: duration,
                      width: 14,
                      height: 2,
                      decoration: BoxDecoration(
                        color: widget.selected
                            ? widget.color
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small monoline navigation glyphs on the handoff's 24-unit icon grid.
class _MainTabIcon extends StatelessWidget {
  const _MainTabIcon({
    required this.index,
    required this.selected,
    required this.color,
  });

  final int index;
  final bool selected;
  final Color color;

  static const _outlines = <String>[
    '<path d="M3 10 12 3l9 7M5 9v10a2 2 0 0 0 2 2h3v-7h4v7h3a2 2 0 0 0 2-2V9"/>',
    '<path d="M4 3v4a3 3 0 0 0 6 0V3M7 3v18M20 3c-3 0-5 3-5 7v3h5M20 3v18"/>',
    '<path d="M4 4h7l9 9a2 2 0 0 1 0 3l-4 4a2 2 0 0 1-3 0l-9-9V4Z"/>'
        '<circle cx="8" cy="8" r="1" fill="black" stroke="none"/>',
    '<path d="M6 7h12l2 13H4L6 7ZM9 7V6a3 3 0 0 1 6 0v1"/>',
    '<circle cx="12" cy="7" r="4"/>'
        '<path d="M5 21v-2a4 4 0 0 1 4-4h6a4 4 0 0 1 4 4v2"/>',
  ];

  static const _filled = <int, String>{
    0: '<path d="m3 10 9-7 9 7h-2v9a2 2 0 0 1-2 2h-3v-7h-4v7H7a2 2 0 0 1-2-2v-9Z"/>',
    2: '<path fill-rule="evenodd" d="M4 3a1 1 0 0 0-1 1v7l10 10a2 2 0 0 0 3 0l5-5a2 2 0 0 0 0-3L11 3H4Zm5 5a1 1 0 1 1-2 0 1 1 0 0 1 2 0Z"/>',
    3: '<path fill-rule="evenodd" d="M8 6a4 4 0 0 1 8 0v1h2l2 14H4L6 7h2V6Zm2 1h4V6a2 2 0 0 0-4 0v1Z"/>',
    4:
        '<circle cx="12" cy="7" r="4"/>'
        '<path d="M9 14h6a5 5 0 0 1 5 5v2H4v-2a5 5 0 0 1 5-5Z"/>',
  };

  @override
  Widget build(BuildContext context) {
    final filled = selected ? _filled[index] : null;
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
      'fill="${filled == null ? 'none' : 'black'}" '
      'stroke="${filled == null ? 'black' : 'none'}" '
      'stroke-width="2" stroke-linecap="round" stroke-linejoin="round">'
      '${filled ?? _outlines[index]}</svg>',
      width: 20,
      height: 20,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      excludeFromSemantics: true,
    );
  }
}
