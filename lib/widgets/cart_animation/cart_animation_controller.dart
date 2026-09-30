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
    final travel = Curves.easeInOutCubic.transform(
      _phase(t, _launchTime, _arrivalTime),
    );
    final target = _target;
    var center = Offset.lerp(source.center, packedCenter, lift)!;
    if (target != null) {
      final control = Offset(
        (packedCenter.dx + target.center.dx) / 2,
        math.min(packedCenter.dy, target.center.dy) - 44,
      );
      center = Offset.lerp(
        Offset.lerp(packedCenter, control, travel)!,
        Offset.lerp(control, target.center, travel)!,
        travel,
      )!;
    }
    final endScale = target == null
        ? 0.1
        : (target.shortestSide / side * 0.65).clamp(0.06, 0.3);
    final settle = math.sin(_phase(t, 0.56, _launchTime) * math.pi);
    final scale = (1 + 0.025 * settle) * (1 - travel) + endScale * travel;
    return Stack(
      children: [
        Positioned.fromRect(
          rect: Rect.fromCenter(
            center: source.center,
            width: frameSize.width,
            height: frameSize.height,
          ),
          child: Transform.translate(
            offset: center - source.center,
            child: Transform.rotate(
              angle: -0.035 * settle - 0.08 * travel,
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity:
                      (widget.fadeIn ? _phase(t, 0, 0.1) : 1) *
                      (1 - _phase(travel, 0.9, 1)),
                  child: Center(
                    child: SizedBox.square(
                      dimension: side,
                      child: PresetPackagingVisual(
                        kind: widget.packagingKind!,
                        progress: progress,
                        product: image,
                        productSize: source.size,
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
