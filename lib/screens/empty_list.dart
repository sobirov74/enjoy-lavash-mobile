import 'package:flutter/material.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';

class EmptyList extends StatelessWidget {
  final String? label;

  const EmptyList({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    final text = label ?? L.of(context).emptyList;

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.translate(
            offset: const Offset(0, -50),
            child: Image.asset(
              'assets/images/enjoy-logo.png',
              width: 250,
              height: 250,
            ),
          ),
          TypographyText(
            text,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
