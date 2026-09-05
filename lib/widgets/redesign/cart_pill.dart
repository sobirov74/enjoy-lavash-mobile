import 'package:enjoy_lavash_mobile/theme/app_design_tokens.dart';
import 'package:flutter/material.dart';

class CartPill extends StatelessWidget {
  const CartPill({
    required this.itemCount,
    required this.totalLabel,
    required this.label,
    required this.onTap,
    super.key,
  });

  final int itemCount;
  final String totalLabel;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label, $itemCount, $totalLabel',
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFFF4F0EB)
                : AppDesignTokens.ink,
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
            boxShadow: AppDesignTokens.darkPillShadow,
          ),
          child: InkWell(
            key: const ValueKey<String>('floating-cart-pill'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppDesignTokens.ink.withValues(alpha: 0.10)
                          : Colors.white.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$itemCount',
                      style: AppTextStyles.ui(
                        size: 11,
                        weight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppDesignTokens.ink
                            : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: AppTextStyles.ui(
                        size: 15.5,
                        weight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppDesignTokens.ink
                            : Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    totalLabel,
                    style: AppTextStyles.ui(
                      size: 15.5,
                      weight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppDesignTokens.ink
                          : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
