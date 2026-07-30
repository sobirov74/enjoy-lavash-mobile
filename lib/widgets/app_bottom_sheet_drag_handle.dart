import 'package:flutter/material.dart';

import 'app_modal_bottom_sheet.dart';

/// A bottom-sheet handle with its own downward-swipe recognizer.
///
/// Flutter's route-level drag gesture can lose the gesture arena when a sheet
/// is built inside a [ScrollView]. Keeping the recognizer on the handle makes
/// dismissal reliable without interfering with scrolling the sheet content.
class AppBottomSheetDragHandle extends StatefulWidget {
  const AppBottomSheetDragHandle({
    super.key,
    this.color,
    this.enabled = true,
    this.margin = EdgeInsets.zero,
  });

  final Color? color;
  final bool enabled;
  final EdgeInsetsGeometry margin;

  @override
  State<AppBottomSheetDragHandle> createState() =>
      _AppBottomSheetDragHandleState();
}

class _AppBottomSheetDragHandleState extends State<AppBottomSheetDragHandle> {
  static const double _dismissDistance = 64;
  static const double _dismissVelocity = 700;

  double _downwardDistance = 0;
  bool _didDismiss = false;

  void _onDragStart(DragStartDetails details) {
    _downwardDistance = 0;
    _didDismiss = false;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _downwardDistance = (_downwardDistance + details.delta.dy).clamp(
      0,
      _dismissDistance,
    );
    if (_downwardDistance >= _dismissDistance) {
      _dismiss();
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (details.primaryVelocity != null &&
        details.primaryVelocity! >= _dismissVelocity) {
      _dismiss();
    }
    _downwardDistance = 0;
  }

  void _dismiss() {
    if (_didDismiss || !widget.enabled) return;
    _didDismiss = true;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetOwnsDrag = AppModalBottomSheetDragScope.maybeOf(context) != null;
    final handleColor =
        widget.color ??
        (isDark ? const Color(0xFF4A4038) : const Color(0xFFE5DAD0));

    return Semantics(
      container: true,
      child: GestureDetector(
        key: const ValueKey<String>('bottom-sheet-drag-handle'),
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: widget.enabled && !sheetOwnsDrag
            ? _onDragStart
            : null,
        onVerticalDragUpdate: widget.enabled && !sheetOwnsDrag
            ? _onDragUpdate
            : null,
        onVerticalDragEnd: widget.enabled && !sheetOwnsDrag ? _onDragEnd : null,
        child: Container(
          width: double.infinity,
          height: 28,
          margin: widget.margin,
          alignment: Alignment.center,
          child: Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: handleColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}
