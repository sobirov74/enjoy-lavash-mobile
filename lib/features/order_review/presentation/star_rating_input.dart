import 'dart:async';

import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/theme/app_design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/order_review_limits.dart';

/// The word that goes with a rating ("Good"), empty when none is chosen.
String reviewRatingLabel(L t, int rating) {
  return switch (rating) {
    1 => t.reviewTerrible,
    2 => t.reviewBad,
    3 => t.reviewOkay,
    4 => t.reviewGood,
    5 => t.reviewExcellent,
    _ => '',
  };
}

class StarRatingInput extends StatelessWidget {
  const StarRatingInput({
    super.key,
    required this.rating,
    required this.onChanged,
  });

  final int rating;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final label = reviewRatingLabel(t, rating);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var value = 1; value <= orderReviewStarCount; value++)
              Semantics(
                label: t.reviewStarLabel(value),
                selected: value == rating,
                child: IconButton(
                  key: ValueKey<String>('review-star-$value'),
                  tooltip: t.reviewStarLabel(value),
                  constraints: const BoxConstraints.tightFor(
                    width: AppDesignTokens.buttonHeight,
                    height: AppDesignTokens.buttonHeight,
                  ),
                  onPressed: onChanged == null
                      ? null
                      : () {
                          unawaited(HapticFeedback.selectionClick());
                          onChanged!(value);
                        },
                  icon: Icon(
                    value <= rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                  ),
                  color: BaseColors.primary,
                  disabledColor: BaseColors.primary.withValues(alpha: 0.38),
                ),
              ),
          ],
        ),
        // Reserves the label's line before a star is chosen, so the form
        // below does not jump on the first tap.
        Text(
          label.isEmpty ? ' ' : label,
          style: TextStyle(color: AppDesignTokens.secondaryText(context)),
        ),
      ],
    );
  }
}
