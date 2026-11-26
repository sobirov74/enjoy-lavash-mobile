import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:enjoy_lavash_mobile/core/error/failures.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

import 'order_review_limits.dart';

abstract class ReviewPhotoNormalizer {
  const ReviewPhotoNormalizer();
  Future<Result<String>> normalize(String path);
  Future<void> remove(String path);
}

class JpegReviewPhotoNormalizer extends ReviewPhotoNormalizer {
  const JpegReviewPhotoNormalizer();

  @override
  Future<Result<String>> normalize(String path) async {
    Directory? outputDirectory;
    try {
      final buffer = await ui.ImmutableBuffer.fromFilePath(path);
      late final ui.ImageDescriptor descriptor;
      try {
        descriptor = await ui.ImageDescriptor.encoded(buffer);
      } finally {
        buffer.dispose();
      }
      final scale = math.min(
        1.0,
        orderReviewPhotoMaxSide / math.max(descriptor.width, descriptor.height),
      );
      // Native encoders fit the shortest edge and may swap the bounds for
      // EXIF rotation. A square bound derived from that edge keeps the longest
      // edge within the limit in either orientation.
      final targetShortSide = math.max(
        1,
        (math.min(descriptor.width, descriptor.height) * scale).floor(),
      );
      descriptor.dispose();
      final bytes = await FlutterImageCompress.compressWithFile(
        path,
        minWidth: targetShortSide,
        minHeight: targetShortSide,
        quality: orderReviewPhotoQuality,
        format: CompressFormat.jpeg,
        keepExif: false,
      );
      if (bytes == null) return const Error(UnknownFailure());
      if (bytes.length > maxOrderReviewPhotoBytes) {
        return const Error(PayloadTooLargeFailure());
      }
      final temp = await getTemporaryDirectory();
      outputDirectory = await Directory(
        '${temp.path}/order_review_',
      ).createTemp();
      final output = File('${outputDirectory.path}/photo.jpg');
      await output.writeAsBytes(bytes, flush: true);
      return Success(output.path);
    } catch (_) {
      if (outputDirectory != null) {
        await remove('${outputDirectory.path}/photo.jpg');
      }
      return const Error(UnknownFailure());
    }
  }

  @override
  Future<void> remove(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
      if (await file.parent.exists()) await file.parent.delete();
    } catch (_) {
      // A temp-file cleanup must not prevent closing or retrying a review.
    }
  }
}
