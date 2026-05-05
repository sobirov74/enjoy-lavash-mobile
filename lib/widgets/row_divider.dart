import 'package:flutter/material.dart';
import 'package:enjoy_lavash_mobile/theme/theme_extensions.dart';

class RowDivider extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const RowDivider({super.key, required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.colors.border, width: 1),
        ),
      ),
      child: child,
    );
  }
}
