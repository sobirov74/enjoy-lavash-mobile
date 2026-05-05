import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';

class MyIconButton extends StatelessWidget {
  final SvgPicture icon;
  final VoidCallback? onPressed;
  final bool? removeShadow;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  const MyIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.removeShadow = false,
    this.padding,
    this.width = 40,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      // margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      padding:
          padding ?? const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      width: width,
      height: height,
      decoration: BoxDecoration(
        boxShadow: !removeShadow!
            ? [
                BoxShadow(
                  color: Colors.black26, // Shadow color
                  blurRadius: 0.2, // Softens the shadow
                  spreadRadius: 0.1, // Expands the shadow
                  offset: Offset(0.1, 0.1), // Moves the shadow (x, y)
                ),
              ]
            : null,
        color: isDark ? BaseColors.black : BaseColors.white,
        // shape: BoxShape.circle,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: IconButton(icon: icon, onPressed: onPressed),
    );
  }
}
