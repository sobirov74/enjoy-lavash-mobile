import 'package:enjoy_lavash_mobile/utils/format_cache.dart';
import 'package:flutter/widgets.dart';

String formatSum(BuildContext context, int value) {
  final language = Localizations.localeOf(context).languageCode;
  final amount = decimalFormat(language).format(value);
  final currency = switch (language) {
    'ru' => 'сум',
    'en' => 'UZS',
    _ => "so'm",
  };
  return '$amount $currency';
}
