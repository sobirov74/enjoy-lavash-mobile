part of '../preset_packaging_visual.dart';

extension _CupPackaging on _PackagingPainter {
  void _cup(Canvas c) {
    const bodyTop = 103.0;
    if (!foreground) {
      final body = _polygon([
        const Offset(104, bodyTop),
        const Offset(216, bodyTop),
        const Offset(201, 259),
        const Offset(119, 259),
      ]);
      _surface(c, body, _inkLight, _ink, shadow: true, gloss: .25);
      _cylinder(c, body, strength: .7);
      _surface(
        c,
        Path()..addOval(const Rect.fromLTWH(104, 95, 112, 18)),
        const Color(0xff151515),
        const Color(0xff494338),
        grain: 0,
      );
      return;
    }
    final close = p(.18, .67);
    final frontY = ui.lerpDouble(259, bodyTop, close)!;
    final front = _polygon([
      Offset(ui.lerpDouble(119, 104, close)!, frontY),
      Offset(ui.lerpDouble(201, 216, close)!, frontY),
      const Offset(201, 259),
      const Offset(119, 259),
    ]);
    _surface(c, front, _inkLight, _ink, gloss: .25);
    _cylinder(c, front, strength: .7);
    final sleeve = p(.3, .72);
    final band = _polygon([
      Offset(110, ui.lerpDouble(228, 159, sleeve)!),
      Offset(210, ui.lerpDouble(228, 159, sleeve)!),
      const Offset(201, 228),
      const Offset(119, 228),
    ]);
    _surface(c, band, _paperLight, _paperDark);
    _cylinder(c, band, strength: .6);
    _line(
      c,
      const Offset(124, 251),
      const Offset(196, 251),
      const Color(0xff73684e),
    );
    // A moulded plastic lid: smooth, glossy and free of paper grain.
    final lidY = ui.lerpDouble(34, 86, p(.48, .88))!;
    _surface(
      c,
      _rounded(Rect.fromLTWH(91, lidY, 138, 20), 9),
      _inkLight,
      _ink,
      shadow: true,
      gloss: .55,
      grain: 0,
    );
    _cylinder(
      c,
      _rounded(Rect.fromLTWH(91, lidY, 138, 20), 9),
      strength: .5,
      highlight: .28,
    );
    _surface(
      c,
      _rounded(Rect.fromLTWH(99, lidY - 7, 122, 12), 5),
      const Color(0xff50504a),
      _ink,
      gloss: .65,
      grain: 0,
    );
    _line(
      c,
      Offset(109, lidY - 1),
      Offset(210, lidY - 1),
      const Color(0xff747367),
    );
    _line(
      c,
      Offset(108, lidY - 4),
      Offset(150, lidY - 4.5),
      Colors.white.withValues(alpha: .30),
    );
    _surface(
      c,
      _rounded(Rect.fromLTWH(189, lidY - 6, 13, 4), 2),
      const Color(0xff161616),
      const Color(0xff161616),
      grain: 0,
    );
  }
}
