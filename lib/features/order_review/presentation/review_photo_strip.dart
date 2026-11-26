import 'dart:io';

import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/theme/app_design_tokens.dart';
import 'package:enjoy_lavash_mobile/theme/app_motion.dart';
import 'package:flutter/material.dart';

import '../data/order_review_limits.dart';

const double reviewPhotoExtent = AppDesignTokens.tabBarHeight;
const double _removeButtonExtent = 28;
const double _removeIconSize = 16;
const double _addLabelSize = 11;
const double _preparingIndicatorExtent = 22;

/// The photos attached to a review being written: thumbnails in the order
/// they were added, a tile for the photo still being prepared, then the Add
/// tile. The row follows a new photo, so the customer sees it arrive.
class ReviewPhotoStrip extends StatefulWidget {
  const ReviewPhotoStrip({
    super.key,
    required this.paths,
    required this.onAdd,
    required this.onRemove,
    this.isPreparing = false,
  });

  final List<String> paths;
  final VoidCallback? onAdd;
  final ValueChanged<String>? onRemove;

  /// A picked photo is being resized and stored; it is not in [paths] yet.
  final bool isPreparing;

  @override
  State<ReviewPhotoStrip> createState() => _ReviewPhotoStripState();
}

class _ReviewPhotoStripState extends State<ReviewPhotoStrip> {
  final ScrollController _scroll = ScrollController();
  late int _shownCount = widget.paths.length;

  @override
  void didUpdateWidget(covariant ReviewPhotoStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    // [paths] is the caller's own list, so its length is remembered here.
    final added = widget.paths.length > _shownCount;
    final startedPreparing = widget.isPreparing && !oldWidget.isPreparing;
    _shownCount = widget.paths.length;
    if (added || startedPreparing) _revealNewest();
  }

  void _revealNewest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final end = _scroll.position.maxScrollExtent;
      if (AppMotion.reduced(context)) {
        _scroll.jumpTo(end);
      } else {
        _scroll.animateTo(
          end,
          duration: AppMotion.state,
          curve: AppMotion.enter,
        );
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final paths = widget.paths;
    final canAdd =
        paths.length + (widget.isPreparing ? 1 : 0) < maxOrderReviewPhotos;
    final tiles = <Widget>[
      for (var index = 0; index < paths.length; index++)
        _PhotoTile(path: paths[index], index: index, onRemove: widget.onRemove),
      if (widget.isPreparing) const _PreparingTile(),
      if (canAdd) _AddTile(onAdd: widget.onAdd),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var index = 0; index < tiles.length; index++)
                Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 0 : AppDesignTokens.gutter / 2,
                  ),
                  child: SizedBox.square(
                    dimension: reviewPhotoExtent,
                    child: tiles[index],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppDesignTokens.gutter / 2),
        Text(
          widget.isPreparing
              ? t.reviewPreparingPhoto
              : t.reviewPhotoCount(paths.length, maxOrderReviewPhotos),
          style: TextStyle(color: AppDesignTokens.secondaryText(context)),
        ),
      ],
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onAdd});

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    return OutlinedButton(
      key: const ValueKey<String>('review-add-photo'),
      onPressed: onAdd,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        backgroundColor: AppDesignTokens.inset(context),
        side: BorderSide(color: AppDesignTokens.controlBorder(context)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusThumb),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_a_photo_outlined, color: BaseColors.primary),
          const SizedBox(height: 2),
          Text(
            t.reviewAddPhoto,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: _addLabelSize,
              height: 1.15,
              fontWeight: FontWeight.w700,
              color: AppDesignTokens.primaryText(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// Holds the place of the photo being prepared, so adding one is visible at
/// once and not only when the thumbnail is ready.
class _PreparingTile extends StatelessWidget {
  const _PreparingTile();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: L.of(context).reviewPreparingPhoto,
      child: DecoratedBox(
        key: const ValueKey<String>('review-photo-preparing'),
        decoration: BoxDecoration(
          color: AppDesignTokens.inset(context),
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusThumb),
        ),
        child: Center(
          child: AppMotion.reduced(context)
              ? const Icon(
                  Icons.hourglass_top_rounded,
                  color: BaseColors.primary,
                )
              : const SizedBox.square(
                  dimension: _preparingIndicatorExtent,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: BaseColors.primary,
                  ),
                ),
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.path,
    required this.index,
    required this.onRemove,
  });

  final String path;
  final int index;
  final ValueChanged<String>? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusThumb),
          child: Image.file(
            File(path),
            key: ValueKey<String>('review-photo-thumb-$index'),
            fit: BoxFit.cover,
            cacheWidth: orderReviewPhotoMaxSide ~/ 4,
            errorBuilder: (_, _, _) => ColoredBox(
              color: AppDesignTokens.inset(context),
              child: const Icon(Icons.image_outlined),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: IconButton.filled(
            key: ValueKey<String>('review-remove-photo-$index'),
            tooltip: L.of(context).reviewRemovePhoto(index + 1),
            onPressed: onRemove == null ? null : () => onRemove!(path),
            // Small on the thumbnail; the padded tap target keeps a 48 px
            // hit area.
            constraints: const BoxConstraints.tightFor(
              width: _removeButtonExtent,
              height: _removeButtonExtent,
            ),
            padding: EdgeInsets.zero,
            iconSize: _removeIconSize,
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
            icon: const Icon(Icons.close_rounded),
          ),
        ),
      ],
    );
  }
}
