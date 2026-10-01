part of '../preset_packaging_visual.dart';

// Shared palette, light and material primitives for every built-in package.

const _paper = Color(0xfff0dfbd);
const _paperLight = Color(0xfffff0d3);
const _paperDark = Color(0xffcaa979);
const _ink = Color(0xff292828);
const _inkLight = Color(0xff41403c);
const _seam = Color(0xffb29469);
const _gold = Color(0xffe7bb58);

void _handle(Canvas c, Rect bounds, Color color, double width) {
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

void _print(Canvas c, Rect bounds, double opacity) {
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

Path _polygon(List<Offset> vertices) => Path()..addPolygon(vertices, true);

Path _rounded(Rect rect, double radius) =>
    Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

/// Screen-space direction toward the single key light: upper left, slightly
/// in front of the package. Face shading, fold tilt, sheen and every cast
/// shadow derive from this one light so the parcel reads as one solid object.
const Offset _lightDirection = Offset(-.6, -.8);

/// Paper fibre tile rasterised once. Mid grey is neutral under overlay
/// blending, so only its deviations lighten or darken the paper colour.
final ui.Image _grainTile = _makeGrainTile();

final Float64List _grainMatrix = Matrix4.diagonal3Values(.85, .85, 1).storage;

ui.Image _makeGrainTile() {
  const size = 96;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..drawColor(const Color(0xff808080), BlendMode.src);
  var seed = 0x2f6e2b1;
  int next() => seed = (seed * 1103515245 + 12345) & 0x7fffffff;
  // Nine grey levels drawn as point batches keep the one-time cost tiny.
  final buckets = List.generate(9, (_) => <Offset>[]);
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      buckets[(next() >> 12) % 9].add(Offset(x + .5, y + .5));
    }
  }
  for (var i = 0; i < buckets.length; i++) {
    final value = 104 + i * 6;
    canvas.drawPoints(
      ui.PointMode.points,
      buckets[i],
      Paint()
        ..color = Color.fromARGB(255, value, value, value)
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.square,
    );
  }
  // Sparse fibre flecks, as in unbleached kraft stock.
  for (var i = 0; i < 150; i++) {
    final x = (next() % size).toDouble();
    final y = (next() % size).toDouble();
    final length = 1.5 + next() % 4;
    final dark = next().isEven;
    canvas.drawLine(
      Offset(x, y),
      Offset(x + length, y + (next() % 3 - 1) * .5),
      Paint()
        ..color = dark ? const Color(0xff606060) : const Color(0xffa8a8a8)
        ..strokeWidth = .7,
    );
  }
  return recorder.endRecording().toImageSync(size, size);
}

void _volume(Canvas c, Path path, double amount) {
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

/// Rounds a panel: dark turning edges, a highlight band toward the light and
/// a deeper shadow on the far side, as on a cup, sleeve or bulging bag front.
void _cylinder(
  Canvas c,
  Path path, {
  double strength = 1,
  double highlight = .3,
}) {
  final bounds = path.getBounds();
  c.drawPath(
    path,
    Paint()
      ..shader = ui.Gradient.linear(
        bounds.centerLeft,
        bounds.centerRight,
        [
          Colors.black.withValues(alpha: .26 * strength),
          Colors.black.withValues(alpha: .04 * strength),
          Colors.white.withValues(alpha: .16 * strength),
          Colors.transparent,
          Colors.black.withValues(alpha: .10 * strength),
          Colors.black.withValues(alpha: .34 * strength),
        ],
        [0, highlight - .16, highlight, highlight + .18, .8, 1],
      ),
  );
}

void _crease(Canvas c, Offset start, Offset end, double amount) {
  _line(
    c,
    start + const Offset(.5, 1),
    end + const Offset(.5, 1),
    Colors.white.withValues(alpha: .26 * amount),
  );
  _line(c, start, end, const Color(0xff59432b).withValues(alpha: .29 * amount));
}

void _wrinkle(Canvas c, Offset start, Offset end, double amount) {
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

/// Multiplies a material colour by how squarely its face meets the light.
Color _shade(Color color, double shade) => shade >= 1
    ? Color.lerp(
        color,
        const Color(0xfffff8e8),
        ((shade - 1) * 1.4).clamp(0.0, 1.0),
      )!
    : Color.lerp(
        color,
        const Color(0xff1a1208),
        ((1 - shade) * 1.1).clamp(0.0, 1.0),
      )!;

/// One lit material face. There is no drawn outline: the edge is defined by
/// shading contrast, soft ambient occlusion and a lit paper edge, the way a
/// photographed parcel is. [shade] tilts the face toward (>1) or away (<1)
/// from the light; [gloss] raises the sheen for waxed or plastic surfaces.
void _surface(
  Canvas c,
  Path path,
  Color light,
  Color dark, {
  bool shadow = false,
  double shade = 1,
  double gloss = .1,
  double grain = 1,
}) {
  if (shadow) c.drawShadow(path, const Color(0x662a1a08), 5, false);
  final bounds = path.getBounds();
  final lit = _shade(light, shade);
  final dim = _shade(dark, shade);
  c.drawPath(
    path,
    Paint()
      ..shader = ui.Gradient.linear(
        bounds.topLeft,
        bounds.bottomRight,
        [
          Color.lerp(lit, Colors.white, .07)!,
          lit,
          Color.lerp(lit, dim, .62)!,
          dim,
        ],
        const [0, .2, .74, 1],
      ),
  );
  c.save();
  c.clipPath(path);
  if (grain > 0) {
    c.drawRect(
      bounds,
      Paint()
        ..shader = ui.ImageShader(
          _grainTile,
          TileMode.repeated,
          TileMode.repeated,
          _grainMatrix,
          filterQuality: FilterQuality.low,
        )
        ..blendMode = BlendMode.overlay
        ..color = Colors.white.withValues(alpha: .6 * grain),
    );
  }
  // Broad sheen where the face turns toward the light.
  final sheenCenter =
      bounds.center +
      Offset(
        _lightDirection.dx * bounds.width * .32,
        _lightDirection.dy * bounds.height * .32,
      );
  c.drawRect(
    bounds,
    Paint()
      ..shader = ui.Gradient.radial(sheenCenter, bounds.longestSide * .62, [
        Colors.white.withValues(alpha: .07 + .18 * gloss),
        Colors.transparent,
      ]),
  );
  // Ambient occlusion: edges recede softly instead of being inked.
  for (final (width, alpha) in const [(4.5, .045), (2.6, .06), (1.2, .09)]) {
    c.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 2
        ..strokeJoin = StrokeJoin.round,
    );
  }
  // Lit paper edge along the sides facing the light.
  c.drawPath(
    path.shift(const Offset(.8, 1.1)),
    Paint()
      ..color = const Color(0x46fff6e0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2,
  );
  c.restore();
  // A faint seam keeps abutting folds from opening hairline gaps.
  c.drawPath(
    path,
    Paint()
      ..color = Color.lerp(dim, Colors.black, .3)!.withValues(alpha: .28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .6
      ..strokeJoin = StrokeJoin.round,
  );
}

void _line(Canvas c, Offset start, Offset end, Color color) => c.drawLine(
  start,
  end,
  Paint()
    ..color = color
    ..strokeWidth = 1.1
    ..strokeCap = StrokeCap.round,
);

void _fold(
  Canvas c,
  List<Offset> opened,
  List<Offset> closed,
  double amount,
  Color light,
  Color dark, {
  double gloss = .1,
}) {
  // A lifted flap follows a half rotation about its unmoving hinge. The
  // projected height avoids a paper sheet shrinking through a flat line.
  final turn = (1 - math.cos(math.pi * amount)) / 2;
  final lift = math.sin(math.pi * amount);
  final hingePoints = <Offset>[
    for (var i = 0; i < opened.length; i++)
      if ((opened[i] - closed[i]).distanceSquared < .01) opened[i],
  ];
  final hinge = hingePoints.isEmpty ? opened.first : hingePoints.first;
  // The direction a flap extends from its hinge decides whether its face
  // tilts toward the light or away from it while it stands up mid-fold.
  var centroid = Offset.zero;
  for (final vertex in opened) {
    centroid += vertex / opened.length.toDouble();
  }
  final extend = centroid - hinge;
  final facing = extend.distance < .01
      ? 0.0
      : -(extend.dx * _lightDirection.dx + extend.dy * _lightDirection.dy) /
            extend.distance;
  final shade = ui.lerpDouble(1, .78 + .34 * (facing + 1) / 2, lift)!;
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
    // The cast shadow falls away from the light and softens with height.
    c.save();
    c.translate(
      -_lightDirection.dx * (1.5 + lift * 5),
      -_lightDirection.dy * (1.5 + lift * 11),
    );
    c.drawPath(
      path,
      Paint()
        ..color = Color.fromRGBO(25, 18, 10, .13 + .12 * lift)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1 + lift * 4),
    );
    c.restore();
  }
  _surface(c, path, light, dark, shade: shade, gloss: gloss);
  if (hingePoints.length > 1) {
    _crease(c, hingePoints.first, hingePoints.last, .6 + lift * .4);
  }
}
