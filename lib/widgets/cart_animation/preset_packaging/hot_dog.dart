part of '../preset_packaging_visual.dart';

extension _HotDogPackaging on _PackagingPainter {
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
      gloss: .3,
    );
    if (t > .83) {
      _line(c, const Offset(119, 213), const Offset(201, 213), _gold);
    }
  }
}
