import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Decoded sizes are rounded up to this many physical pixels, so slightly
/// different measurements of the same box share one decoded bitmap.
const int coverSizeStep = 16;

/// Device pixel ratios above this decode no sharper. It bounds the memory of
/// the many product photos; the few banners and Home tiles decode at the
/// screen's full ratio.
const double maxDecodeDevicePixelRatio = 3;

/// The decode size for an image of [intrinsicWidth] × [intrinsicHeight] that
/// must cover a [boxWidth] × [boxHeight] box (as `BoxFit.cover` draws it).
///
/// Only the dimension that binds is given, so the engine keeps the aspect
/// ratio (never squashed), and a source smaller than the box is decoded at
/// its own size (never upscaled).
ui.TargetImageSize coverTargetSize(
  int intrinsicWidth,
  int intrinsicHeight,
  int boxWidth,
  int boxHeight,
) {
  // The width binds when the box is relatively wider than the image.
  final widthBinds = boxWidth * intrinsicHeight >= boxHeight * intrinsicWidth;
  if (widthBinds) {
    return boxWidth >= intrinsicWidth
        ? const ui.TargetImageSize()
        : ui.TargetImageSize(width: boxWidth);
  }
  return boxHeight >= intrinsicHeight
      ? const ui.TargetImageSize()
      : ui.TargetImageSize(height: boxHeight);
}

/// [logical] × [devicePixelRatio] in physical pixels, rounded up to
/// [coverSizeStep]. The ratio is capped at [maxDecodeDevicePixelRatio]
/// unless [capDevicePixelRatio] is false.
int coverDecodeExtent(
  double logical,
  double devicePixelRatio, {
  bool capDevicePixelRatio = true,
}) {
  final ratio =
      capDevicePixelRatio && devicePixelRatio > maxDecodeDevicePixelRatio
      ? maxDecodeDevicePixelRatio
      : devicePixelRatio;
  final physical = (logical * ratio).ceil();
  final steps = (physical + coverSizeStep - 1) ~/ coverSizeStep;
  return steps < 1 ? coverSizeStep : steps * coverSizeStep;
}

/// Decodes [imageProvider] at the smallest size that covers a [width] ×
/// [height] box in physical pixels, keeping the aspect ratio.
///
/// Unlike `ResizeImage` with both sizes, a photo whose shape differs from the
/// box is neither squashed nor decoded narrower than the box.
@immutable
class CoverSizedImage extends ImageProvider<CoverSizedImageKey> {
  const CoverSizedImage(
    this.imageProvider, {
    required this.width,
    required this.height,
  }) : assert(width > 0 && height > 0);

  final ImageProvider<Object> imageProvider;

  /// Box size in physical pixels.
  final int width;
  final int height;

  @override
  Future<CoverSizedImageKey> obtainKey(ImageConfiguration configuration) {
    // Same pattern as ResizeImage: stay synchronous when the inner provider
    // resolves its key synchronously, so cached images paint on first frame.
    Completer<CoverSizedImageKey>? completer;
    SynchronousFuture<CoverSizedImageKey>? result;
    imageProvider.obtainKey(configuration).then((Object key) {
      final coverKey = CoverSizedImageKey._(key, width, height);
      if (completer == null) {
        result = SynchronousFuture<CoverSizedImageKey>(coverKey);
      } else {
        completer.complete(coverKey);
      }
    });
    if (result != null) return result!;
    completer = Completer<CoverSizedImageKey>();
    return completer.future;
  }

  @override
  ImageStreamCompleter loadImage(
    CoverSizedImageKey key,
    ImageDecoderCallback decode,
  ) {
    Future<ui.Codec> decodeToCover(
      ui.ImmutableBuffer buffer, {
      ui.TargetImageSizeCallback? getTargetSize,
    }) {
      assert(
        getTargetSize == null,
        'CoverSizedImage cannot wrap a provider that sets its own size.',
      );
      return decode(
        buffer,
        getTargetSize: (intrinsicWidth, intrinsicHeight) => coverTargetSize(
          intrinsicWidth,
          intrinsicHeight,
          key.width,
          key.height,
        ),
      );
    }

    final completer = imageProvider.loadImage(key._providerKey, decodeToCover);
    if (!kReleaseMode) {
      completer.debugLabel =
          '${completer.debugLabel} - Cover(${key.width}×${key.height})';
    }
    completer.addEphemeralErrorListener((_, _) {
      // As in ResizeImage: a failed load must not stay cached, so the next
      // build retries. The microtask lets the cache track the key first.
      scheduleMicrotask(() => PaintingBinding.instance.imageCache.evict(key));
    });
    return completer;
  }

  @override
  bool operator ==(Object other) =>
      other is CoverSizedImage &&
      other.imageProvider == imageProvider &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(imageProvider, width, height);

  @override
  String toString() =>
      'CoverSizedImage($imageProvider, width: $width, height: $height)';
}

/// Cache key of a [CoverSizedImage]: the wrapped provider's key and the box.
@immutable
class CoverSizedImageKey {
  const CoverSizedImageKey._(this._providerKey, this.width, this.height);

  final Object _providerKey;
  final int width;
  final int height;

  @override
  bool operator ==(Object other) =>
      other is CoverSizedImageKey &&
      other._providerKey == _providerKey &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(_providerKey, width, height);
}
