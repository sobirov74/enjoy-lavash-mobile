import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/widgets/icon_button.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';

class CustomHomeAppBar extends StatelessWidget {
  const CustomHomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /// Location selector
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // open branch selector
                },
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    // vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? BaseColors.black : BaseColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26, // Shadow color
                        blurRadius: 0.2, // Softens the shadow
                        spreadRadius: 0.1, // Expands the shadow
                        offset: Offset(0.1, 0.1), // Moves the shadow (x, y)
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: BaseColors.primary,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: TypographyText(
                          "Алмата Р.Б. Магазин",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: BaseColors.primary),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 30),

            /// Notification button
            MyIconButton(
              icon: SvgPicture.asset('assets/icons/has_notification.svg'),
            ),
          ],
        ),
      ),
    );
  }
}
