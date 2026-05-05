import 'package:intl/intl.dart';

extension DateFormatLocal on DateTime {
  String formatLocal([String pattern = 'dd.MM.yyyy HH:mm']) {
    return DateFormat(pattern).format(toLocal());
  }
}
