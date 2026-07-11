import 'package:flutter/material.dart';

enum FontWeightType { thin, normal, medium, semibold, bold }

class TypographyText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextType type;
  final int? maxLines;
  final TextOverflow? overflow;
  final FontWeightType weight;
  final TextAlign? textAlign;

  const TypographyText(
    this.text, {
    super.key,
    this.style,
    this.type = TextType.base,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.weight = FontWeightType.normal,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = type == TextType.secondary
        ? (isDark ? Colors.grey.shade400 : Colors.grey.shade600)
        : (isDark ? Colors.white : Colors.black);

    return Text(
      text,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      style: TextStyle(
        fontSize: 16,
        color: baseColor,
        fontWeight: _fontWeight(weight),
      ).merge(style),
    );
  }

  FontWeight _fontWeight(FontWeightType weight) {
    switch (weight) {
      case FontWeightType.thin:
        return FontWeight.w300;
      case FontWeightType.medium:
        return FontWeight.w500;
      case FontWeightType.semibold:
        return FontWeight.w600;
      case FontWeightType.bold:
        return FontWeight.w700;
      case FontWeightType.normal:
        // default:
        return FontWeight.w400;
    }
  }
}

enum TextType { base, secondary }
