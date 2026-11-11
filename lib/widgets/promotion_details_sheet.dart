import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/promotion_model.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/utils/price_formatter.dart';
import 'package:enjoy_lavash_mobile/widgets/app_bottom_sheet_drag_handle.dart';
import 'package:enjoy_lavash_mobile/widgets/app_modal_bottom_sheet.dart';
import 'package:enjoy_lavash_mobile/widgets/app_snack_bar.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

Future<void> showPromotionDetails(
  BuildContext context, {
  required PromotionModel promotion,
  required String locale,
}) async {
  final code = promotion.code?.trim();
  await showAppModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    enableDrag: true,
    isDismissible: true,
    showDragHandle: false,
    builder: (sheetContext) => _PromotionDetailsSheet(
      promotion: promotion,
      locale: locale,
      onCopyCode: code?.isNotEmpty == true
          ? () {
              Clipboard.setData(ClipboardData(text: code!));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(appSnackBar(L.of(context).promoCodeCopied));
            }
          : null,
    ),
  );
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
              AppBottomSheetDragHandle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.1),
              ),
              const SizedBox(height: 8),
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
                  value: promotion.isPercentageDiscount
                      ? '${promotion.discountValue}%'
                      : formatSum(context, promotion.discountValue!),
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
