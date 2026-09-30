import 'dart:io';
import 'dart:ui' as ui;

import 'package:enjoy_lavash_mobile/widgets/cart_animation/packaging_visual.dart';
import 'package:enjoy_lavash_mobile/widgets/cart_animation/preset_packaging_visual.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<ui.Image> frame(
    WidgetTester tester,
    CartPackagingKind kind,
    double progress, {
    Size productSize = const Size(190, 110),
  }) async {
    final boundary = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RepaintBoundary(
            key: boundary,
            child: SizedBox.square(
              dimension: 220,
              child: PresetPackagingVisual(
                kind: kind,
                progress: progress,
                productSize: productSize,
                // An unambiguous sentinel lets raster checks detect any photo
                // leaking outside the fully closed package.
                product: const ColoredBox(color: Color(0xffff00ff)),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => precacheImage(
        const ResizeImage(
          AssetImage('assets/images/enjoy-logo.png'),
          width: 144,
        ),
        tester.element(find.byType(PresetPackagingVisual)),
      ),
    );
    await tester.pumpAndSettle();
    final render =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final result = (await tester.runAsync(() => render.toImage()))!;
    expect(tester.takeException(), isNull);
    return result;
  }

  Future<int> productPixels(WidgetTester tester, ui.Image image) async {
    final bytes = (await tester.runAsync(() => image.toByteData()))!;
    var count = 0;
    for (var index = 0; index < bytes.lengthInBytes; index += 4) {
      if (bytes.getUint8(index) > 245 &&
          bytes.getUint8(index + 1) < 10 &&
          bytes.getUint8(index + 2) > 245 &&
          bytes.getUint8(index + 3) > 245) {
        count++;
      }
    }
    return count;
  }

  testWidgets(
    'every preset renders each preparation stage without external art',
    (tester) async {
      const previewPath = String.fromEnvironment('PACKAGING_PREVIEW_PATH');
      final recorder = previewPath.isEmpty ? null : ui.PictureRecorder();
      final canvas = recorder == null ? null : Canvas(recorder);
      const phases = [0.0, .25, .5, .75, 1.0];
      canvas?.drawColor(const Color(0xfff5f3ed), BlendMode.src);
      for (final kind in CartPackagingKind.values) {
        for (var index = 0; index < phases.length; index++) {
          final image = await frame(tester, kind, phases[index]);
          if (canvas != null) {
            final offset = Offset(index * 240, kind.index * 250);
            canvas.drawImage(image, offset + const Offset(10, 22), Paint());
            final label = TextPainter(
              text: TextSpan(
                text: '${kind.name}  ${(phases[index] * 100).round()}%',
                style: const TextStyle(fontSize: 15, color: Colors.black),
              ),
              textDirection: TextDirection.ltr,
            )..layout();
            label.paint(canvas, offset + const Offset(12, 6));
          }
          image.dispose();
        }
      }
      if (recorder != null) {
        final picture = recorder.endRecording();
        final image = (await tester.runAsync(
          () => picture.toImage(1200, CartPackagingKind.values.length * 250),
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
    },
  );

  for (final kind in [
    CartPackagingKind.pizza,
    CartPackagingKind.burger,
    CartPackagingKind.lavash,
    CartPackagingKind.cup,
    CartPackagingKind.combo,
    CartPackagingKind.none,
  ]) {
    testWidgets(
      '${kind.name} hides the actual photo inside the finished package',
      (tester) async {
        final opened = await frame(tester, kind, 0);
        expect(await productPixels(tester, opened), greaterThan(1000));
        opened.dispose();
        for (final progress in [.89, 1.0]) {
          final closed = await frame(tester, kind, progress);
          expect(await productPixels(tester, closed), 0);
          closed.dispose();
        }
      },
    );
  }

  testWidgets(
    'sealed bottles preserve the actual product throughout preparation',
    (tester) async {
      for (final progress in [0.0, .5, 1.0]) {
        final image = await frame(tester, CartPackagingKind.bottle, progress);
        expect(await productPixels(tester, image), greaterThan(1000));
        image.dispose();
      }
    },
  );

  testWidgets('folding keeps the supplied non-square product layout stable', (
    tester,
  ) async {
    const size = Size(200, 80);
    for (final progress in [0.0, .25, .6, 1.0]) {
      final image = await frame(
        tester,
        CartPackagingKind.burger,
        progress,
        productSize: size,
      );
      expect(tester.getSize(find.byType(ColoredBox).last), size);
      image.dispose();
    }
  });

  testWidgets('detail entrance preserves exact source bounds and one photo', (
    tester,
  ) async {
    const source = Rect.fromLTWH(-40, 60, 400, 200);
    const photoKey = ValueKey('detail-product-photo');
    const stageKey = ValueKey('detail-packaging-stage');
    Future<Rect> placement(double entrance) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.shrink(),
        ),
      );
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox.square(
              key: stageKey,
              dimension: 320,
              child: PresetPackagingVisual(
                kind: CartPackagingKind.pizza,
                progress: 0,
                entranceProgress: entrance,
                initialProductRect: source,
                productSize: const Size(200, 100),
                product: const ColoredBox(
                  key: photoKey,
                  color: Color(0xffff00ff),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byKey(photoKey), findsOneWidget);
      final photo = tester.renderObject<RenderBox>(find.byKey(photoKey));
      final stage = tester.renderObject<RenderBox>(find.byKey(stageKey));
      expect(photo.size, const Size(200, 100));
      return Rect.fromPoints(
        photo.localToGlobal(Offset.zero, ancestor: stage),
        photo.localToGlobal(
          photo.size.bottomRight(Offset.zero),
          ancestor: stage,
        ),
      );
    }

    expect(await placement(0), source);
    final resting = await placement(1);
    expect(resting.center.dx, closeTo(160, .001));
    expect(resting.center.dy, closeTo(171, .001));
    expect(resting.width, closeTo(188, .001));
    expect(resting.height, closeTo(94, .001));
    final between = await placement(.5);
    expect(between.width, greaterThan(resting.width));
    expect(between.width, lessThan(source.width));
    expect(tester.takeException(), isNull);
  });
}
