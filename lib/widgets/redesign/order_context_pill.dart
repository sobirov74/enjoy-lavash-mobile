import 'package:enjoy_lavash_mobile/theme/app_design_tokens.dart';
import 'package:flutter/material.dart';

class OrderContextPill extends StatelessWidget {
  const OrderContextPill({
    required this.modeLabel,
    required this.contextLabel,
    required this.onTap,
    super.key,
    this.compact = false,
  });

  final String modeLabel;
  final String contextLabel;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: AppDesignTokens.surface(context),
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
          boxShadow: AppDesignTokens.cardShadow(context),
        ),
        child: InkWell(
          key: const ValueKey<String>('order-context-pill'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
          child: Padding(
            padding: compact
                ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
                : const EdgeInsets.fromLTRB(8, 8, 14, 8),
            child: Row(
              children: <Widget>[
                if (!compact) ...<Widget>[
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: AppDesignTokens.actionSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      size: 18,
                      color: AppDesignTokens.action,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: compact
                      ? Row(
                          children: <Widget>[
                            Text(
                              modeLabel,
                              style: AppTextStyles.ui(
                                size: 11.5,
                                weight: FontWeight.w600,
                                color: AppDesignTokens.tertiaryText(context),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                contextLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.ui(
                                  size: 14,
                                  weight: FontWeight.w600,
                                  color: AppDesignTokens.primaryText(context),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              modeLabel,
                              maxLines: 1,
                              style: AppTextStyles.ui(
                                size: 11.5,
                                weight: FontWeight.w600,
                                color: AppDesignTokens.tertiaryText(context),
                              ),
                            ),
                            Text(
                              contextLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.ui(
                                size: 14,
                                weight: FontWeight.w600,
                                color: AppDesignTokens.primaryText(context),
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppDesignTokens.tertiaryText(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
