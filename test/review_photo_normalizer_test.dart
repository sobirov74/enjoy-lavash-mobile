import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:enjoy_lavash_mobile/core/error/failures.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/features/order_review/data/order_review_limits.dart';
import 'package:enjoy_lavash_mobile/features/order_review/data/review_photo_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

/// The real normalizer, with only the platform encoder and the cache
/// directory replaced: the sheet tests use a fake normalizer, so nothing else
/// runs the code that stores a picked photo.
void main() {
  late Directory cache;

  setUp(() async {
    cache = await Directory.systemTemp.createTemp('review_normalizer_test_');
  });

  tearDown(() async {
    if (await cache.exists()) await cache.delete(recursive: true);
  });

  testWidgets('stores a picked photo in its own cache folder', (tester) async {
    await tester.runAsync(() async {
      final source = await _writePhoto(cache, width: 40, height: 20);
      final encoded = Uint8List.fromList(<int>[1, 2, 3, 4]);
      final normalizer = JpegReviewPhotoNormalizer(
        encode: (_, _) async => encoded,
        temporaryDirectory: () async => cache,
      );

      final first = await normalizer.normalize(source);
      final second = await normalizer.normalize(source);

      final firstPath = (first as Success<String>).data;
      final secondPath = (second as Success<String>).data;
      expect(firstPath, isNot(secondPath));
      expect(File(firstPath).parent.parent.path, cache.path);
      expect(await File(firstPath).readAsBytes(), encoded);
      expect(await File(secondPath).readAsBytes(), encoded);
    });
  });

  testWidgets('asks the encoder to keep the longest edge within the limit', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final requested = <int>[];
      final normalizer = JpegReviewPhotoNormalizer(
        encode: (_, shortSide) async {
          requested.add(shortSide);
          return <int>[1];
        },
        temporaryDirectory: () async => cache,
      );

      // Twice the limit on the longest edge: both edges are halved.
      await normalizer.normalize(
        await _writePhoto(
          cache,
          width: orderReviewPhotoMaxSide * 2,
          height: orderReviewPhotoMaxSide,
        ),
      );
      // Already small: never enlarged.
      await normalizer.normalize(
        await _writePhoto(cache, width: 30, height: 60),
      );

      expect(requested, <int>[orderReviewPhotoMaxSide ~/ 2, 30]);
    });
  });

  testWidgets('removing a stored photo deletes its folder too', (tester) async {
    await tester.runAsync(() async {
      final normalizer = JpegReviewPhotoNormalizer(
        encode: (_, _) async => <int>[1],
        temporaryDirectory: () async => cache,
      );
      final stored = await normalizer.normalize(
        await _writePhoto(cache, width: 10, height: 10),
      );
      final path = (stored as Success<String>).data;

      await normalizer.remove(path);

      expect(await File(path).exists(), isFalse);
      expect(await File(path).parent.exists(), isFalse);
    });
  });

  testWidgets('refuses a photo that is still too large or was not encoded', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final source = await _writePhoto(cache, width: 10, height: 10);
      final entriesBefore = cache.listSync().length;

      final tooLarge = await JpegReviewPhotoNormalizer(
        encode: (_, _) async => Uint8List(maxOrderReviewPhotoBytes + 1),
        temporaryDirectory: () async => cache,
      ).normalize(source);
      final notEncoded = await JpegReviewPhotoNormalizer(
        encode: (_, _) async => null,
        temporaryDirectory: () async => cache,
      ).normalize(source);
      final unreadable = await JpegReviewPhotoNormalizer(
        encode: (_, _) async => <int>[1],
        temporaryDirectory: () async => cache,
      ).normalize('${cache.path}/missing.jpg');

      expect(
        (tooLarge as Error<String>).failure,
        isA<PayloadTooLargeFailure>(),
      );
      expect((notEncoded as Error<String>).failure, isA<UnknownFailure>());
      expect((unreadable as Error<String>).failure, isA<UnknownFailure>());
      // Nothing is left behind for a refused photo.
      expect(cache.listSync().length, entriesBefore);
    });
  });
}

var _photoIndex = 0;

Future<String> _writePhoto(
  Directory directory, {
  required int width,
  required int height,
}) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const ui.Color(0xFFC4511A),
  );
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  final file = File('${directory.path}/source_${_photoIndex++}.png');
  await file.writeAsBytes(data!.buffer.asUint8List(), flush: true);
  return file.path;
}
