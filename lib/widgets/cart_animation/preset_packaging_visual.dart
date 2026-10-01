import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'packaging_visual.dart';

part 'preset_packaging/materials.dart';
part 'preset_packaging/brand_seal.dart';
part 'preset_packaging/pizza.dart';
part 'preset_packaging/burger.dart';
part 'preset_packaging/lavash.dart';
part 'preset_packaging/hot_dog.dart';
part 'preset_packaging/fries.dart';
part 'preset_packaging/cup.dart';
part 'preset_packaging/bag.dart';

/// Reusable, asset-independent packaging driven by preparation progress.
///
/// Only the packaging is illustrated. [product] remains the selected catalog
/// image, fitted uniformly using its original [productSize]. All geometry uses
/// one fixed canvas, so folding and settling never trigger child layout.
class PresetPackagingVisual extends StatelessWidget {
  const PresetPackagingVisual({
    super.key,
    required this.kind,
    required this.progress,
    required this.product,
    required this.productSize,
    this.initialProductRect,
    this.entranceProgress,
    this.groundShadow = true,
  });

  final CartPackagingKind kind;
  final double progress;
  final Widget product;
  final Size productSize;

  /// Starting photo bounds in the fixed 320×320 canvas. Bounds can extend
  /// beyond the canvas, allowing a detail image to lift without changing size.
  final Rect? initialProductRect;

  /// Optional, already-eased placement progress, independent of paper folds.
  final double? entranceProgress;

  /// Whether the parcel paints its own contact shadow. The flight overlay
  /// disables this and keeps a detached ground shadow behind the lift-off.
  final bool groundShadow;

  /// Contact shadow footprint of a resting parcel in the 320 × 320 canvas.
  static Rect groundShadowRect(CartPackagingKind kind) =>
      _PackagingPainter._shadowBounds(kind);

  /// Rasterises the shared paper grain ahead of the first animation frame.
  static void warmUp() => _grainTile;

  /// Prepares every procedural material before the first animation, off the
  /// frame path. Idempotent: later calls complete immediately. Painting stays
  /// correct (and fully occluding) if a frame is drawn before this completes.
  static Future<void> prepareMaterials() async => warmUp();

  @override
  Widget build(BuildContext context) {
    final t = progress.clamp(0.0, 1.0);
    final geometry = _PackagingGeometry(kind, t);
    final source = initialProductRect ?? const Rect.fromLTWH(48, 55, 224, 204);
    final target = geometry.productRect;
    final settle = entranceProgress?.clamp(0.0, 1.0) ?? _phase(t, 0, .32);
    final scale = ui.lerpDouble(
      1,
      math.min(target.width / source.width, target.height / source.height),
      settle,
    )!;
    final offset = (target.center - source.center) * settle;
    final size = productSize.isFinite && !productSize.isEmpty
        ? productSize
        : const Size(160, 160);
    // The photo's fitted footprint casts a soft contact shadow on the paper
    // once it has settled, so it sits in the package instead of floating.
    final fitted = applyBoxFit(BoxFit.contain, size, source.size).destination;
    final contact = Rect.fromCenter(
      center: source.center,
      width: fitted.width,
      height: fitted.height,
    );
    final enclosed = switch (kind) {
      CartPackagingKind.burger ||
      CartPackagingKind.lavash ||
      CartPackagingKind.pizza ||
      CartPackagingKind.cup ||
      CartPackagingKind.combo ||
      CartPackagingKind.none => t >= .9,
      _ => false,
    };
    return RepaintBoundary(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox.square(
          dimension: 320,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _PackagingPainter(
                    geometry,
                    foreground: false,
                    groundShadow: groundShadow,
                  ),
                ),
              ),
              if (!enclosed && settle > 0)
                Positioned.fromRect(
                  rect: contact,
                  child: Transform.translate(
                    offset: offset,
                    child: Transform.scale(
                      scale: scale,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xff2a1a08,
                                ).withValues(alpha: .22 * settle),
                                blurRadius: 9,
                                spreadRadius: -2,
                                offset: const Offset(2, 6),
                              ),
                              BoxShadow(
                                color: const Color(
                                  0xff2a1a08,
                                ).withValues(alpha: .18 * settle),
                                blurRadius: 2.5,
                                spreadRadius: -1,
                                offset: const Offset(.5, 1.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned.fromRect(
                rect: source,
                child: Transform.translate(
                  offset: offset,
                  child: Transform.scale(
                    scale: scale,
                    child: Visibility(
                      visible: !enclosed,
                      maintainState: true,
                      maintainAnimation: true,
                      maintainSize: true,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox.fromSize(size: size, child: product),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _PackagingPainter(geometry, foreground: true),
                ),
              ),
              if (kind != CartPackagingKind.bottle)
                Positioned.fromRect(
                  rect: geometry.brandRect,
                  child: Opacity(
                    opacity: _phase(t, .76, .94),
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, .0015)
                        ..rotateX(kind == CartPackagingKind.pizza ? -.46 : -.06)
                        ..rotateZ(
                          kind == CartPackagingKind.lavash ? -.025 : .015,
                        ),
                      child: const _BrandSeal(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

double _phase(double t, double start, double end) => Curves.easeInOutCubic
    .transform(((t - start) / (end - start)).clamp(0.0, 1.0));

class _PackagingGeometry {
  const _PackagingGeometry(this.kind, this.t);

  final CartPackagingKind kind;
  final double t;

  Rect get productRect => switch (kind) {
    CartPackagingKind.pizza => const Rect.fromLTWH(66, 121, 188, 100),
    CartPackagingKind.burger => const Rect.fromLTWH(83, 112, 154, 116),
    CartPackagingKind.lavash => const Rect.fromLTWH(102, 80, 116, 171),
    CartPackagingKind.hotDog => const Rect.fromLTWH(55, 110, 210, 120),
    CartPackagingKind.fries => const Rect.fromLTWH(91, 72, 138, 166),
    CartPackagingKind.cup => const Rect.fromLTWH(121, 115, 78, 124),
    CartPackagingKind.bottle => const Rect.fromLTWH(93, 42, 134, 230),
    CartPackagingKind.combo ||
    CartPackagingKind.none => const Rect.fromLTWH(100, 140, 120, 105),
  };

  Rect get brandRect => switch (kind) {
    CartPackagingKind.pizza => const Rect.fromLTWH(132, 136, 56, 56),
    CartPackagingKind.burger => const Rect.fromLTWH(133, 140, 54, 54),
    CartPackagingKind.lavash => const Rect.fromLTWH(135, 138, 50, 58),
    CartPackagingKind.hotDog => const Rect.fromLTWH(136, 147, 48, 50),
    CartPackagingKind.fries => const Rect.fromLTWH(134, 183, 52, 52),
    CartPackagingKind.cup => const Rect.fromLTWH(139, 169, 42, 46),
    CartPackagingKind.combo ||
    CartPackagingKind.none => const Rect.fromLTWH(132, 172, 56, 60),
    CartPackagingKind.bottle => Rect.zero,
  };
}

/// Separate back/front passes let the real photo sit inside the paper layers.
class _PackagingPainter extends CustomPainter {
  const _PackagingPainter(
    this.geometry, {
    required this.foreground,
    this.groundShadow = true,
  });

  final _PackagingGeometry geometry;
  final bool foreground;
  final bool groundShadow;

  double get t => geometry.t;
  double p(double a, double b) => _phase(t, a, b);

  @override
  void paint(Canvas canvas, Size size) {
    final reveal = p(0, .16);
    if (reveal == 0 || geometry.kind == CartPackagingKind.bottle) return;
    // A whole-material reveal beneath the settling product, without an opaque
    // stage/card. Every surface has a matching foreground occlusion layer.
    canvas.save();
    canvas.translate(160, 175);
    canvas.scale(.76 + .24 * reveal);
    canvas.translate(-160, -175);
    if (!foreground && groundShadow) _contactShadow(canvas);
    switch (geometry.kind) {
      case CartPackagingKind.burger:
        _burger(canvas);
      case CartPackagingKind.lavash:
        _lavash(canvas);
      case CartPackagingKind.pizza:
        _pizza(canvas);
      case CartPackagingKind.hotDog:
        _hotDog(canvas);
      case CartPackagingKind.fries:
        _fries(canvas);
      case CartPackagingKind.cup:
        _cup(canvas);
      case CartPackagingKind.combo:
      case CartPackagingKind.none:
        _bag(canvas);
      case CartPackagingKind.bottle:
        break;
    }
    canvas.restore();
  }

  static Rect _shadowBounds(CartPackagingKind kind) => switch (kind) {
    CartPackagingKind.pizza => const Rect.fromLTWH(63, 229, 196, 21),
    CartPackagingKind.burger => const Rect.fromLTWH(91, 228, 144, 21),
    CartPackagingKind.hotDog => const Rect.fromLTWH(64, 212, 193, 24),
    CartPackagingKind.lavash => const Rect.fromLTWH(107, 246, 109, 22),
    _ => const Rect.fromLTWH(107, 253, 110, 19),
  };

  void _contactShadow(Canvas c) {
    // Three warm layers: a wide ambient pool, the body shadow and a tight
    // dark contact line where the parcel actually touches the surface.
    final bounds = _shadowBounds(geometry.kind);
    c.drawOval(
      bounds.inflate(6),
      Paint()
        ..color = const Color(0x1e2a1a08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    c.drawOval(
      bounds,
      Paint()
        ..color = const Color(0x342a1a08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    c.drawOval(
      bounds.deflate(5),
      Paint()
        ..color = const Color(0x2a1a1008)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );
  }

  @override
  bool shouldRepaint(_PackagingPainter oldDelegate) =>
      oldDelegate.geometry.t != t ||
      oldDelegate.geometry.kind != geometry.kind ||
      oldDelegate.foreground != foreground ||
      oldDelegate.groundShadow != groundShadow;
}
