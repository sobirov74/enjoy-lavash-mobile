part of '../preset_packaging_visual.dart';

extension _FriesPackaging on _PackagingPainter {
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
    _surface(c, path, _inkLight, _ink, shadow: true, gloss: .22);
    _cylinder(c, path, strength: .55);
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
}
