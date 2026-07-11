import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Plays a one-time fade + slide-up entrance when the widget is first built.
///
/// The animation runs once per element lifetime, so ordinary rebuilds do not
/// replay it. Use [delay] to stagger a group of siblings.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 280),
    this.beginOffset = const Offset(0, 0.06),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset beginOffset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final CurvedAnimation _animation = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.enter,
  );
  Timer? _delayTimer;
  bool _entranceScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = AppMotion.reduced(context);
    _controller.duration = AppMotion.duration(context, widget.duration);

    if (reduceMotion) {
      _delayTimer?.cancel();
      _entranceScheduled = true;
      _controller.value = 1;
      return;
    }

    if (_entranceScheduled) return;
    _entranceScheduled = true;
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant FadeSlideIn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = AppMotion.duration(context, widget.duration);
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _animation.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: widget.beginOffset,
          end: Offset.zero,
        ).animate(_animation),
        child: widget.child,
      ),
    );
  }
}

/// An [IndexedStack] that plays a fade + slide-up entrance for the selected
/// child on first launch and on every tab change, while keeping the state of
/// all tabs alive.
class FadeIndexedStack extends StatefulWidget {
  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 260),
    this.beginOffset = const Offset(0, 0.015),
  });

  final int index;
  final List<Widget> children;
  final Duration duration;
  final Offset beginOffset;

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final CurvedAnimation _animation = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.enter,
  );
  bool _initialEntranceStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = AppMotion.reduced(context);
    _controller.duration = AppMotion.duration(context, widget.duration);

    if (!_initialEntranceStarted) {
      _initialEntranceStarted = true;
      if (reduceMotion) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    } else if (reduceMotion) {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = AppMotion.duration(context, widget.duration);
    }
    if (oldWidget.index != widget.index) {
      if (AppMotion.reduced(context)) {
        _controller.value = 1;
      } else {
        _controller.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: widget.beginOffset,
          end: Offset.zero,
        ).animate(_animation),
        child: IndexedStack(index: widget.index, children: widget.children),
      ),
    );
  }
}
