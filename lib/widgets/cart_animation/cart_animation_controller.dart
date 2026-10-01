import 'dart:async';
import 'dart:math' as math;

import 'package:enjoy_lavash_mobile/theme/app_motion.dart';
import 'package:enjoy_lavash_mobile/widgets/cart_animation/cart_animation_source.dart';
import 'package:enjoy_lavash_mobile/widgets/cart_animation/packaging_visual.dart';
import 'package:enjoy_lavash_mobile/widgets/cart_animation/preset_packaging_visual.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Coordinates decoration only. The caller owns cart mutation/reconciliation.
/// Every invocation executes [add]'s operation exactly once, even during a flight.
class CartAnimationController {
  CartAnimationController({this.duration = const Duration(milliseconds: 2200)});

  /// Overall timing scales all preparation, folding, and flight phases together.
  /// Reduced motion retains its independent, short fade.
  final Duration duration;
  final Set<CartPackagingAssets> _readyAssets = {};
  OverlayEntry? _entry;
  CartAnimationSource? _source;
  VoidCallback? _onCancelled;
  bool _reserved = false;
  bool _disposed = false;
  int _generation = 0;

  bool get isAnimating => _reserved;

  /// Call when menu assets arrive, never on the animation's frame path.
  Future<void> preload(
    BuildContext context,
    Iterable<CartPackagingAssets> assets,
  ) async {
    if (_disposed || !context.mounted) return;
    await PresetPackagingVisual.prepareMaterials();
    if (_disposed || !context.mounted) return;
    await precacheImage(
      const ResizeImage(AssetImage('assets/images/enjoy-logo.png'), width: 144),
      context,
      onError: (_, _) {},
    );
    for (final asset in assets) {
      if (_disposed || !context.mounted) return;
      if (_readyAssets.contains(asset)) continue;
      if (await asset.preload(context) && !_disposed) _readyAssets.add(asset);
    }
  }

  Future<bool> add({
    required BuildContext context,
    required FutureOr<void> Function() operation,
    required Rect? Function() destination,
    required VoidCallback onConfirmed,
    required void Function(Object error, StackTrace stack) onFailed,
    CartAnimationSource? source,
    CartPackagingAssets? packaging,
    // A built-in preset is used when optional artwork is absent or not ready.
    CartPackagingKind? packagingKind,
    CartAnimationSource? Function()? fallbackSource,
    Rect? Function()? stagingBounds,
    double packagingSize = 360,
    VoidCallback? onCancelled,
  }) async {
    if (_disposed) return false;
    final route = ModalRoute.of(context);
    final generation = _generation;
    final ownsEffect = !_reserved;
    if (ownsEffect) {
      _reserved = true;
      _onCancelled = onCancelled;
    }
    unawaited(HapticFeedback.lightImpact());
    try {
      // Future.sync invokes synchronous local mutations immediately and also
      // observes asynchronous server rejection without coupling it to motion.
      await Future<void>.sync(operation);
    } catch (error, stack) {
      if (!_disposed && generation == _generation && context.mounted) {
        if (ownsEffect) _removeEffect(cancelled: true);
        if (route?.isCurrent ?? true) onFailed(error, stack);
      }
      return false;
    }
    if (_disposed || generation != _generation || !context.mounted) return true;
    if (route != null && !route.isCurrent) {
      if (ownsEffect) _removeEffect(cancelled: true);
      return true;
    }
    if (!ownsEffect) {
      // Coalesce decoration, never quantity changes or network requests.
      onConfirmed();
      return true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed || generation != _generation || !context.mounted) return;
      if (route != null && !route.isCurrent) {
        _removeEffect(cancelled: true);
        return;
      }
      var freshSource = source?.recapture != null
          ? source!.recapture!()
          : source;
      final overlay = Overlay.maybeOf(context, rootOverlay: true);
      final overlayBox = overlay?.context.findRenderObject();
      final initialTarget = destination();
      if (overlay == null ||
          overlayBox is! RenderBox ||
          !overlayBox.hasSize ||
          initialTarget == null) {
        _removeEffect(cancelled: false);
        onConfirmed();
        return;
      }
      final viewport = (overlayBox.localToGlobal(Offset.zero) & overlayBox.size)
          .inflate(0.5);
      bool visible(CartAnimationSource? candidate) {
        final bounds = candidate?.bounds;
        return bounds != null &&
            bounds.isFinite &&
            !bounds.isEmpty &&
            viewport.contains(bounds.topLeft) &&
            viewport.contains(bounds.bottomRight);
      }

      final reduced = AppMotion.reduced(context);
      // Detail pages can stage a fresh copy inside their visible body when the
      // hero is clipped. Never resurrect its stale off-screen bounds.
      if (!visible(freshSource)) {
        freshSource = reduced ? null : fallbackSource?.call();
      }
      if (freshSource == null || !visible(freshSource)) {
        _removeEffect(cancelled: false);
        onConfirmed();
        return;
      }
      final resolvedSource = freshSource;
      final bounds = resolvedSource.bounds;
      final localSource = Rect.fromLTWH(
        overlayBox.globalToLocal(bounds.topLeft).dx,
        overlayBox.globalToLocal(bounds.topLeft).dy,
        bounds.width,
        bounds.height,
      );
      Rect? resolveTarget() {
        final target = destination();
        if (target == null || !target.isFinite || target.isEmpty) return null;
        return overlayBox.globalToLocal(target.topLeft) & target.size;
      }

      _source = resolvedSource;
      if (!reduced) resolvedSource.setHidden?.call(true);
      final artwork = _readyAssets.contains(packaging) ? packaging : null;
      final stage = stagingBounds?.call();
      final localStage = stage != null && stage.isFinite && !stage.isEmpty
          ? overlayBox.globalToLocal(stage.topLeft) & stage.size
          : null;
      late final OverlayEntry entry;
      entry = OverlayEntry(
        builder: (_) => _CartFlight(
          source: localSource,
          image: resolvedSource.child,
          destination: resolveTarget,
          packaging: artwork,
          packagingKind: packagingKind,
          viewportSize: overlayBox.size,
          viewportPadding:
              MediaQuery.maybeOf(context)?.padding ?? EdgeInsets.zero,
          stagingArea: localStage,
          packagingSize: packagingSize,
          fadeIn: resolvedSource.fadeIn,
          duration: reduced ? const Duration(milliseconds: 140) : duration,
          reduced: reduced,
          isCurrent: () => route?.isCurrent ?? true,
          onArrived: () {
            if (_entry == entry) onConfirmed();
          },
          onCompleted: () {
            if (_entry == entry) _removeEffect(cancelled: false);
          },
          onCancelled: () {
            if (_entry == entry) _removeEffect(cancelled: true);
          },
        ),
      );
      _entry = entry;
      overlay.insert(entry);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
    return true;
  }

  void _removeEffect({required bool cancelled}) {
    final entry = _entry;
    _entry = null;
    entry?.remove();
    entry?.dispose();
    _source?.setHidden?.call(false);
    _source = null;
    _reserved = false;
    final callback = _onCancelled;
    _onCancelled = null;
    if (cancelled) callback?.call();
  }

  /// Also invalidates pending asynchronous completions and scheduled inserts.
  void cancel() {
    _generation++;
    _removeEffect(cancelled: true);
  }

  void dispose() {
    if (_disposed) return;
    cancel();
    _disposed = true;
    _readyAssets.clear();
  }
}

class _CartFlight extends StatefulWidget {
  const _CartFlight({
    required this.source,
    required this.image,
    required this.destination,
    required this.packaging,
    required this.packagingKind,
    required this.viewportSize,
    required this.viewportPadding,
    required this.stagingArea,
    required this.packagingSize,
    required this.fadeIn,
    required this.duration,
    required this.reduced,
    required this.isCurrent,
    required this.onArrived,
    required this.onCompleted,
    required this.onCancelled,
  });

  final Rect source;
  final Widget image;
  final Rect? Function() destination;
  final CartPackagingAssets? packaging;
  final CartPackagingKind? packagingKind;
  final Size viewportSize;
  final EdgeInsets viewportPadding;
  final Rect? stagingArea;
  final double packagingSize;
  final bool fadeIn;
  final Duration duration;
  final bool reduced;
  final bool Function() isCurrent;
  final VoidCallback onArrived;
  final VoidCallback onCompleted;
  final VoidCallback onCancelled;

  @override
  State<_CartFlight> createState() => _CartFlightState();
}

class _CartFlightState extends State<_CartFlight>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: widget.duration,
    animationBehavior: AnimationBehavior.preserve,
  )..addListener(_tick);
  Rect? _target;
  bool _arrived = false;
  bool _confirmed = false;
  bool _ending = false;

  bool get _usesPreset =>
      widget.packaging == null && widget.packagingKind != null;

  // The built-in sequence closes first, holds the sealed package, then flies.
  double get _launchTime => _usesPreset ? 0.68 : 650 / 1100;
  double get _arrivalTime => _usesPreset ? 0.94 : 1000 / 1100;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clock.forward();
  }

  void _finish(VoidCallback callback) {
    if (_ending) return;
    _ending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) callback();
    });
  }

  void _tick() {
    if (!widget.isCurrent()) {
      _finish(widget.onCancelled);
      return;
    }
    // Resolve AFTER the cart bar's entrance/layout, once at flight launch.
    // No layout queries or image decoding on the per-frame paint path.
    if (!widget.reduced && _clock.value >= _launchTime && _target == null) {
      _target = widget.destination();
      if (_target == null) {
        _finish(widget.onCancelled);
        return;
      }
    }
    final arrival = widget.reduced ? 0.5 : _arrivalTime;
    if (!_arrived && _clock.value >= arrival) {
      _arrived = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_ending) _confirm();
      });
    }
    if (_clock.isCompleted) {
      _finish(() {
        // A skipped frame may cross both arrival and completion thresholds.
        _confirm();
        widget.onCompleted();
      });
    }
  }

  void _confirm() {
    if (_confirmed) return;
    _confirmed = true;
    widget.onArrived();
  }

  @override
  void didChangeMetrics() => _finish(widget.onCancelled);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _finish(widget.onCancelled);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock.dispose();
    super.dispose();
  }

  double _phase(double value, double start, double end) =>
      ((value - start) / (end - start)).clamp(0.0, 1.0);

  Widget _buildPresetFlight(double t, Widget image) {
    final source = widget.source;
    final padding = widget.viewportPadding;
    final safeArea = Rect.fromLTRB(
      padding.left,
      padding.top,
      widget.viewportSize.width - padding.right,
      widget.viewportSize.height - padding.bottom,
    );
    final intersection = widget.stagingArea?.intersect(safeArea);
    final stage = intersection == null || intersection.isEmpty
        ? safeArea
        : intersection;
    final side = math.min(
      widget.packagingSize,
      math.max(1.0, math.min(stage.width, stage.height) - 24),
    );
    final frameSize = Size(
      math.max(source.width, side),
      math.max(source.height, side),
    );
    // Lift from the original photo, then wrap in the center of the visible view.
    final packedCenter = stage.center;
    final lift = Curves.easeInOutCubic.transform(_phase(t, 0, 0.16));
    final progress = _phase(t, 0.08, 0.56);
    // The sealed parcel sets down with a small bounce, then crouches before
    // it leaves. Both are scale-only, so the parcel never drifts off stage.
    final landing = math.sin(_phase(t, 0.56, 0.63) * math.pi);
    final crouch = math.sin(_phase(t, 0.63, _launchTime) * math.pi);
    // Flight is an unpowered toss: linear time drives a gravity parabola while
    // horizontal travel eases, so the parcel rises, hangs, then drops in.
    final flight = _phase(t, _launchTime, _arrivalTime);
    final shrink = Curves.easeInQuad.transform(flight);
    final target = _target;
    var center = Offset.lerp(source.center, packedCenter, lift)!;
    var tilt = -.02 * landing;
    var endScale = 0.1;
    if (target != null) {
      final travel = Curves.easeInOutSine.transform(flight);
      final delta = target.center - packedCenter;
      final arc = (delta.distance * .24).clamp(40.0, 120.0);
      center = Offset(
        packedCenter.dx + delta.dx * travel,
        packedCenter.dy + delta.dy * flight - arc * 4 * flight * (1 - flight),
      );
      endScale = (target.shortestSide / side * 0.65).clamp(0.06, 0.3);
      // Lean into the direction of travel, most at the top of the arc.
      final direction = delta.dx.abs() < 1 ? 0.0 : delta.dx.sign;
      tilt += -.16 * direction * math.sin(flight * math.pi) - .05 * flight;
    }
    final scale = (1 + .03 * landing) * (1 - shrink) + endScale * shrink;
    final opacity =
        (widget.fadeIn ? _phase(t, 0, 0.1) : 1) * (1 - _phase(flight, 0.86, 1));
    // The ground shadow stays on the surface: it spreads, softens and fades
    // as the parcel lifts away instead of travelling with it.
    final reveal = _phase(t, 0, 0.16);
    // The shadow belongs to a parcel resting on the surface, so it appears as
    // the parcel sets down rather than waiting on the stage ahead of it.
    final setDown = _phase(t, 0.11, 0.24);
    final liftOff = _phase(flight, 0, 0.38);
    final footprint = PresetPackagingVisual.groundShadowRect(
      widget.packagingKind!,
    );
    final unit = side / 320;
    final stageOrigin = packedCenter - Offset(side / 2, side / 2);
    final grounded = .76 + .24 * reveal;
    final shadowRect = Rect.fromCenter(
      center:
          stageOrigin +
          Offset(160 * unit, 175 * unit) +
          (footprint.center - const Offset(160, 175)) * unit * grounded,
      width: footprint.width * unit * grounded,
      height: footprint.height * unit * grounded,
    );
    return Stack(
      children: [
        Positioned.fromRect(
          rect: shadowRect.inflate(48 * unit),
          child: CustomPaint(
            painter: _GroundShadowPainter(
              footprint: Rect.fromCenter(
                center:
                    Offset(shadowRect.width / 2, shadowRect.height / 2) +
                    Offset(48 * unit, 48 * unit),
                width: shadowRect.width,
                height: shadowRect.height,
              ),
              opacity: setDown * (1 - liftOff),
              spread: liftOff,
              unit: unit,
            ),
          ),
        ),
        Positioned.fromRect(
          rect: Rect.fromCenter(
            center: source.center,
            width: frameSize.width,
            height: frameSize.height,
          ),
          child: Transform.translate(
            offset: center - source.center,
            child: Transform.rotate(
              angle: tilt,
              child: Transform.scale(
                scaleX: scale * (1 + .025 * crouch),
                scaleY: scale * (1 - .04 * crouch),
                child: Opacity(
                  opacity: opacity,
                  child: Center(
                    child: SizedBox.square(
                      dimension: side,
                      child: PresetPackagingVisual(
                        kind: widget.packagingKind!,
                        progress: progress,
                        product: image,
                        productSize: source.size,
                        groundShadow: false,
                        initialProductRect: Rect.fromCenter(
                          center: const Offset(160, 160),
                          width: source.width * 320 / side,
                          height: source.height * 320 / side,
                        ),
                        entranceProgress: Curves.easeInOutCubic.transform(
                          _phase(t, 0, 0.2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final artwork = widget.packaging;
    final source = widget.source;
    final packedSize = source.size;
    final packedCenter = source.center - const Offset(0, 12);
    return Positioned.fill(
      key: ValueKey(widget.reduced ? 'cart-add-fade' : 'wrap-to-cart-flight'),
      child: ExcludeSemantics(
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _clock,
            child: RepaintBoundary(child: widget.image),
            builder: (context, image) {
              final t = _clock.value;
              if (widget.reduced) {
                return Stack(
                  children: [
                    Positioned.fromRect(
                      rect: source,
                      child: Opacity(
                        opacity: 1 - t,
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            Colors.white.withValues(alpha: 0.08),
                            BlendMode.srcATop,
                          ),
                          child: image,
                        ),
                      ),
                    ),
                  ],
                );
              }
              if (_usesPreset) return _buildPresetFlight(t, image!);
              final prepare = Curves.easeInOutCubic.transform(
                _phase(t, 100 / 1100, 350 / 1100),
              );
              final travel = Curves.easeInOutCubic.transform(
                _phase(t, 650 / 1100, 1000 / 1100),
              );
              final target = _target;
              final start = Offset.lerp(source.center, packedCenter, prepare)!;
              var center = start;
              if (target != null) {
                final control = Offset(
                  (packedCenter.dx + target.center.dx) / 2,
                  math.min(packedCenter.dy, target.center.dy) - 36,
                );
                center = Offset.lerp(
                  Offset.lerp(packedCenter, control, travel)!,
                  Offset.lerp(control, target.center, travel)!,
                  travel,
                )!;
              }
              final endScale = target == null
                  ? 0.12
                  : (target.shortestSide / packedSize.longestSide * 0.55).clamp(
                      0.06,
                      0.35,
                    );
              final preparedScale =
                  1 - (1 - math.min(1.0, 190 / source.longestSide)) * prepare;
              final scale = preparedScale * (1 - travel) + endScale * travel;
              final opacity = 1 - _phase(travel, 0.86, 1);
              final stage = artwork == null
                  ? image!
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        if (prepare < 1)
                          Opacity(opacity: 1 - prepare, child: image),
                        Opacity(
                          opacity: prepare,
                          child: CartPackagingVisual(
                            kind: artwork.kind,
                            assets: artwork,
                            product: Image(
                              image: artwork.productCutout!,
                              fit: BoxFit.contain,
                            ),
                            progress: _phase(t, 100 / 1100, 650 / 1100),
                            size: source.size,
                          ),
                        ),
                      ],
                    );
              return Stack(
                children: [
                  // Bounds are fixed at capture; only compositor transforms move.
                  Positioned(
                    left: source.left,
                    top: source.top,
                    width: source.width,
                    height: source.height,
                    child: Transform.translate(
                      offset: center - source.center,
                      child: Transform.rotate(
                        angle: -0.06 * travel,
                        child: Transform.scale(
                          scale: scale,
                          child: Opacity(
                            opacity: opacity,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: 0.12 * prepare * (1 - travel),
                                    ),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: stage,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Contact shadow left on the surface beneath a lifting parcel.
class _GroundShadowPainter extends CustomPainter {
  const _GroundShadowPainter({
    required this.footprint,
    required this.opacity,
    required this.spread,
    required this.unit,
  });

  final Rect footprint;
  final double opacity;
  final double spread;
  final double unit;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    // Wider, softer and fainter the higher the parcel is above the surface.
    final grow = 1 + .6 * spread;
    final rect = Rect.fromCenter(
      center: footprint.center,
      width: footprint.width * grow,
      height: footprint.height * (1 + .8 * spread),
    );
    const shadow = Color(0xff2a1a08);
    canvas.drawOval(
      rect.inflate(6 * unit),
      Paint()
        ..color = shadow.withValues(alpha: .12 * opacity)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          (14 + 16 * spread) * unit,
        ),
    );
    canvas.drawOval(
      rect,
      Paint()
        ..color = shadow.withValues(alpha: .2 * opacity * (1 - .5 * spread))
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          (7 + 12 * spread) * unit,
        ),
    );
    canvas.drawOval(
      rect.deflate(5 * unit),
      Paint()
        ..color = shadow.withValues(alpha: .16 * opacity * (1 - spread))
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          (2.5 + 8 * spread) * unit,
        ),
    );
  }

  @override
  bool shouldRepaint(_GroundShadowPainter oldDelegate) =>
      oldDelegate.footprint != footprint ||
      oldDelegate.opacity != opacity ||
      oldDelegate.spread != spread ||
      oldDelegate.unit != unit;
}
