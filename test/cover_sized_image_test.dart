import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:enjoy_lavash_mobile/widgets/utils/cover_sized_image.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('coverTargetSize', () {
    test('a landscape photo in a square box keeps its shape', () {
      final size = coverTargetSize(1600, 900, 160, 160);
      expect(size.width, isNull);
      expect(size.height, 160);
    });

    test('a square photo in a wide box is decoded as wide as the box', () {
      final size = coverTargetSize(1000, 1000, 480, 320);
      expect(size.width, 480);
      expect(size.height, isNull);
    });

    test('a square photo in a tall box is decoded as tall as the box', () {
      final size = coverTargetSize(1000, 1000, 320, 480);
      expect(size.width, isNull);
      expect(size.height, 480);
    });

    test('a portrait photo in a wide box binds on the width', () {
      final size = coverTargetSize(600, 900, 480, 320);
      expect(size.width, 480);
      expect(size.height, isNull);
    });

    test('a photo smaller than the box is never upscaled', () {
      final size = coverTargetSize(200, 150, 480, 320);
      expect(size.width, isNull);
      expect(size.height, isNull);
    });
  });

  group('coverDecodeExtent', () {
    test('rounds physical pixels up to the size step', () {
      expect(coverDecodeExtent(52, 3), 160); // 156 → 160
      expect(coverDecodeExtent(106, 2), 224); // 212 → 224
      expect(coverDecodeExtent(16, 1), 16);
    });

    test('caps the device pixel ratio', () {
      expect(coverDecodeExtent(100, 4), coverDecodeExtent(100, 3));
    });
  });

  test('the cache key is the wrapped key and the box', () async {
    final bytes = Uint8List.fromList(<int>[1, 2, 3]);
    final first = CoverSizedImage(MemoryImage(bytes), width: 160, height: 96);
    final same = CoverSizedImage(MemoryImage(bytes), width: 160, height: 96);
    final larger = CoverSizedImage(MemoryImage(bytes), width: 320, height: 96);

    final firstKey = await first.obtainKey(ImageConfiguration.empty);
    expect(await same.obtainKey(ImageConfiguration.empty), firstKey);
    expect(await larger.obtainKey(ImageConfiguration.empty), isNot(firstKey));
    expect(first, same);
  });

  testWidgets('decodes a wide photo to cover a square box, unsquashed', (
    tester,
  ) async {
    final decoded = await tester.runAsync(() async {
      final bytes = await _png(400, 200);
      return _decode(
        CoverSizedImage(MemoryImage(bytes), width: 100, height: 100),
      );
    });

    expect(decoded!.width, 200);
    expect(decoded.height, 100);
  });

  testWidgets('decodes a small photo at its own size', (tester) async {
    final decoded = await tester.runAsync(() async {
      final bytes = await _png(120, 80);
      return _decode(
        CoverSizedImage(MemoryImage(bytes), width: 480, height: 320),
      );
    });

    expect(decoded!.width, 120);
    expect(decoded.height, 80);
  });
}

Future<Uint8List> _png(int width, int height) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = const Color(0xFFE5793B),
  );
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

Future<ui.Image> _decode(ImageProvider<Object> provider) {
  final completer = Completer<ui.Image>();
  provider
      .resolve(ImageConfiguration.empty)
      .addListener(
        ImageStreamListener(
          (info, _) => completer.complete(info.image),
          onError: completer.completeError,
        ),
      );
  return completer.future;
}
