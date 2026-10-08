import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

typedef NetworkImageProviderFactory =
    ImageProvider<Object> Function(String url);

/// How the app loads network images. Production keeps a disk cache so
/// product, banner and category photos are not downloaded again on every
/// cold start; widget tests swap in [NetworkImage]
/// (see `test/flutter_test_config.dart`).
NetworkImageProviderFactory networkImageProvider = DiskCachedNetworkImage.new;

/// A network image decoded at [cacheWidth] × [cacheHeight] physical pixels
/// when either is given, through the app-wide [networkImageProvider].
ImageProvider<Object> resizedNetworkImage(
  String url, {
  int? cacheWidth,
  int? cacheHeight,
}) {
  return ResizeImage.resizeIfNeeded(
    cacheWidth,
    cacheHeight,
    networkImageProvider(url),
  );
}

/// Disk cache for photos: enough objects for the whole catalog plus banners,
/// refreshed after [_stalePeriod] even when the URL did not change.
class AppImageCacheManager extends CacheManager {
  factory AppImageCacheManager() => _instance ??= AppImageCacheManager._();

  AppImageCacheManager._()
    : super(
        Config(
          _key,
          stalePeriod: _stalePeriod,
          maxNrOfCacheObjects: _maxObjects,
        ),
      );

  static const String _key = 'enjoy_lavash_images';
  static const Duration _stalePeriod = Duration(days: 14);
  static const int _maxObjects = 600;
  static AppImageCacheManager? _instance;
}

/// [ImageProvider] that serves [url] from [AppImageCacheManager], fetching
/// it over the network only when the cached copy is missing or stale.
@immutable
class DiskCachedNetworkImage extends ImageProvider<DiskCachedNetworkImage> {
  const DiskCachedNetworkImage(this.url, {this.scale = 1.0});

  final String url;
  final double scale;

  @override
  Future<DiskCachedNetworkImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<DiskCachedNetworkImage>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    DiskCachedNetworkImage key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadCodec(key, decode),
      scale: key.scale,
      debugLabel: key.url,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<DiskCachedNetworkImage>('Image key', key),
      ],
    );
  }

  Future<ui.Codec> _loadCodec(
    DiskCachedNetworkImage key,
    ImageDecoderCallback decode,
  ) async {
    try {
      final file = await AppImageCacheManager().getSingleFile(key.url);
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw StateError('${key.url} is empty and cannot be decoded.');
      }
      return await decode(await ui.ImmutableBuffer.fromUint8List(bytes));
    } catch (_) {
      // Same as NetworkImage: a failed load must not stay in the memory
      // cache, so the next build retries instead of showing the fallback
      // forever.
      scheduleMicrotask(() => PaintingBinding.instance.imageCache.evict(key));
      rethrow;
    }
  }

  @override
  bool operator ==(Object other) {
    return other is DiskCachedNetworkImage &&
        other.url == url &&
        other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(url, scale);

  @override
  String toString() => 'DiskCachedNetworkImage("$url", scale: $scale)';
}
