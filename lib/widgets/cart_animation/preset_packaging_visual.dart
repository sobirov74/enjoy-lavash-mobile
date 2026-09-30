import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'packaging_visual.dart';

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
                  painter: _PackagingPainter(geometry, foreground: false),
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

class _BrandSeal extends StatelessWidget {
  const _BrandSeal();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xff393832), Color(0xff252522), Color(0xff2c2b26)],
      ),
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: const Color(0xffd7b570), width: .8),
      boxShadow: const [
        BoxShadow(
          color: Color(0x39000000),
          blurRadius: 1.3,
          offset: Offset(.3, .7),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(2),
      child: Image.asset(
        'assets/images/enjoy-logo.png',
        cacheWidth: 144,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        excludeFromSemantics: true,
        errorBuilder: (_, _, _) => const Center(
          child: Text(
            'Enjoy',
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: Color(0xffffd322),
              fontSize: 16,
              fontWeight: FontWeight.w800,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    ),
  );
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
  const _PackagingPainter(this.geometry, {required this.foreground});

  final _PackagingGeometry geometry;
  final bool foreground;

  static const _paper = Color(0xfff0dfbd);
  static const _paperLight = Color(0xfffff0d3);
  static const _paperDark = Color(0xffcaa979);
  static const _ink = Color(0xff292828);
  static const _inkLight = Color(0xff41403c);
  static const _seam = Color(0xffb29469);
  static const _gold = Color(0xffe7bb58);

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
    if (!foreground) _contactShadow(canvas);
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

  void _contactShadow(Canvas c) {
    final bounds = switch (geometry.kind) {
      CartPackagingKind.pizza => const Rect.fromLTWH(63, 229, 196, 21),
      CartPackagingKind.burger => const Rect.fromLTWH(91, 228, 144, 21),
      CartPackagingKind.hotDog => const Rect.fromLTWH(64, 212, 193, 24),
      CartPackagingKind.lavash => const Rect.fromLTWH(107, 246, 109, 22),
      _ => const Rect.fromLTWH(107, 253, 110, 19),
    };
    c.drawOval(
      bounds,
      Paint()
        ..color = const Color(0x38000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    c.drawOval(
      bounds.deflate(4),
      Paint()
        ..color = const Color(0x25000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  void _burger(Canvas c) {
    if (!foreground) {
      // The open diamond disappears beneath the folds as each side turns in.
      final left = p(.2, .46);
      final right = p(.35, .62);
      final bottom = p(.11, .36);
      final top = p(.57, .86);
      _surface(
        c,
        _polygon([
          Offset(160, ui.lerpDouble(28, 104, top)!),
          Offset(ui.lerpDouble(300, 240, right)!, 164),
          Offset(160, ui.lerpDouble(296, 238, bottom)!),
          Offset(ui.lerpDouble(20, 80, left)!, 164),
        ]),
        _inkLight,
        _ink,
        shadow: true,
      );
      _surface(
        c,
        _rounded(const Rect.fromLTWH(78, 100, 164, 140), 15),
        _inkLight,
        _ink,
      );
      return;
    }
    // Distinct lower, left, right, then upper folds, each closing over the food.
    _fold(
      c,
      [const Offset(80, 235), const Offset(240, 235), const Offset(160, 296)],
      [const Offset(80, 235), const Offset(240, 235), const Offset(160, 146)],
      p(.11, .36),
      const Color(0xff373633),
      _ink,
    );
    _fold(
      c,
      [const Offset(80, 106), const Offset(17, 159), const Offset(80, 235)],
      [const Offset(80, 106), const Offset(185, 161), const Offset(80, 235)],
      p(.2, .46),
      _inkLight,
      _ink,
    );
    _fold(
      c,
      [const Offset(240, 106), const Offset(302, 162), const Offset(240, 235)],
      [const Offset(240, 106), const Offset(135, 164), const Offset(240, 235)],
      p(.35, .62),
      const Color(0xff49473f),
      _ink,
    );
    _fold(
      c,
      [const Offset(80, 104), const Offset(160, 27), const Offset(240, 104)],
      [const Offset(80, 104), const Offset(160, 211), const Offset(240, 104)],
      p(.57, .86),
      const Color(0xff3a3935),
      const Color(0xff222222),
    );
    if (t > .7) {
      final amount = p(.7, .89);
      _volume(c, _rounded(const Rect.fromLTWH(79, 103, 162, 134), 17), amount);
      _wrinkle(c, const Offset(84, 113), const Offset(107, 141), amount);
      _wrinkle(c, const Offset(236, 115), const Offset(212, 141), amount);
      _wrinkle(c, const Offset(85, 227), const Offset(110, 208), amount);
      _wrinkle(c, const Offset(235, 226), const Offset(215, 210), amount);
    }
    if (t > .77) {
      final seal = p(.77, .94);
      _surface(
        c,
        _rounded(Rect.fromLTWH(150, 185, 20, 39 * seal), 3),
        _gold,
        const Color(0xffbc9147),
      );
      _line(
        c,
        const Offset(154, 218),
        const Offset(166, 218),
        const Color(0xff947036),
      );
    }
  }

  void _lavash(Canvas c) {
    final left = p(.16, .48);
    final right = p(.35, .69);
    final end = p(.62, .89);
    if (!foreground) {
      _surface(
        c,
        _polygon([
          Offset(ui.lerpDouble(42, 98, left)!, 74),
          Offset(ui.lerpDouble(278, 222, right)!, 74),
          Offset(ui.lerpDouble(278, 222, right)!, 259),
          Offset(ui.lerpDouble(42, 98, left)!, 259),
        ]),
        _paperLight,
        _paperDark,
        shadow: true,
      );
      _surface(
        c,
        _rounded(const Rect.fromLTWH(99, 74, 122, 186), 8),
        _paper,
        _paperDark,
      );
      return;
    }
    _fold(
      c,
      [
        const Offset(98, 74),
        const Offset(42, 87),
        const Offset(42, 248),
        const Offset(98, 259),
      ],
      [
        const Offset(98, 74),
        const Offset(181, 84),
        const Offset(181, 248),
        const Offset(98, 259),
      ],
      left,
      _paperLight,
      _paperDark,
    );
    _fold(
      c,
      [
        const Offset(222, 74),
        const Offset(278, 87),
        const Offset(278, 248),
        const Offset(222, 259),
      ],
      [
        const Offset(222, 74),
        const Offset(143, 84),
        const Offset(143, 248),
        const Offset(222, 259),
      ],
      right,
      _paperLight,
      _paper,
    );
    _fold(
      c,
      [
        const Offset(98, 259),
        const Offset(222, 259),
        const Offset(208, 290),
        const Offset(112, 290),
      ],
      [
        const Offset(98, 259),
        const Offset(222, 259),
        const Offset(207, 222),
        const Offset(112, 222),
      ],
      end,
      _paper,
      _paperDark,
    );
    _fold(
      c,
      [
        const Offset(98, 74),
        const Offset(112, 45),
        const Offset(208, 45),
        const Offset(222, 74),
      ],
      [
        const Offset(98, 74),
        const Offset(112, 104),
        const Offset(208, 104),
        const Offset(222, 74),
      ],
      end,
      _paperLight,
      _paperDark,
    );
    if (t > .69) {
      _volume(
        c,
        _rounded(const Rect.fromLTWH(100, 76, 120, 183), 7),
        p(.69, .89),
      );
      _crease(c, const Offset(144, 105), const Offset(144, 219), p(.69, .89));
      _wrinkle(c, const Offset(104, 80), const Offset(125, 106), p(.69, .89));
      _wrinkle(c, const Offset(215, 251), const Offset(197, 226), p(.69, .89));
      _print(c, const Rect.fromLTWH(105, 112, 108, 103), p(.69, .85));
      _surface(
        c,
        _rounded(Rect.fromLTWH(144, 190, 32, 29 * p(.74, .94)), 2),
        _gold,
        _paperDark,
      );
      _line(c, const Offset(149, 206), const Offset(171, 206), _seam);
    }
  }

  void _pizza(Canvas c) {
    const backLeft = Offset(76, 114);
    const backRight = Offset(244, 114);
    final close = p(.34, .88);
    // Project a rigid lid rotating about its rear hinge. Sine supplies height;
    // cosine supplies depth, and perspective keeps the hinge stationary while
    // the free edge lifts toward the viewer before settling on the front rim.
    final angle = (1 - close) * 1.9;
    final perspective =
        1 / (1 - .225 * math.cos(angle) + .13 * math.sin(angle));
    final edgeY =
        114 + (85.25 * math.cos(angle) - 84 * math.sin(angle)) * perspective;
    final halfWidth = 84 * perspective;
    final frontLeft = Offset(160 - halfWidth, edgeY);
    final frontRight = Offset(160 + halfWidth, edgeY);
    final lid = _polygon([backLeft, backRight, frontRight, frontLeft]);
    final aboveFood = edgeY >= 114;
    if (!foreground) {
      if (!aboveFood) {
        _surface(c, lid, _paperLight, _paper, shadow: true);
        _crease(
          c,
          backLeft + const Offset(8, -4),
          backRight + const Offset(-8, -4),
          .7,
        );
      }
      _surface(
        c,
        _polygon([
          backLeft,
          backRight,
          const Offset(273, 225),
          const Offset(47, 225),
        ]),
        _paperLight,
        _paperDark,
        shadow: true,
      );
      // Recessed floor and four folded walls give the empty box real depth.
      _surface(
        c,
        _polygon([
          const Offset(84, 127),
          const Offset(236, 127),
          const Offset(253, 218),
          const Offset(67, 218),
        ]),
        const Color(0xffd8bd92),
        _paper,
      );
      _crease(c, const Offset(83, 125), const Offset(237, 125), .7);
      _crease(c, const Offset(65, 218), const Offset(83, 126), .65);
      _crease(c, const Offset(254, 218), const Offset(237, 126), .65);
      return;
    }
    _surface(
      c,
      _polygon([
        const Offset(47, 225),
        const Offset(273, 225),
        const Offset(267, 247),
        const Offset(53, 247),
      ]),
      _paperDark,
      const Color(0xffa9804d),
    );
    _surface(
      c,
      _polygon([
        const Offset(244, 114),
        const Offset(273, 225),
        const Offset(267, 247),
        const Offset(242, 139),
      ]),
      _paper,
      _paperDark,
    );
    _surface(
      c,
      _polygon([
        const Offset(76, 114),
        const Offset(47, 225),
        const Offset(53, 247),
        const Offset(78, 139),
      ]),
      const Color(0xffd3b88d),
      const Color(0xffba9767),
    );
    _line(
      c,
      const Offset(55, 230),
      const Offset(265, 230),
      const Color(0xff9b794d),
    );
    // Corrugated cardboard is visible on the front edge rather than a single
    // flat rectangle; short static fibres are cheap to retain across frames.
    for (double x = 61; x < 261; x += 5) {
      _line(c, Offset(x, 227), Offset(x + 1.8, 230), const Color(0xffad8855));
    }
    if (aboveFood) {
      final lift = math.sin(angle).abs();
      c.save();
      c.clipPath(
        _polygon([
          backLeft,
          backRight,
          const Offset(273, 225),
          const Offset(47, 225),
        ]),
      );
      c.translate(0, 3 + lift * 18);
      c.drawPath(
        lid,
        Paint()
          ..color = Color.fromRGBO(56, 35, 16, .13 + .08 * lift)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1 + lift * 5),
      );
      c.restore();
      _surface(c, lid, _paperLight, _paper);
      _surface(
        c,
        _polygon([
          frontLeft,
          frontRight,
          frontRight + const Offset(-.7, 3),
          frontLeft + const Offset(.7, 3),
        ]),
        const Color(0xffe2c99f),
        const Color(0xffb19060),
      );
      if (close > .88) {
        _crease(c, const Offset(61, 219), const Offset(259, 219), p(.76, .9));
        _surface(
          c,
          _polygon([
            Offset(140, edgeY - 3),
            Offset(180, edgeY - 3),
            Offset(177, edgeY + 19),
            Offset(143, edgeY + 19),
          ]),
          _gold,
          const Color(0xffc8a454),
        );
        _line(
          c,
          Offset(144, edgeY + 2),
          Offset(177, edgeY + 2),
          const Color(0xffaa813d),
        );
      }
    }
    if (t > .86) _print(c, const Rect.fromLTWH(90, 137, 140, 72), p(.86, .98));
  }

  void _hotDog(Canvas c) {
    if (!foreground) {
      _surface(
        c,
        _polygon([
          const Offset(61, 117),
          const Offset(264, 117),
          const Offset(287, 220),
          const Offset(34, 220),
        ]),
        _paperLight,
        _paperDark,
        shadow: true,
      );
      return;
    }
    _fold(
      c,
      [
        const Offset(34, 220),
        const Offset(287, 220),
        const Offset(273, 248),
        const Offset(47, 248),
      ],
      [
        const Offset(34, 220),
        const Offset(287, 220),
        const Offset(267, 194),
        const Offset(54, 194),
      ],
      p(.14, .46),
      _paper,
      _paperDark,
    );
    _surface(
      c,
      _polygon([
        const Offset(34, 220),
        const Offset(61, 117),
        const Offset(76, 136),
        const Offset(54, 194),
      ]),
      _paperLight,
      _paperDark,
    );
    _surface(
      c,
      _polygon([
        const Offset(287, 220),
        const Offset(264, 117),
        const Offset(248, 136),
        const Offset(267, 194),
      ]),
      _paper,
      _paperDark,
    );
    _fold(
      c,
      [
        const Offset(122, 118),
        const Offset(199, 118),
        const Offset(200, 53),
        const Offset(121, 53),
      ],
      [
        const Offset(122, 118),
        const Offset(199, 118),
        const Offset(208, 223),
        const Offset(112, 223),
      ],
      p(.38, .84),
      _inkLight,
      _ink,
    );
    if (t > .83) {
      _line(c, const Offset(119, 213), const Offset(201, 213), _gold);
    }
  }

  void _fries(Canvas c) {
    final rise = p(.18, .74);
    if (!foreground) {
      _surface(
        c,
        _polygon([
          const Offset(82, 119),
          const Offset(238, 119),
          const Offset(211, 263),
          const Offset(109, 263),
        ]),
        _paper,
        _paperDark,
        shadow: true,
      );
      return;
    }
    final y = ui.lerpDouble(263, 154, rise)!;
    final path = Path()
      ..moveTo(82, y)
      ..quadraticBezierTo(160, y + 40 * rise, 238, y)
      ..lineTo(211, 263)
      ..quadraticBezierTo(160, 273, 109, 263)
      ..close();
    _surface(c, path, _inkLight, _ink, shadow: true);
    if (rise > .3) {
      _line(
        c,
        Offset(96, y + 17 * rise),
        const Offset(119, 251),
        const Color(0xff69604d),
      );
      _line(
        c,
        Offset(224, y + 17 * rise),
        const Offset(201, 251),
        const Color(0xff69604d),
      );
    }
    if (rise > .95) {
      _line(c, const Offset(123, 250), const Offset(197, 250), _gold);
    }
  }

  void _cup(Canvas c) {
    const bodyTop = 103.0;
    if (!foreground) {
      _surface(
        c,
        _polygon([
          const Offset(104, bodyTop),
          const Offset(216, bodyTop),
          const Offset(201, 259),
          const Offset(119, 259),
        ]),
        _inkLight,
        _ink,
        shadow: true,
      );
      _surface(
        c,
        Path()..addOval(const Rect.fromLTWH(104, 95, 112, 18)),
        const Color(0xff151515),
        const Color(0xff494338),
      );
      return;
    }
    final close = p(.18, .67);
    final frontY = ui.lerpDouble(259, bodyTop, close)!;
    _surface(
      c,
      _polygon([
        Offset(ui.lerpDouble(119, 104, close)!, frontY),
        Offset(ui.lerpDouble(201, 216, close)!, frontY),
        const Offset(201, 259),
        const Offset(119, 259),
      ]),
      _inkLight,
      _ink,
    );
    final sleeve = p(.3, .72);
    _surface(
      c,
      _polygon([
        Offset(110, ui.lerpDouble(228, 159, sleeve)!),
        Offset(210, ui.lerpDouble(228, 159, sleeve)!),
        const Offset(201, 228),
        const Offset(119, 228),
      ]),
      _paperLight,
      _paperDark,
    );
    _line(
      c,
      const Offset(124, 251),
      const Offset(196, 251),
      const Color(0xff73684e),
    );
    final lidY = ui.lerpDouble(34, 86, p(.48, .88))!;
    _surface(
      c,
      _rounded(Rect.fromLTWH(91, lidY, 138, 20), 9),
      _inkLight,
      _ink,
      shadow: true,
    );
    _surface(
      c,
      _rounded(Rect.fromLTWH(99, lidY - 7, 122, 12), 5),
      const Color(0xff50504a),
      _ink,
    );
    _line(
      c,
      Offset(109, lidY - 1),
      Offset(210, lidY - 1),
      const Color(0xff747367),
    );
    _surface(
      c,
      _rounded(Rect.fromLTWH(189, lidY - 6, 13, 4), 2),
      const Color(0xff161616),
      const Color(0xff161616),
    );
  }

  void _bag(Canvas c) {
    final close = p(.27, .76);
    if (!foreground) {
      // Upright open bag with visible gussets and real handles.
      _surface(
        c,
        _polygon([
          const Offset(82, 101),
          const Offset(230, 101),
          const Offset(244, 261),
          const Offset(75, 261),
        ]),
        _paper,
        _paperDark,
        shadow: true,
      );
      _handle(c, const Rect.fromLTWH(127, 67, 65, 78), _paperDark, 9);
      _surface(
        c,
        _polygon([
          const Offset(83, 103),
          const Offset(231, 103),
          const Offset(215, 130),
          const Offset(101, 130),
        ]),
        const Color(0xffa38459),
        const Color(0xff705a3c),
      );
      return;
    }
    final frontY = ui.lerpDouble(248, 126, close)!;
    _surface(
      c,
      _polygon([
        Offset(91, frontY),
        Offset(224, frontY),
        const Offset(244, 261),
        const Offset(75, 261),
      ]),
      _paperLight,
      _paper,
      shadow: true,
    );
    _surface(
      c,
      _polygon([
        const Offset(231, 103),
        Offset(224, frontY),
        const Offset(244, 261),
        const Offset(254, 244),
      ]),
      _paperDark,
      const Color(0xffae8b5b),
    );
    if (close > .96) {
      _handle(c, const Rect.fromLTWH(129, 86, 60, 62), _paperDark, 7);
      _line(c, const Offset(98, 141), const Offset(218, 141), _seam);
      _line(c, const Offset(89, 249), const Offset(231, 249), _seam);
      _print(c, const Rect.fromLTWH(100, 156, 118, 88), p(.75, .9));
    }
    _fold(
      c,
      [
        const Offset(91, 126),
        const Offset(224, 126),
        const Offset(232, 107),
        const Offset(83, 107),
      ],
      [
        const Offset(91, 126),
        const Offset(224, 126),
        const Offset(214, 148),
        const Offset(101, 148),
      ],
      p(.75, .93),
      _paperLight,
      _paperDark,
    );
    if (t > .8) {
      _surface(
        c,
        _rounded(Rect.fromLTWH(151, 125, 18, 38 * p(.8, .96)), 2),
        _gold,
        const Color(0xffc9a251),
      );
    }
  }

  static void _handle(Canvas c, Rect bounds, Color color, double width) {
    c.drawPath(
      Path()
        ..moveTo(bounds.left, bounds.bottom)
        ..lineTo(bounds.left, bounds.center.dy)
        ..cubicTo(
          bounds.left,
          bounds.top,
          bounds.right,
          bounds.top,
          bounds.right,
          bounds.center.dy,
        )
        ..lineTo(bounds.right, bounds.bottom),
      Paint()
        ..color = color
        ..strokeWidth = width
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  static void _print(Canvas c, Rect bounds, double opacity) {
    final paint = Paint()
      ..color = const Color(0xff80674c).withValues(alpha: .16 * opacity)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    c.save();
    c.clipRect(bounds);
    // A quiet repeating smile pattern printed into the paper, not new food art.
    for (double y = bounds.top + 6; y < bounds.bottom; y += 25) {
      for (double x = bounds.left + 2; x < bounds.right; x += 28) {
        c.drawArc(Rect.fromLTWH(x, y, 12, 10), .1, math.pi - .2, false, paint);
      }
    }
    c.restore();
  }

  static Path _polygon(List<Offset> vertices) =>
      Path()..addPolygon(vertices, true);

  static Path _rounded(Rect rect, double radius) =>
      Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

  // Two retained fibre paths provide paper grain without an image dependency,
  // random work during a frame, or hundreds of individual draw calls.
  static final ui.Picture _paperGrain = _makePaperGrain();

  static ui.Picture _makePaperGrain() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final dark = Path();
    final light = Path();
    for (var i = 0; i < 660; i++) {
      final x = ((i * 73 + 19) % 319).toDouble();
      final y = ((i * 47 + i * i * 3 + 11) % 317).toDouble();
      final target = i.isEven ? dark : light;
      target
        ..moveTo(x, y)
        ..lineTo(x + 1.2 + i % 4, y + (i % 3 - 1) * .55);
    }
    canvas.drawPath(
      dark,
      Paint()
        ..color = const Color(0x11795c37)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .65,
    );
    canvas.drawPath(
      light,
      Paint()
        ..color = const Color(0x19fff7df)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .6,
    );
    return recorder.endRecording();
  }

  static void _volume(Canvas c, Path path, double amount) {
    final bounds = path.getBounds();
    c.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(
          bounds.centerLeft,
          bounds.centerRight,
          [
            Colors.black.withValues(alpha: .17 * amount),
            Colors.white.withValues(alpha: .11 * amount),
            Colors.transparent,
            Colors.black.withValues(alpha: .20 * amount),
          ],
          [0, .22, .56, 1],
        ),
    );
    c.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(
          bounds.topCenter,
          bounds.bottomCenter,
          [
            Colors.white.withValues(alpha: .09 * amount),
            Colors.transparent,
            Colors.black.withValues(alpha: .16 * amount),
          ],
          [0, .18, 1],
        ),
    );
  }

  static void _crease(Canvas c, Offset start, Offset end, double amount) {
    _line(
      c,
      start + const Offset(.5, 1),
      end + const Offset(.5, 1),
      Colors.white.withValues(alpha: .26 * amount),
    );
    _line(
      c,
      start,
      end,
      const Color(0xff59432b).withValues(alpha: .29 * amount),
    );
  }

  static void _wrinkle(Canvas c, Offset start, Offset end, double amount) {
    final middle = Offset.lerp(start, end, .45)! + const Offset(3, -1.5);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(middle.dx, middle.dy, end.dx, end.dy);
    c.drawPath(
      path.shift(const Offset(.8, .7)),
      Paint()
        ..color = Colors.white.withValues(alpha: .16 * amount)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .75,
    );
    c.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: .23 * amount)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .75,
    );
  }

  static void _surface(
    Canvas c,
    Path path,
    Color light,
    Color dark, {
    bool shadow = false,
  }) {
    if (shadow) c.drawShadow(path, const Color(0x50000000), 4, false);
    final bounds = path.getBounds();
    c.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(
          bounds.topLeft,
          bounds.bottomRight,
          [
            Color.lerp(light, Colors.white, .055)!,
            light,
            Color.lerp(light, dark, .68)!,
            dark,
          ],
          [0, .17, .72, 1],
        ),
    );
    c.save();
    c.clipPath(path);
    c.drawPicture(_paperGrain);
    c.drawPath(
      path.shift(const Offset(.7, 1)),
      Paint()
        ..color = const Color(0x32fff8e6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );
    c.restore();
    c.drawPath(
      path,
      Paint()
        ..color = Color.lerp(dark, Colors.black, .14)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8
        ..strokeJoin = StrokeJoin.round,
    );
  }

  static void _line(Canvas c, Offset start, Offset end, Color color) =>
      c.drawLine(
        start,
        end,
        Paint()
          ..color = color
          ..strokeWidth = 1.1
          ..strokeCap = StrokeCap.round,
      );

  static void _fold(
    Canvas c,
    List<Offset> opened,
    List<Offset> closed,
    double amount,
    Color light,
    Color dark,
  ) {
    // A lifted flap follows a half rotation about its unmoving hinge. The
    // projected height avoids a paper sheet shrinking through a flat line.
    final turn = (1 - math.cos(math.pi * amount)) / 2;
    final lift = math.sin(math.pi * amount);
    final hingePoints = <Offset>[
      for (var i = 0; i < opened.length; i++)
        if ((opened[i] - closed[i]).distanceSquared < .01) opened[i],
    ];
    final hinge = hingePoints.isEmpty ? opened.first : hingePoints.first;
    final vertices = List<Offset>.generate(opened.length, (i) {
      final travel = (closed[i] - opened[i]).distance;
      final height = math.min(38.0, travel * .24) * lift;
      final plane = Offset.lerp(opened[i], closed[i], turn)!;
      return Offset(
        plane.dx + (plane.dx - hinge.dx) * height / 950,
        plane.dy - height,
      );
    });
    final path = _polygon(vertices);
    if (amount > .015) {
      c.save();
      c.translate(1 + lift * 3, 1.1 + lift * 10);
      c.drawPath(
        path,
        Paint()
          ..color = Color.fromRGBO(25, 18, 10, .12 + .10 * lift)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, .9 + lift * 3.4),
      );
      c.restore();
    }
    _surface(
      c,
      path,
      Color.lerp(light, Colors.white, lift * .075)!,
      Color.lerp(dark, Colors.black, lift * .10)!,
    );
    if (hingePoints.length > 1) {
      _crease(c, hingePoints.first, hingePoints.last, .6 + lift * .4);
    }
  }

  @override
  bool shouldRepaint(_PackagingPainter oldDelegate) =>
      oldDelegate.geometry.t != t ||
      oldDelegate.geometry.kind != geometry.kind ||
      oldDelegate.foreground != foreground;
}
