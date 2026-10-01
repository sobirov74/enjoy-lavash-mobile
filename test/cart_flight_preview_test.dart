import 'dart:io';
import 'dart:ui' as ui;

import 'package:enjoy_lavash_mobile/widgets/cart_animation/cart_animation_controller.dart';
import 'package:enjoy_lavash_mobile/widgets/cart_animation/cart_animation_source.dart';
import 'package:enjoy_lavash_mobile/widgets/cart_animation/packaging_visual.dart';
import 'package:enjoy_lavash_mobile/widgets/cart_animation/preset_packaging_visual.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders the complete built-in add-to-cart sequence on a phone-sized
/// surface. Pass `--dart-define=CART_FLIGHT_PREVIEW_PATH=/path/sheet.png` to
/// save one row of frames per package for visual review; without it the test
/// is a smoke check that every phase composes without exceptions.
void main() {
  testWidgets('built-in flight composes every phase for each package', (
    tester,
  ) async {
    const previewPath = String.fromEnvironment('CART_FLIGHT_PREVIEW_PATH');
    const kinds = [
      CartPackagingKind.pizza,
      CartPackagingKind.burger,
      CartPackagingKind.lavash,
      CartPackagingKind.cup,
      CartPackagingKind.combo,
    ];
    const samples = [0.0, .1, .22, .36, .5, .6, .66, .72, .78, .84, .9, .96];
    const frame = Size(390, 780);
    tester.view.physicalSize = frame;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.runAsync(PresetPackagingVisual.prepareMaterials);
    final recorder = previewPath.isEmpty ? null : ui.PictureRecorder();
    final canvas = recorder == null ? null : Canvas(recorder);
    canvas?.drawColor(const Color(0xff2b2b2b), BlendMode.src);

    for (var row = 0; row < kinds.length; row++) {
      final kind = kinds[row];
      final rootKey = GlobalKey();
      final anchorKey = GlobalKey<CartAnimationAnchorState>();
      final cartKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: rootKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            home: _Scene(anchorKey: anchorKey, cartKey: cartKey),
          ),
        ),
      );
      await tester.runAsync(
        () => precacheImage(
          const ResizeImage(
            AssetImage('assets/images/enjoy-logo.png'),
            width: 144,
          ),
          tester.element(find.byType(_Scene)),
        ),
      );
      await tester.pump();
      final controller = CartAnimationController();
      addTearDown(controller.dispose);
      var confirmations = 0;
      await controller.add(
        context: tester.element(find.byType(_Scene)),
        source: anchorKey.currentState!.capture(),
        packagingKind: kind,
        operation: () {},
        destination: () => cartAnimationBounds(cartKey),
        onConfirmed: () => confirmations++,
        onFailed: (_, _) => fail('Unexpected failure.'),
      );
      await tester.pump();
      await tester.pump();

      var elapsed = Duration.zero;
      for (var column = 0; column < samples.length; column++) {
        final at = controller.duration * samples[column];
        await tester.pump(at - elapsed);
        elapsed = at;
        expect(find.byType(PresetPackagingVisual), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (canvas == null) continue;
        final render =
            rootKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = (await tester.runAsync(() => render.toImage()))!;
        final offset = Offset(
          column * (frame.width + 8),
          row * (frame.height + 30),
        );
        canvas.drawImage(image, offset + const Offset(0, 26), Paint());
        final label = TextPainter(
          text: TextSpan(
            text: '${kind.name}  t=${samples[column]}',
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        label.paint(canvas, offset + const Offset(4, 4));
        image.dispose();
      }
      await tester.pumpAndSettle();
      expect(confirmations, 1);
      expect(find.byType(PresetPackagingVisual), findsNothing);
      expect(tester.takeException(), isNull);
    }

    if (recorder != null) {
      final picture = recorder.endRecording();
      final width = (samples.length * (frame.width + 8)).round();
      final height = (kinds.length * (frame.height + 30)).round();
      final image = (await tester.runAsync(
        () => picture.toImage(width, height),
      ))!;
      final bytes = (await tester.runAsync(
        () => image.toByteData(format: ui.ImageByteFormat.png),
      ))!;
      await tester.runAsync(() async {
        await File(previewPath).writeAsBytes(bytes.buffer.asUint8List());
      });
      image.dispose();
      picture.dispose();
    }
  });
}

/// A menu-like page: a product tile near the top, a cart tab at the bottom.
class _Scene extends StatelessWidget {
  const _Scene({required this.anchorKey, required this.cartKey});

  final GlobalKey<CartAnimationAnchorState> anchorKey;
  final GlobalKey cartKey;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xfff6f3ec),
    body: Stack(
      children: [
        for (var i = 0; i < 4; i++)
          Positioned(
            left: 20 + (i % 2) * 180,
            top: 90 + (i ~/ 2) * 220,
            width: 170,
            height: 200,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 106,
                      child: i == 0
                          ? CartAnimationAnchor(
                              key: anchorKey,
                              child: const _FakePhoto(),
                            )
                          : const _FakePhoto(muted: true),
                    ),
                    const SizedBox(height: 8),
                    Container(height: 12, color: const Color(0xffe4e0d8)),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 80,
                      color: const Color(0xffeeebe4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 72,
          child: ColoredBox(
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const Icon(Icons.home_outlined, color: Colors.black38),
                const Icon(Icons.menu_book_outlined, color: Colors.black38),
                const Icon(Icons.local_offer_outlined, color: Colors.black38),
                SizedBox(
                  key: cartKey,
                  width: 24,
                  height: 24,
                  child: const Icon(Icons.shopping_bag_outlined),
                ),
                const Icon(Icons.person_outline, color: Colors.black38),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

/// Stand-in for a catalog photo: a warm plate with a round dish on it.
class _FakePhoto extends StatelessWidget {
  const _FakePhoto({this.muted = false});

  final bool muted;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(11),
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: muted
              ? const [Color(0xffe9e2d3), Color(0xffd9d0bd)]
              : const [Color(0xfff2d9b1), Color(0xffd8a86b)],
        ),
      ),
      child: Center(
        child: Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: muted
                  ? const [Color(0xffcfc6b3), Color(0xffb8ad97)]
                  : const [Color(0xfff2b347), Color(0xffc0392b)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
