part of 'package:enjoy_lavash_mobile/screens/profile.dart';

const double _ratePromptStarSize = 36;

/// The review's place in the order details: an invitation to rate while the
/// server allows it, the saved review afterwards, nothing otherwise.
class _OrderReviewCard extends StatelessWidget {
  const _OrderReviewCard({
    super.key,
    required this.order,
    required this.justSent,
    required this.onRate,
  });

  final CustomerOrderModel order;

  /// The review was sent a moment ago from this sheet.
  final bool justSent;

  /// Called with the star that was tapped, or 0 for the card itself.
  final ValueChanged<int> onRate;

  @override
  Widget build(BuildContext context) {
    // Lists carry the rating alone; the full review follows with the detail
    // request. The stars show at once either way.
    final rating = order.review?.rating ?? order.reviewRating;
    final review =
        order.review ??
        (rating == null ? null : OrderReviewModel(id: '', rating: rating));

    final Widget card;
    final Key cardKey;
    if (review != null) {
      cardKey = const ValueKey<String>('order-review-saved');
      card = _OrderReviewedCard(review: review, justSent: justSent);
    } else if (order.canReview) {
      cardKey = const ValueKey<String>('order-review-prompt');
      card = _OrderRatePrompt(onRate: onRate);
    } else {
      return const SizedBox.shrink();
    }

    final duration = AppMotion.duration(context, AppMotion.state);
    return Padding(
      padding: const EdgeInsets.only(top: _sectionGap),
      child: AnimatedSize(
        duration: duration,
        curve: AppMotion.enter,
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: duration,
          switchInCurve: AppMotion.enter,
          switchOutCurve: AppMotion.exit,
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.topCenter,
            children: <Widget>[...previous, ?current],
          ),
          child: SizedBox(key: cardKey, width: double.infinity, child: card),
        ),
      ),
    );
  }
}

class _OrderRatePrompt extends StatelessWidget {
  const _OrderRatePrompt({required this.onRate});

  final ValueChanged<int> onRate;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(AppDesignTokens.radiusCard);

    return Material(
      color: isDark
          ? Color.alphaBlend(
              AppDesignTokens.gold.withValues(alpha: 0.12),
              AppDesignTokens.inset(context),
            )
          : AppDesignTokens.goldWash,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: AppDesignTokens.gold.withValues(alpha: isDark ? 0.3 : 0.55),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const ValueKey<String>('details-rate-order'),
        onTap: () => onRate(0),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            _detailCardPadding,
            _detailCardPadding,
            _detailCardPadding,
            10,
          ),
          child: Column(
            children: <Widget>[
              Text(
                t.reviewTitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.display(
                  size: 17,
                  weight: FontWeight.w800,
                  color: AppDesignTokens.primaryText(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                t.reviewTapStar,
                textAlign: TextAlign.center,
                style: AppTextStyles.ui(
                  size: 13,
                  color: AppDesignTokens.secondaryText(context),
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    for (var value = 1; value <= orderReviewStarCount; value++)
                      IconButton(
                        key: ValueKey<String>('details-rate-star-$value'),
                        tooltip: t.reviewStarLabel(value),
                        onPressed: () {
                          unawaited(HapticFeedback.selectionClick());
                          onRate(value);
                        },
                        iconSize: _ratePromptStarSize,
                        color: _detailAccent(context),
                        icon: const Icon(Icons.star_outline_rounded),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderReviewedCard extends StatelessWidget {
  const _OrderReviewedCard({required this.review, required this.justSent});

  final OrderReviewModel review;
  final bool justSent;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final success = AppDesignTokens.successText(context);

    return _OrderDetailCard(
      title: t.yourReview,
      trailing: Icon(Icons.verified_rounded, color: success, size: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (justSent) ...[
            Semantics(
              liveRegion: true,
              child: Text(
                t.reviewThanks,
                key: const ValueKey<String>('order-review-thanks'),
                style: AppTextStyles.ui(
                  size: 13.5,
                  weight: FontWeight.w700,
                  color: success,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          OrderReviewSummary(review: review),
        ],
      ),
    );
  }
}
