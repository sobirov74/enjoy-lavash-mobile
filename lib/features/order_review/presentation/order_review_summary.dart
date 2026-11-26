import 'dart:async';

import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/theme/app_design_tokens.dart';
import 'package:enjoy_lavash_mobile/utils/format_cache.dart';
import 'package:enjoy_lavash_mobile/widgets/utils/cached_image_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models/order_review_model.dart';
import '../data/order_review_limits.dart';
import 'order_review_photo_viewer.dart';
import 'review_photo_strip.dart';

class OrderReviewSummary extends StatelessWidget {
  const OrderReviewSummary({super.key, required this.review});

  final OrderReviewModel review;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final date = review.createdAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: t.reviewStarLabel(review.rating),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var value = 1; value <= orderReviewStarCount; value++)
                Icon(
                  value <= review.rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: AppDesignTokens.gutter,
                  color: BaseColors.primary,
                ),
            ],
          ),
        ),
        if (date != null)
          Text(
            dateFormat(
              t.localeName,
              'yMMMd',
              DateFormat.yMMMd,
            ).format(date.toLocal()),
            style: TextStyle(color: AppDesignTokens.secondaryText(context)),
          ),
        if (review.comment?.isNotEmpty == true) ...[
          const SizedBox(height: AppDesignTokens.gutter / 2),
          Text(review.comment!),
        ],
        if (review.photos.isNotEmpty) ...[
          const SizedBox(height: AppDesignTokens.gutter / 2),
          Wrap(
            spacing: AppDesignTokens.gutter / 2,
            runSpacing: AppDesignTokens.gutter / 2,
            children: [
              for (var index = 0; index < review.photos.length; index++)
                Semantics(
                  label: t.reviewViewPhoto(index + 1),
                  button: true,
                  child: InkWell(
                    key: ValueKey<String>('review-photo-$index'),
                    borderRadius: BorderRadius.circular(
                      AppDesignTokens.radiusThumb,
                    ),
                    onTap: () => unawaited(
                      showOrderReviewPhoto(context, review.photos[index].url),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppDesignTokens.radiusThumb,
                      ),
                      child: Image(
                        width: reviewPhotoExtent,
                        height: reviewPhotoExtent,
                        fit: BoxFit.cover,
                        image: coverNetworkImage(
                          review.photos[index].url,
                          box: const Size.square(reviewPhotoExtent),
                          devicePixelRatio: MediaQuery.devicePixelRatioOf(
                            context,
                          ),
                        ),
                        errorBuilder: (_, _, _) => const SizedBox.square(
                          dimension: reviewPhotoExtent,
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
