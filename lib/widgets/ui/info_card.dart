import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/theme/theme_extensions.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final String? textLabel;
  final String imagePath;
  final VoidCallback onPressed;

  const InfoCard({
    super.key,
    required this.title,
    required this.imagePath,
    required this.onPressed,
    this.textLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDark ? BaseColors.black600 : BaseColors.baseBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // 🔹 Image with bell icon
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    imagePath,
                    // height: 100,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),

                // Bell icon
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? BaseColors.black600 : BaseColors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SvgPicture.asset(
                      "assets/icons/notification.svg",
                      colorFilter: ColorFilter.mode(
                        context.colors.text,
                        BlendMode.srcIn,
                      ),
                      // color: !isDark ? BaseColors.black : BaseColors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 🔹 Title
            TypographyText(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: 12),

            // 🔹 Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  elevation: 0.3,
                  backgroundColor: isDark ? BaseColors.black : BaseColors.white,
                  foregroundColor: !isDark
                      ? BaseColors.black
                      : BaseColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: TypographyText(textLabel ?? ""),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
