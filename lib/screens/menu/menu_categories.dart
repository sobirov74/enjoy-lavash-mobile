part of 'package:enjoy_lavash_mobile/screens/menu_screen.dart';

/// Category selection: chip keys, the shared selection pill and keeping the
/// selected chip in view.
extension _MenuCategories on _MenuScreenState {
  void _syncCategoryKeys() {
    _syncKeyList(_categoryChipKeys, widget.categories.length + 1);
  }

  void _syncKeyList(List<GlobalKey> keys, int count) {
    if (keys.length == count) return;

    if (keys.length < count) {
      keys.addAll(_buildKeys(count - keys.length));
      return;
    }

    keys.removeRange(count, keys.length);
  }

  void _updateCategoryPillGeometry() {
    if (!mounted || _categoryChipKeys.isEmpty) return;

    final selectedIndex = (widget.selectedCategoryIndex + 1).clamp(
      0,
      widget.categories.length,
    );
    final chipRenderObject = _categoryChipKeys[selectedIndex].currentContext
        ?.findRenderObject();
    final trackRenderObject = _categoryPillTrackKey.currentContext
        ?.findRenderObject();
    if (chipRenderObject is! RenderBox ||
        trackRenderObject is! RenderBox ||
        !chipRenderObject.hasSize ||
        !trackRenderObject.hasSize) {
      return;
    }

    final chipOffset = chipRenderObject.localToGlobal(
      Offset.zero,
      ancestor: trackRenderObject,
    );
    final nextLeft = chipOffset.dx;
    final nextWidth = chipRenderObject.size.width;
    final current = _categoryPill.value;
    if (current != null &&
        (nextLeft - current.left).abs() < 0.5 &&
        (nextWidth - current.width).abs() < 0.5) {
      return;
    }

    _categoryPill.value = (left: nextLeft, width: nextWidth);
  }

  void _selectCategory(int index) {
    if (index < -1 || index >= widget.categories.length) return;
    _cartAnimation.cancel();
    widget.onCategorySelected(index);
    if (!_scrollController.hasClients) return;
    if (AppMotion.reduced(context)) {
      _scrollController.jumpTo(0);
    } else {
      unawaited(
        _scrollController.animateTo(
          0,
          duration: AppMotion.state,
          curve: AppMotion.enter,
        ),
      );
    }
  }

  void _scrollSelectedChipIntoView() {
    if (!_categoryScrollController.hasClients || _categoryChipKeys.isEmpty) {
      return;
    }

    final displayIndex = (widget.selectedCategoryIndex + 1).clamp(
      0,
      widget.categories.length,
    );
    final chipContext = _categoryChipKeys[displayIndex].currentContext;
    if (chipContext == null) return;

    final chipBox = chipContext.findRenderObject();
    final listBox = _categoryScrollController.position.context.storageContext
        .findRenderObject();

    if (chipBox is! RenderBox || listBox is! RenderBox) return;

    final chipOffset = chipBox.localToGlobal(Offset.zero, ancestor: listBox);
    final chipCenter = chipOffset.dx + chipBox.size.width / 2;
    final viewportCenter =
        _categoryScrollController.position.viewportDimension / 2;

    final targetOffset =
        (_categoryScrollController.offset + chipCenter - viewportCenter).clamp(
          0.0,
          _categoryScrollController.position.maxScrollExtent,
        );

    if ((targetOffset - _categoryScrollController.offset).abs() < 1) return;

    if (AppMotion.reduced(context)) {
      _categoryScrollController.jumpTo(targetOffset);
    } else {
      _categoryScrollController.animateTo(
        targetOffset,
        duration: AppMotion.state,
        curve: AppMotion.enter,
      );
    }
  }
}
