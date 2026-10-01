import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:enjoy_lavash_mobile/widgets/cart_animation/packaging_visual.dart';
import 'package:enjoy_lavash_mobile/widgets/cart_animation/preset_packaging_visual.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phone-resolution packaging close-ups for visual review.
///
/// Pass `--dart-define=PACKAGING_CLOSEUP_DIR=/absolute/dir` to write, for
/// every package, `<kind>_detail.png` (mid-fold and closed side by side at 3x,
/// the pixel density of a modern phone) and `<kind>_strip.png` (five stages,
/// the last on the dark app ground, at half size). Without the define the test
/// is a smoke check that every stage composes without exceptions.
void main() {
  const outDir = String.fromEnvironment('PACKAGING_CLOSEUP_DIR');
  const kinds = [
    CartPackagingKind.pizza,
    CartPackagingKind.burger,
    CartPackagingKind.lavash,
    CartPackagingKind.hotDog,
    CartPackagingKind.fries,
    CartPackagingKind.cup,
    CartPackagingKind.combo,
  ];
  const lightGround = Color(0xfff6f3ec);
  const darkGround = Color(0xff151312);
  const stages = <(double, Color)>[
    (.2, lightGround),
    (.45, lightGround),
    (.7, lightGround),
    (1, lightGround),
    (1, darkGround),
  ];
  const side = 360.0;
  const ratio = 3.0;

  testWidgets('packaging close-ups render every stage', (tester) async {
    tester.view.physicalSize = const Size(side * ratio, side * ratio);
    tester.view.devicePixelRatio = ratio;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await PresetPackagingVisual.prepareMaterials();
      final font = FontLoader('Manrope')
        ..addFont(rootBundle.load('assets/fonts/Manrope-Variable.ttf'));
      await font.load();
    });
    if (outDir.isNotEmpty) Directory(outDir).createSync(recursive: true);

    var logoReady = false;
    for (final kind in kinds) {
      final frames = <ui.Image>[];
      for (final (progress, ground) in stages) {
        final boundary = GlobalKey();
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: RepaintBoundary(
              key: boundary,
              child: ColoredBox(
                color: ground,
                child: Center(
                  child: SizedBox.square(
                    dimension: side,
                    child: PresetPackagingVisual(
                      kind: kind,
                      progress: progress,
                      productSize: const Size(190, 110),
                      product: const _FoodPhoto(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        if (!logoReady) {
          await tester.runAsync(
            () => precacheImage(
              const ResizeImage(
                AssetImage('assets/images/enjoy-logo.png'),
                width: 144,
              ),
              tester.element(find.byType(PresetPackagingVisual)),
            ),
          );
          logoReady = true;
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (outDir.isEmpty) continue;
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        frames.add(
          (await tester.runAsync(() => render.toImage(pixelRatio: ratio)))!,
        );
      }
      if (outDir.isEmpty) continue;
      final full = side * ratio;
      // Mid-fold and closed, both at true phone pixel density.
      await _writeSheet(
        tester,
        '$outDir/${kind.name}_detail.png',
        [(frames[1], 'progress 0.45'), (frames[3], 'progress 1.0 (closed)')],
        '${kind.name} — 3x phone resolution',
        full,
      );
      await _writeSheet(
        tester,
        '$outDir/${kind.name}_strip.png',
        [
          for (var i = 0; i < stages.length; i++)
            (
              frames[i],
              'p ${stages[i].$1}${stages[i].$2 == darkGround ? ' dark' : ''}',
            ),
        ],
        '${kind.name} — all stages, half size',
        full / 2,
      );
      for (final frame in frames) {
        frame.dispose();
      }
    }
  });
}

Future<void> _writeSheet(
  WidgetTester tester,
  String path,
  List<(ui.Image, String)> frames,
  String title,
  double cell,
) async {
  const gap = 12.0;
  const header = 56.0;
  const caption = 40.0;
  final width = frames.length * cell + (frames.length + 1) * gap;
  final height = header + caption + cell + gap;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..drawColor(const Color(0xff2b2b2b), BlendMode.src);
  _label(canvas, title, const Offset(gap, 12), 28);
  for (var i = 0; i < frames.length; i++) {
    final (image, text) = frames[i];
    final left = gap + i * (cell + gap);
    _label(canvas, text, Offset(left, header), 22);
    canvas.drawImageRect(
      image,
      Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(left, header + caption, cell, cell),
      Paint()..filterQuality = FilterQuality.high,
    );
  }
  final picture = recorder.endRecording();
  final image = (await tester.runAsync(
    () => picture.toImage(width.round(), height.round()),
  ))!;
  final bytes = (await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.png),
  ))!;
  await tester.runAsync(
    () => File(path).writeAsBytes(bytes.buffer.asUint8List()),
  );
  image.dispose();
  picture.dispose();
}

void _label(Canvas canvas, String text, Offset offset, double size) {
  (TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'Manrope',
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout()).paint(canvas, offset);
}

/// Stand-in for a catalog photograph: a dish on a wooden board, lit from the
/// upper left, with deterministic toppings so every render is identical.
class _FoodPhoto extends StatelessWidget {
  const _FoodPhoto();

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(painter: _FoodPhotoPainter(), size: Size(190, 110));
}

class _FoodPhotoPainter extends CustomPainter {
  const _FoodPhotoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(10)),
      Paint()
        ..shader = ui.Gradient.linear(
          bounds.topLeft,
          bounds.bottomRight,
          const [Color(0xffc8925a), Color(0xff8a5a32)],
        ),
    );
    for (var i = 0; i < 9; i++) {
      final y = 6.0 + i * 12;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + 3),
        Paint()
          ..color = const Color(0x22301a08)
          ..strokeWidth = 1.2,
      );
    }
    final center = Offset(size.width / 2, size.height / 2 + 2);
    final radius = size.height * .42;
    canvas.drawCircle(
      center + const Offset(3, 5),
      radius,
      Paint()
        ..color = const Color(0x66301a08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = ui.Gradient.radial(
          center - Offset(radius * .3, radius * .35),
          radius * 1.2,
          const [Color(0xfff4c56a), Color(0xffd9822e), Color(0xffa8501c)],
          const [0, .62, 1],
        ),
    );
    final random = math.Random(7);
    for (var i = 0; i < 26; i++) {
      final angle = random.nextDouble() * math.pi * 2;
      final distance = math.sqrt(random.nextDouble()) * radius * .78;
      final at = center + Offset(math.cos(angle), math.sin(angle)) * distance;
      canvas.drawCircle(
        at,
        2.2 + random.nextDouble() * 3,
        Paint()
          ..color = i.isEven
              ? const Color(0xffb4321e)
              : const Color(0xff4f7a2a),
      );
    }
  }

  @override
  bool shouldRepaint(_FoodPhotoPainter oldDelegate) => false;
}
