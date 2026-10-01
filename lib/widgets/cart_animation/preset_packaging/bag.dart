part of '../preset_packaging_visual.dart';

extension _BagPackaging on _PackagingPainter {
  void _bag(Canvas c) {
    final close = p(.27, .76);
    if (!foreground) {
      // Upright open bag with visible gussets and real handles.
      final body = _polygon([
        const Offset(82, 101),
        const Offset(230, 101),
        const Offset(244, 261),
        const Offset(75, 261),
      ]);
      _surface(c, body, _paper, _paperDark, shadow: true);
      _cylinder(c, body, strength: .4);
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
    final front = _polygon([
      Offset(91, frontY),
      Offset(224, frontY),
      const Offset(244, 261),
      const Offset(75, 261),
    ]);
    _surface(c, front, _paperLight, _paper, shadow: true);
    _cylinder(c, front, strength: .45);
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
}
