part of '../preset_packaging_visual.dart';

extension _BurgerPackaging on _PackagingPainter {
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
        gloss: .3,
      );
      _surface(
        c,
        _rounded(const Rect.fromLTWH(78, 100, 164, 140), 15),
        _inkLight,
        _ink,
        gloss: .3,
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
      gloss: .32,
    );
    _fold(
      c,
      [const Offset(80, 106), const Offset(17, 159), const Offset(80, 235)],
      [const Offset(80, 106), const Offset(185, 161), const Offset(80, 235)],
      p(.2, .46),
      _inkLight,
      _ink,
      gloss: .32,
    );
    _fold(
      c,
      [const Offset(240, 106), const Offset(302, 162), const Offset(240, 235)],
      [const Offset(240, 106), const Offset(135, 164), const Offset(240, 235)],
      p(.35, .62),
      const Color(0xff49473f),
      _ink,
      gloss: .32,
    );
    _fold(
      c,
      [const Offset(80, 104), const Offset(160, 27), const Offset(240, 104)],
      [const Offset(80, 104), const Offset(160, 211), const Offset(240, 104)],
      p(.57, .86),
      const Color(0xff3a3935),
      const Color(0xff222222),
      gloss: .32,
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
}
