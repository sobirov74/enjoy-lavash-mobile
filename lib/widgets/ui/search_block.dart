import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/widgets/white_container.dart';

class AppSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final String hintText;

  const AppSearchField({
    super.key,
    required this.controller,
    this.onChanged,
    this.onTap,
    this.hintText = "Поиск",
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WhiteContainer(
      // padding: const EdgeInsets.symmetric(horizontal: 16),
      // decoration: BoxDecoration(
      //   color: theme.colorScheme.surface,
      //   borderRadius: BorderRadius.circular(20),
      //   boxShadow: [
      //     BoxShadow(
      //       color: Colors.black.withValues(alpha:0.04),
      //       blurRadius: 8,
      //       offset: const Offset(0, 4),
      //     ),
      //   ],
      // ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isDark ? BaseColors.black600 : BaseColors.baseBg,
        ),
        // color: isDark ? BaseColors.black600 : BaseColors.baseBg,
        child: Row(
          children: [
            /// Search Icon
            const SizedBox(width: 10),
            SvgPicture.asset('assets/icons/search.svg'),

            const SizedBox(width: 10),

            /// Input
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                onTap: onTap,
                decoration: InputDecoration(
                  hintText: hintText,
                  fillColor: BaseColors.black,
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),

            /// Clear button
            if (controller.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  controller.clear();
                  onChanged?.call("");
                },
                child: const Icon(Icons.close, size: 18, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
