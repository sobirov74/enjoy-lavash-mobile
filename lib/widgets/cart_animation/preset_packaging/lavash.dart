part of '../preset_packaging_visual.dart';

extension _LavashPackaging on _PackagingPainter {
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
}
