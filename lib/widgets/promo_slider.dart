import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/promotion_model.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/widgets/app_snack_bar.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class PromoSlider extends StatefulWidget {
  const PromoSlider({
    super.key,
    required this.promotions,
    required this.locale,
  });

  final List<PromotionModel> promotions;
  final String locale;

  @override
  State<PromoSlider> createState() => _PromoSliderState();
}

class _PromoSliderState extends State<PromoSlider> {
  final PageController _pageController = PageController();
  int _selectedIndex = 0;

  @override
  void didUpdateWidget(covariant PromoSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.promotions.length != widget.promotions.length &&
        _selectedIndex >= widget.promotions.length) {
      _selectedIndex = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _copyPromoCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    final t = L.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      appSnackBar(t.promoCodeCopied, duration: const Duration(seconds: 2)),
    );
  }

  void _showPromotionDetails(PromotionModel promotion) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _PromotionDetailsSheet(
        promotion: promotion,
        locale: widget.locale,
        onCopyCode: promotion.code?.trim().isNotEmpty == true
            ? () => _copyPromoCode(promotion.code!.trim())
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final promotions = widget.promotions;
    final t = L.of(context);

    return Column(
      children: [
        SizedBox(
          height: 152,
          child: PageView.builder(
            controller: _pageController,
            itemCount: promotions.length,
            onPageChanged: (index) {
              setState(() => _selectedIndex = index);
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  right: index == promotions.length - 1 ? 0 : 10,
                ),
                child: _PromoBanner(
                  promotion: promotions[index],
                  fallbackTitle: t.specialOffer,
                  fallbackDescription: t.specialOfferDesc,
                  fallbackCta: t.specialOfferCta,
                  onTap: () => _showPromotionDetails(promotions[index]),
                  onCodeTap: promotions[index].code?.trim().isNotEmpty == true
                      ? () => _copyPromoCode(promotions[index].code!.trim())
                      : null,
                ),
              );
            },
          ),
        ),
        if (promotions.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var index = 0; index < promotions.length; index++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: index == _selectedIndex ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: index == _selectedIndex
                        ? BaseColors.primary
                        : BaseColors.primary.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Promo banner card
// ---------------------------------------------------------------------------

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({
    required this.promotion,
    required this.fallbackTitle,
    required this.fallbackDescription,
    required this.fallbackCta,
    required this.onTap,
    this.onCodeTap,
  });

  final PromotionModel promotion;
  final String fallbackTitle;
  final String fallbackDescription;
  final String fallbackCta;
  final VoidCallback onTap;
  final VoidCallback? onCodeTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = promotion.description?.trim();
    final promoCode = promotion.code?.trim();
    final hasCode = promoCode?.isNotEmpty == true;

    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFB74D), BaseColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TypographyText(
                  promotion.title.isEmpty ? fallbackTitle : promotion.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: TypographyText(
                    description?.isNotEmpty == true
                        ? description!
                        : fallbackDescription,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: hasCode ? onCodeTap : null,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: TypographyText(
                              hasCode ? promoCode! : fallbackCta,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasCode) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.copy_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Promotion details bottom sheet
// ---------------------------------------------------------------------------

class _PromotionDetailsSheet extends StatelessWidget {
  const _PromotionDetailsSheet({
    required this.promotion,
    required this.locale,
    this.onCopyCode,
  });

  final PromotionModel promotion;
  final String locale;
  final VoidCallback? onCopyCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = L.of(context);
    final description = promotion.description?.trim();
    final promoCode = promotion.code?.trim();
    final hasCode = promoCode?.isNotEmpty == true;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D1A18) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TypographyText(
                promotion.title.isEmpty ? t.promotionDetails : promotion.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (description?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                TypographyText(
                  description!,
                  style: const TextStyle(
                    color: BaseColors.textGray,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
              if (promotion.discountValue != null) ...[
                const SizedBox(height: 16),
                _DetailRow(
                  icon: Icons.local_offer_rounded,
                  label: t.discount,
                  value: promotion.discountType == 'PERCENTAGE'
                      ? '${promotion.discountValue}%'
                      : "${promotion.discountValue} so'm",
                  isDark: isDark,
                ),
              ],
              if (promotion.endsAt != null) ...[
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.schedule_rounded,
                  label: t.validUntil(
                    DateFormat.yMMMMd(locale).format(promotion.endsAt!),
                  ),
                  isDark: isDark,
                ),
              ],
              if (hasCode) ...[
                const SizedBox(height: 20),
                _PromoCodeCard(
                  code: promoCode!,
                  isDark: isDark,
                  label: t.promoCode,
                  onCopy: onCopyCode,
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: BaseColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: TypographyText(
                    t.close,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.isDark,
    this.value,
  });

  final IconData icon;
  final String label;
  final String? value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: BaseColors.surfaceTint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: BaseColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TypographyText(label, style: const TextStyle(fontSize: 15)),
        ),
        if (value != null)
          TypographyText(
            value!,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: BaseColors.primary,
            ),
          ),
      ],
    );
  }
}

class _PromoCodeCard extends StatelessWidget {
  const _PromoCodeCard({
    required this.code,
    required this.isDark,
    required this.label,
    this.onCopy,
  });

  final String code;
  final bool isDark;
  final String label;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2522) : const Color(0xFFF8F4EF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TypographyText(
                  label,
                  style: const TextStyle(
                    color: BaseColors.textGray,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                TypographyText(
                  code,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded),
            color: BaseColors.primary,
            style: IconButton.styleFrom(
              backgroundColor: BaseColors.primary.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
