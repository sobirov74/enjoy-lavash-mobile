import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:flutter/material.dart';

SnackBar appSnackBar(
  String message, {
  Duration duration = const Duration(seconds: 3),
}) {
  return SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: BaseColors.black800,
    duration: duration,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    content: TypographyText(
      message,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    ),
  );
}
