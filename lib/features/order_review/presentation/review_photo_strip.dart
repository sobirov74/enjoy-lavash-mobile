import 'dart:io';

import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/theme/app_design_tokens.dart';
import 'package:flutter/material.dart';

import '../data/order_review_limits.dart';

const double reviewPhotoExtent = AppDesignTokens.tabBarHeight;

class ReviewPhotoStrip extends StatelessWidget {
  const ReviewPhotoStrip({
    super.key,
    required this.paths,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> paths;
  final VoidCallback? onAdd;
  final ValueChanged<String>? onRemove;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if (paths.length < maxOrderReviewPhotos)
                SizedBox(
                  width: reviewPhotoExtent,
                  height: reviewPhotoExtent,
                  child: OutlinedButton(
                    key: const ValueKey<String>('review-add-photo'),
                    onPressed: onAdd,
                    style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_a_photo_outlined,
                          color: BaseColors.primary,
                        ),
                        Text(t.reviewAddPhoto, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              for (var index = 0; index < paths.length; index++)
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppDesignTokens.gutter / 2,
                  ),
                  child: SizedBox(
                    width: reviewPhotoExtent,
                    height: reviewPhotoExtent,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppDesignTokens.radiusThumb,
                          ),
                          child: Image.file(
                            File(paths[index]),
                            fit: BoxFit.cover,
                            cacheWidth: orderReviewPhotoMaxSide ~/ 4,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.image_outlined),
                          ),
                        ),
                        Align(
                          alignment: Alignment.topRight,
                          child: IconButton.filled(
                            key: ValueKey<String>('review-remove-photo-$index'),
                            tooltip: t.reviewRemovePhoto(index + 1),
                            onPressed: onRemove == null
                                ? null
                                : () => onRemove!(paths[index]),
                            // Small on the 72 px thumbnail; the padded tap
                            // target keeps a 48 px hit area.
                            constraints: const BoxConstraints.tightFor(
                              width: 28,
                              height: 28,
                            ),
                            padding: EdgeInsets.zero,
                            iconSize: 16,
                            style: IconButton.styleFrom(
                              tapTargetSize: MaterialTapTargetSize.padded,
                            ),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppDesignTokens.gutter / 2),
        Text(
          t.reviewPhotoCount(paths.length, maxOrderReviewPhotos),
          style: TextStyle(color: AppDesignTokens.secondaryText(context)),
        ),
      ],
    );
  }
}
