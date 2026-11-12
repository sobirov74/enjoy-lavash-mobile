part of 'package:enjoy_lavash_mobile/navigation/main_tabs.dart';

class _CheckoutStepLabel extends StatelessWidget {
  const _CheckoutStepLabel({required this.index, required this.label});

  final int index;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TypographyText(
      '$index · ${label.toUpperCase()}',
      style: AppTextStyles.ui(
        size: 11,
        weight: FontWeight.w600,
        color: AppDesignTokens.tertiaryText(context),
      ),
    );
  }
}

class _CheckoutDestinationCard extends StatelessWidget {
  const _CheckoutDestinationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.changeLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String changeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppDesignTokens.surface(context),
      borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppDesignTokens.actionSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: AppDesignTokens.action),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TypographyText(
                      title,
                      style: AppTextStyles.ui(
                        size: 14,
                        weight: FontWeight.w600,
                        color: AppDesignTokens.primaryText(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    TypographyText(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.ui(
                        size: 12,
                        color: AppDesignTokens.secondaryText(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TypographyText(
                changeLabel,
                style: AppTextStyles.ui(
                  size: 12,
                  weight: FontWeight.w600,
                  color: AppDesignTokens.action,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCommentField extends StatelessWidget {
  const _OrderCommentField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppDesignTokens.inset(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF3A332D) : const Color(0xFFEDE2D7),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 11),
            child: Icon(Icons.notes_rounded, color: BaseColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.newline,
              cursorColor: BaseColors.primary,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: t.commentHint,
                hintStyle: TextStyle(
                  color: isDark ? const Color(0xFF9E9790) : BaseColors.textGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
