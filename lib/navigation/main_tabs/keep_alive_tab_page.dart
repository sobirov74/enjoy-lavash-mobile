part of 'package:enjoy_lavash_mobile/navigation/main_tabs.dart';

/// Keeps a tab's state while it is off screen and freezes its animations
/// there: tickers on an inactive tab would otherwise keep scheduling frames.
///
/// Only the [TickerMode] follows [active]; [child] is the same widget
/// instance, so switching tabs does not rebuild the tab's content.
class _KeepAliveTabPage extends StatefulWidget {
  const _KeepAliveTabPage({required this.active, required this.child});

  final ValueListenable<bool> active;
  final Widget child;

  @override
  State<_KeepAliveTabPage> createState() => _KeepAliveTabPageState();
}

class _KeepAliveTabPageState extends State<_KeepAliveTabPage>
    with AutomaticKeepAliveClientMixin<_KeepAliveTabPage> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ValueListenableBuilder<bool>(
      valueListenable: widget.active,
      builder: (context, active, child) =>
          TickerMode(enabled: active, child: child!),
      child: widget.child,
    );
  }
}

/// Whether the tab at [index] is the visible one, as a listenable over the
/// shell's current tab.
class _TabActive implements ValueListenable<bool> {
  _TabActive(this._currentTab, this._index);

  final ValueListenable<int> _currentTab;
  final int _index;

  @override
  bool get value => _currentTab.value == _index;

  @override
  void addListener(VoidCallback listener) => _currentTab.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _currentTab.removeListener(listener);
}
