import 'dart:math' as math;

import 'package:enjoy_lavash_mobile/theme/app_motion.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Shows a modal sheet with a consistent, velocity-aware drag interaction.
///
/// A downward gesture can start anywhere in the sheet. When the pointer starts
/// over vertically scrolled content, that content gets the gesture until it
/// returns to the top; a subsequent downward gesture dismisses the sheet.
Future<T?> showAppModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool? showDragHandle,
  bool useSafeArea = false,
  Color? backgroundColor,
  Color? barrierColor,
  String? barrierLabel,
  ShapeBorder? shape,
  Clip? clipBehavior,
  BoxConstraints? constraints,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
  bool? requestFocus,
}) {
  return showModalBottomSheet<T>(
    context: context,
    builder: (sheetContext) => _AppModalBottomSheetDragRegion(
      enabled: enableDrag,
      child: builder(sheetContext),
    ),
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    // The app-level drag region owns the vertical gesture so nested sheet
    // recognizers cannot compete with it.
    enableDrag: false,
    showDragHandle: showDragHandle,
    useSafeArea: useSafeArea,
    backgroundColor: backgroundColor,
    barrierColor: barrierColor,
    barrierLabel: barrierLabel,
    shape: shape,
    clipBehavior: clipBehavior,
    constraints: constraints,
    routeSettings: routeSettings,
    anchorPoint: anchorPoint,
    requestFocus: requestFocus,
    sheetAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 320),
      reverseDuration: Duration(milliseconds: 240),
    ),
  );
}

/// Lets visual drag handles know that the whole sheet already owns dragging.
class AppModalBottomSheetDragScope extends InheritedWidget {
  const AppModalBottomSheetDragScope({
    super.key,
    required this.enabled,
    required super.child,
  });

  final bool enabled;

  static AppModalBottomSheetDragScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppModalBottomSheetDragScope>();
  }

  @override
  bool updateShouldNotify(AppModalBottomSheetDragScope oldWidget) {
    return enabled != oldWidget.enabled;
  }
}

class _AppModalBottomSheetDragRegion extends StatefulWidget {
  const _AppModalBottomSheetDragRegion({
    required this.enabled,
    required this.child,
  });

  final bool enabled;
  final Widget child;

  @override
  State<_AppModalBottomSheetDragRegion> createState() =>
      _AppModalBottomSheetDragRegionState();
}

class _AppModalBottomSheetDragRegionState
    extends State<_AppModalBottomSheetDragRegion>
    with SingleTickerProviderStateMixin {
  static const double _dismissVelocity = 850;
  static const double _scrollTolerance = 0.5;

  late final AnimationController _settleController;

  int? _pointer;
  Offset _pointerOrigin = Offset.zero;
  double _pointerOriginOffset = 0;
  VelocityTracker? _velocityTracker;
  double _dragOffset = 0;
  double _settleOrigin = 0;
  bool _gestureDecided = false;
  bool _isDragging = false;
  bool _canDragFromPointerDown = true;
  bool _verticalContentIsScrolled = false;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _settleController = AnimationController(
      vsync: this,
      duration: AppMotion.state,
    )..addListener(_handleSettleTick);
  }

  void _handleSettleTick() {
    final progress = AppMotion.enter.transform(_settleController.value);
    setState(() => _dragOffset = _settleOrigin * (1 - progress));
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis == Axis.vertical && !_isDragging) {
      _verticalContentIsScrolled =
          notification.metrics.pixels >
          notification.metrics.minScrollExtent + _scrollTolerance;
    }
    return false;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (!widget.enabled || _pointer != null || _isDismissing) return;

    _settleController.stop();
    _pointer = event.pointer;
    _pointerOrigin = event.position;
    _pointerOriginOffset = _dragOffset;
    _gestureDecided = false;
    _isDragging = false;
    _canDragFromPointerDown = !_verticalContentIsScrolled;
    _velocityTracker = VelocityTracker.withKind(event.kind)
      ..addPosition(event.timeStamp, event.position);
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (event.pointer != _pointer || _isDismissing) return;
    _velocityTracker?.addPosition(event.timeStamp, event.position);

    final travel = event.position - _pointerOrigin;
    if (!_gestureDecided &&
        travel.distance >= kTouchSlop &&
        (travel.dy <= 0 ||
            travel.dy.abs() <= travel.dx.abs() ||
            !_canDragFromPointerDown)) {
      _gestureDecided = true;
      return;
    }

    if (!_gestureDecided && travel.dy > kTouchSlop) {
      _gestureDecided = true;
      _isDragging = true;
    }

    if (!_isDragging) return;
    setState(
      () => _dragOffset = math.max(
        0,
        _pointerOriginOffset + travel.dy - kTouchSlop,
      ),
    );
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (event.pointer != _pointer) return;
    _velocityTracker?.addPosition(event.timeStamp, event.position);
    final velocity = _velocityTracker?.getVelocity().pixelsPerSecond.dy ?? 0;
    _finishGesture(velocity);
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (event.pointer != _pointer) return;
    _finishGesture(0);
  }

  void _finishGesture(double velocity) {
    final wasDragging = _isDragging;
    _pointer = null;
    _velocityTracker = null;
    _gestureDecided = false;
    _isDragging = false;

    if (!wasDragging) {
      _settleToOrigin();
      return;
    }

    final sheetHeight =
        context.size?.height ?? MediaQuery.sizeOf(context).height;
    final dismissDistance = math.max(72.0, math.min(140.0, sheetHeight * 0.2));
    final shouldDismiss =
        _dragOffset >= dismissDistance ||
        (velocity >= _dismissVelocity && _dragOffset >= kTouchSlop);

    if (shouldDismiss) {
      _isDismissing = true;
      Navigator.of(context).maybePop();
      return;
    }
    _settleToOrigin();
  }

  void _settleToOrigin() {
    if (_dragOffset == 0) return;
    if (AppMotion.reduced(context)) {
      setState(() => _dragOffset = 0);
      return;
    }

    _settleOrigin = _dragOffset;
    _settleController
      ..duration = AppMotion.state
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _settleController
      ..removeListener(_handleSettleTick)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _handlePointerDown,
        onPointerMove: _handlePointerMove,
        onPointerUp: _handlePointerUp,
        onPointerCancel: _handlePointerCancel,
        child: Transform.translate(
          offset: Offset(0, _dragOffset),
          child: AppModalBottomSheetDragScope(
            enabled: widget.enabled,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
