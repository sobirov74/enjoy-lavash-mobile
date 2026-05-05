import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/widgets/icon_button.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';

class MenuTile extends StatelessWidget {
  final String title;
  final String icon;
  final VoidCallback? onTap;
  final bool hasNotification;
  final String? trailingLabel;

  const MenuTile({
    super.key,
    required this.title,
    required this.icon,
    this.onTap,
    this.hasNotification = false,
    this.trailingLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? BaseColors.black600 : BaseColors.baseBg,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              /// Left icon container
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? BaseColors.black : BaseColors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SvgPicture.asset(
                  icon,
                  colorFilter: ColorFilter.mode(
                    BaseColors.primary,
                    BlendMode.srcIn,
                  ),
                ),
              ),

              const SizedBox(width: 14),

              /// Title
              Expanded(
                child: TypographyText(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(overflow: TextOverflow.ellipsis),
                ),
              ),

              /// Optional label (e.g. "Скоро")
              if (trailingLabel != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TypographyText(
                    trailingLabel!,
                    weight: FontWeightType.bold,
                    style: const TextStyle(color: BaseColors.primary),
                  ),
                ),

              /// Notification + Chevron
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 30,
                    width: 30,
                    padding: const EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? BaseColors.black : BaseColors.white,
                      // shape: BoxShape.circle,
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                    ),
                    child: SvgPicture.asset(
                      'assets/icons/arrow.svg',
                      colorFilter: ColorFilter.mode(
                        BaseColors.primary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),

                  if (hasNotification)
                    Positioned(
                      right: 40,
                      top: 0,
                      child: MyIconButton(
                        height: 30,
                        width: 30,
                        removeShadow: true,
                        padding: EdgeInsets.all(0),
                        icon: SvgPicture.asset(
                          'assets/icons/has_notification.svg',
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
