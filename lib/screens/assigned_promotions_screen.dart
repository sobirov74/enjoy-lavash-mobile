import 'dart:async';

import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/assigned_promotion_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/widgets/animated_error_message.dart';
import 'package:enjoy_lavash_mobile/widgets/app_snack_bar.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AssignedPromotionsScreen extends StatefulWidget {
  const AssignedPromotionsScreen({
    super.key,
    this.initialShowAll = false,
    this.highlightedCode,
  });

  final bool initialShowAll;
  final String? highlightedCode;

  @override
  State<AssignedPromotionsScreen> createState() =>
      _AssignedPromotionsScreenState();
}

class _AssignedPromotionsScreenState extends State<AssignedPromotionsScreen> {
  late bool _showAll = widget.initialShowAll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_refresh());
    });
  }

  Future<void> _refresh() {
    return context
        .read<MobileBackendController>()
        .refreshAssignedPromotions(
          includeAll: _showAll,
          language: Localizations.localeOf(context).languageCode,
        )
        .then((_) {});
  }

  void _setShowAll(bool showAll) {
    if (_showAll == showAll) return;
    setState(() => _showAll = showAll);
    unawaited(_refresh());
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(appSnackBar(L.of(context).promoCodeCopied));
  }

  void _usePromotion(String code) {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    final backend = context.watch<MobileBackendController>();
    final t = L.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final promotions = _orderedPromotions(backend.assignedPromotions);

    return Scaffold(
      appBar: AppBar(
        title: TypographyText(
          t.myPromotions,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
      ),
      body: RefreshIndicator(
        color: BaseColors.primary,
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
          children: <Widget>[
            _PromotionsHero(isDark: isDark),
            const SizedBox(height: 14),
            _PromotionFilter(showAll: _showAll, onChanged: _setShowAll),
            const SizedBox(height: 14),
            if (backend.assignedPromotionsLoading && promotions.isEmpty)
              for (var index = 0; index < 3; index++) ...[
                _PromotionSkeleton(isDark: isDark),
                if (index < 2) const SizedBox(height: 12),
              ]
            else if (backend.assignedPromotionsFailure != null &&
                promotions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 64),
                child: AnimatedErrorMessage(
                  failure: backend.assignedPromotionsFailure,
                  onRetry: () => unawaited(_refresh()),
                ),
              )
            else if (promotions.isEmpty)
              _EmptyPromotions(isDark: isDark)
            else
              for (var index = 0; index < promotions.length; index++) ...[
                _AssignedPromotionCard(
                  promotion: promotions[index],
                  isDark: isDark,
                  highlighted: _isHighlighted(promotions[index]),
                  onCopy: () => unawaited(_copyCode(promotions[index].code)),
                  onUse: promotions[index].canBeUsed
                      ? () => _usePromotion(promotions[index].code)
                      : null,
                ),
                if (index < promotions.length - 1) const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }

  List<AssignedPromotionModel> _orderedPromotions(
    List<AssignedPromotionModel> promotions,
  ) {
    final items = _showAll
        ? promotions
        : promotions
              .where(
                (promotion) =>
                    promotion.status == AssignedPromotionStatus.active,
              )
              .toList(growable: false);
    if (widget.highlightedCode?.trim().isEmpty != false) return items;

    return <AssignedPromotionModel>[
      ...items.where(_isHighlighted),
      ...items.where((promotion) => !_isHighlighted(promotion)),
    ];
  }

  bool _isHighlighted(AssignedPromotionModel promotion) {
    return promotion.code.trim().toUpperCase() ==
        widget.highlightedCode?.trim().toUpperCase();
  }
}

class _PromotionsHero extends StatelessWidget {
  const _PromotionsHero({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFFF9E65), BaseColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: BaseColors.primary.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(19),
            ),
            child: const Icon(
              Icons.confirmation_number_rounded,
              color: Colors.white,
              size: 31,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TypographyText(
                  t.personalOffers,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                TypographyText(
                  t.myPromotionsSubtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PromotionFilter extends StatelessWidget {
  const _PromotionFilter({required this.showAll, required this.onChanged});

  final bool showAll;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    return SegmentedButton<bool>(
      segments: <ButtonSegment<bool>>[
        ButtonSegment<bool>(
          value: false,
          icon: const Icon(Icons.bolt_rounded),
          label: Text(t.activePromotions),
        ),
        ButtonSegment<bool>(
          value: true,
          icon: const Icon(Icons.history_rounded),
          label: Text(t.allPromotions),
        ),
      ],
      selected: <bool>{showAll},
      showSelectedIcon: false,
      onSelectionChanged: (values) => onChanged(values.first),
      style: ButtonStyle(
        visualDensity: VisualDensity.comfortable,
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }
}

class _AssignedPromotionCard extends StatelessWidget {
  const _AssignedPromotionCard({
    required this.promotion,
    required this.isDark,
    required this.highlighted,
    required this.onCopy,
    required this.onUse,
  });

  final AssignedPromotionModel promotion;
  final bool isDark;
  final bool highlighted;
  final VoidCallback onCopy;
  final VoidCallback? onUse;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final muted = isDark ? BaseColors.lightTextGray : BaseColors.textGray;
    final statusColor = _statusColor(promotion.status, isDark);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D1A18) : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: highlighted
              ? BaseColors.primary
              : statusColor.withValues(alpha: 0.24),
          width: highlighted ? 2 : 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: TypographyText(
                  promotion.title.isEmpty
                      ? t.promotionDetails
                      : promotion.title,
                  style: const TextStyle(
                    fontSize: 19,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: TypographyText(
                  _statusLabel(t, promotion.status),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          if (promotion.description?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 8),
            TypographyText(
              promotion.description!.trim(),
              style: TextStyle(color: muted, fontSize: 14, height: 1.35),
            ),
          ],
          if (promotion.reward?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 14),
            _DetailLine(
              icon: Icons.card_giftcard_rounded,
              label: t.reward,
              value: promotion.reward!.trim(),
              isDark: isDark,
            ),
          ],
          if (promotion.conditions.isNotEmpty) ...[
            const SizedBox(height: 12),
            _DetailLine(
              icon: Icons.rule_rounded,
              label: t.conditions,
              value: promotion.conditions.join('\n'),
              isDark: isDark,
            ),
          ],
          if (promotion.startsAt != null || promotion.endsAt != null) ...[
            const SizedBox(height: 12),
            _DetailLine(
              icon: Icons.event_rounded,
              label: t.validity,
              value: _validityText(t, promotion, locale),
              isDark: isDark,
            ),
          ],
          if (promotion.remainingUses != null) ...[
            const SizedBox(height: 12),
            _DetailLine(
              icon: Icons.replay_rounded,
              label: t.usage,
              value: t.remainingUses(promotion.remainingUses!),
              isDark: isDark,
            ),
          ],
          if (promotion.code.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Material(
              color: BaseColors.primary.withValues(alpha: isDark ? 0.16 : 0.08),
              borderRadius: BorderRadius.circular(17),
              child: InkWell(
                borderRadius: BorderRadius.circular(17),
                onTap: onCopy,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: TypographyText(
                          promotion.code,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: BaseColors.primaryDark,
                            fontSize: 17,
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.copy_rounded,
                        color: BaseColors.primary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          if (onUse != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onUse,
                style: FilledButton.styleFrom(
                  backgroundColor: BaseColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
                icon: const Icon(Icons.shopping_bag_outlined),
                label: TypographyText(
                  t.usePromo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _validityText(L t, AssignedPromotionModel promotion, String locale) {
    final formatter = DateFormat.yMMMd(locale);
    if (promotion.startsAt != null && promotion.endsAt != null) {
      return '${formatter.format(promotion.startsAt!.toLocal())} — '
          '${formatter.format(promotion.endsAt!.toLocal())}';
    }
    if (promotion.endsAt != null) {
      return t.validUntil(formatter.format(promotion.endsAt!.toLocal()));
    }
    return t.validFrom(formatter.format(promotion.startsAt!.toLocal()));
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, color: BaseColors.primary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TypographyText(
                label,
                style: TextStyle(
                  color: isDark
                      ? BaseColors.lightTextGray
                      : BaseColors.textGray,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              TypographyText(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyPromotions extends StatelessWidget {
  const _EmptyPromotions({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
      child: Column(
        children: <Widget>[
          Icon(
            Icons.local_offer_outlined,
            size: 64,
            color: BaseColors.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 18),
          TypographyText(
            t.noAssignedPromotions,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          TypographyText(
            t.noAssignedPromotionsSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? BaseColors.lightTextGray : BaseColors.textGray,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _PromotionSkeleton extends StatelessWidget {
  const _PromotionSkeleton({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 196,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D1A18) : Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
    );
  }
}

String _statusLabel(L t, AssignedPromotionStatus status) {
  return switch (status) {
    AssignedPromotionStatus.active => t.promoStatusActive,
    AssignedPromotionStatus.notStarted => t.promoStatusNotStarted,
    AssignedPromotionStatus.used => t.promoStatusUsed,
    AssignedPromotionStatus.expired => t.promoStatusExpired,
    AssignedPromotionStatus.revoked => t.promoStatusRevoked,
    AssignedPromotionStatus.inactive => t.promoStatusInactive,
    AssignedPromotionStatus.globalLimitReached => t.promoStatusLimitReached,
    AssignedPromotionStatus.unknown => t.unknown,
  };
}

Color _statusColor(AssignedPromotionStatus status, bool isDark) {
  return switch (status) {
    AssignedPromotionStatus.active => BaseColors.success,
    AssignedPromotionStatus.notStarted => const Color(0xFF3F6EC9),
    AssignedPromotionStatus.used => const Color(0xFF7A5AA6),
    AssignedPromotionStatus.expired ||
    AssignedPromotionStatus.revoked ||
    AssignedPromotionStatus.globalLimitReached =>
      isDark ? BaseColors.dangerDark : BaseColors.danger,
    AssignedPromotionStatus.inactive || AssignedPromotionStatus.unknown =>
      isDark ? BaseColors.lightTextGray : BaseColors.textGray,
  };
}
