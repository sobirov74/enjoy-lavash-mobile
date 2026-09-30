import 'package:enjoy_lavash_mobile/theme/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A copy of the exact displayed image and its global paint bounds.
/// The anchor keeps its layout and hit testing while its copy is in the overlay.
class CartAnimationSource {
  const CartAnimationSource({
    required this.bounds,
    required this.child,
    this.setHidden,
    this.recapture,
    this.fadeIn = false,
  });

  final Rect bounds;
  final Widget child;
  final ValueChanged<bool>? setHidden;
  final CartAnimationSource? Function()? recapture;

  /// Introduce a staged off-screen product gently over the visible detail body.
  final bool fadeIn;
}

Rect? cartAnimationBounds(GlobalKey key) {
  final box = key.currentContext?.findRenderObject();
  if (box is! RenderBox || !box.attached || !box.hasSize) return null;
  final rect = MatrixUtils.transformRect(
    box.getTransformTo(null),
    Offset.zero & box.size,
  );
  return rect.isFinite && !rect.isEmpty ? rect : null;
}

class CartAnimationAnchor extends StatefulWidget {
  const CartAnimationAnchor({required this.child, super.key});

  final Widget child;

  @override
  State<CartAnimationAnchor> createState() => CartAnimationAnchorState();
}

class CartAnimationAnchorState extends State<CartAnimationAnchor> {
  bool _hidden = false;

  CartAnimationSource? capture() {
    if (!mounted) return null;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    final bounds = box.localToGlobal(Offset.zero) & box.size;
    final RenderObject? viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport is RenderBox && viewport.hasSize) {
      final visible = (viewport.localToGlobal(Offset.zero) & viewport.size)
          .inflate(0.5);
      if (!visible.contains(bounds.topLeft) ||
          !visible.contains(bounds.bottomRight)) {
        return null;
      }
    }
    final media = MediaQuery.maybeOf(context);
    final copy = media == null
        ? widget.child
        : MediaQuery(data: media, child: widget.child);
    return CartAnimationSource(
      bounds: bounds,
      // The root overlay may be outside a local theme/text-scale override.
      // Preserve those inputs as well as the exact image/cache configuration.
      child: InheritedTheme.captureAll(context, copy),
      recapture: capture,
      setHidden: (hidden) {
        if (mounted && _hidden != hidden) setState(() => _hidden = hidden);
      },
    );
  }

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: _hidden ? 0 : 1,
    // Retain the original image's accessible name while its visual copy moves.
    alwaysIncludeSemantics: true,
    child: widget.child,
  );
}

/// Press feedback never delays, debounces, or changes the button's callback.
class CartAddFeedback extends StatefulWidget {
  const CartAddFeedback({required this.child, super.key});

  final Widget child;

  @override
  State<CartAddFeedback> createState() => _CartAddFeedbackState();
}

class _CartAddFeedbackState extends State<CartAddFeedback> {
  bool _pressed = false;

  void _press(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _press(true),
    onPointerUp: (_) => _press(false),
    onPointerCancel: (_) => _press(false),
    child: AnimatedScale(
      scale: _pressed && !AppMotion.reduced(context) ? 0.96 : 1,
      duration: AppMotion.duration(context, const Duration(milliseconds: 70)),
      curve: Curves.easeOutCubic,
      child: widget.child,
    ),
  );
}
