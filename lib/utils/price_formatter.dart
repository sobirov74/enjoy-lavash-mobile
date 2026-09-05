import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

String formatSum(BuildContext context, int value) {
  final language = Localizations.localeOf(context).languageCode;
  final amount = NumberFormat.decimalPattern(language).format(value);
  final currency = switch (language) {
    'ru' => 'сум',
    'en' => 'UZS',
    _ => "so'm",
  };
  return '$amount $currency';
}
