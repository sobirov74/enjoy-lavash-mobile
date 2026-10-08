import 'package:flutter/widgets.dart';

/// A [FadeTransition] whose curve is applied by a [CurvedAnimation] it owns.
///
/// Route `transitionsBuilder`s run on every route rebuild; creating a
/// `CurvedAnimation` inline there registers a new listener on the route
/// animation each time and never removes it. This widget keeps one curved
/// animation per route and disposes it with the route.
class CurvedFadeTransition extends StatefulWidget {
  const CurvedFadeTransition({
    super.key,
    required this.animation,
    required this.curve,
    this.reverseCurve,
    required this.child,
  });

  final Animation<double> animation;
  final Curve curve;
  final Curve? reverseCurve;
  final Widget child;

  @override
  State<CurvedFadeTransition> createState() => _CurvedFadeTransitionState();
}

class _CurvedFadeTransitionState extends State<CurvedFadeTransition> {
  late CurvedAnimation _opacity = _curved();

  CurvedAnimation _curved() => CurvedAnimation(
    parent: widget.animation,
    curve: widget.curve,
    reverseCurve: widget.reverseCurve,
  );

  @override
  void didUpdateWidget(covariant CurvedFadeTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation ||
        oldWidget.curve != widget.curve ||
        oldWidget.reverseCurve != widget.reverseCurve) {
      _opacity.dispose();
      _opacity = _curved();
    }
  }

  @override
  void dispose() {
    _opacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}
