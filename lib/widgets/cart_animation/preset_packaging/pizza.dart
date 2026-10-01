part of '../preset_packaging_visual.dart';

extension _PizzaPackaging on _PackagingPainter {
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
        // A raised lid shows its unprinted inner face, paler than the outside.
        _surface(
          c,
          lid,
          const Color(0xfffff4dc),
          _paperLight,
          shadow: true,
          shade: 1.02,
          grain: .6,
        );
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
        shade: .88,
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
      shade: 1.06,
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
      shade: .9,
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
      // The outer face flattens toward the light as the lid comes down.
      _surface(c, lid, _paperLight, _paper, shade: .9 + .16 * math.cos(angle));
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
}
