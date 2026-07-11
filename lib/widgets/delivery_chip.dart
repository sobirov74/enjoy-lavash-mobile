import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:flutter/material.dart';

class DeliveryChip extends StatelessWidget {
  const DeliveryChip({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.active = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleText = subtitle?.trim();
    final hasSubtitle = subtitleText != null && subtitleText.isNotEmpty;

    final Color subtitleTitleColor;
    if (active) {
      subtitleTitleColor = BaseColors.primary;
    } else if (isDark) {
      subtitleTitleColor = const Color(0xFF9E9790);
    } else {
      subtitleTitleColor = BaseColors.textGray;
    }

    final Color bgColor;
    if (active) {
      bgColor = isDark ? const Color(0xFF2A2521) : Colors.white;
    } else {
      bgColor = Colors.transparent;
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: EdgeInsets.symmetric(
        horizontal: hasSubtitle ? 10 : 12,
        vertical: hasSubtitle ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, color: active ? BaseColors.primary : null, size: 21),
          SizedBox(width: hasSubtitle ? 6 : 8),
          Flexible(
            child: hasSubtitle
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      TypographyText(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: subtitleTitleColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 1),
                      TypographyText(
                        subtitleText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  )
                : TypographyText(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
