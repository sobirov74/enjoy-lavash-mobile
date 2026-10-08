import 'package:intl/intl.dart';

/// Shared `intl` formatters.
///
/// `NumberFormat` and `DateFormat` constructors parse locale data on every
/// call. The price formatter alone runs once per product card per rebuild, so
/// instances are kept per locale (and per date skeleton) instead.
final Map<String, NumberFormat> _decimalFormats = <String, NumberFormat>{};
final Map<String, DateFormat> _dateFormats = <String, DateFormat>{};

NumberFormat decimalFormat(String locale) {
  return _decimalFormats[locale] ??= NumberFormat.decimalPattern(locale);
}

/// A [DateFormat] for [locale] built by [create], cached under [skeleton]
/// (the ICU skeleton or pattern that [create] uses, for example `yMMMd`).
DateFormat dateFormat(
  String locale,
  String skeleton,
  DateFormat Function(String locale) create,
) {
  return _dateFormats['$locale|$skeleton'] ??= create(locale);
}
