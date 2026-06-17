import 'package:intl/intl.dart';

class AppDate {
  const AppDate._();

  static String dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String dateKeyStart(DateTime date) => '${dateKey(date)}T00:00:00.000';
  static String dateKeyEnd(DateTime date) => '${dateKey(date)}T23:59:59.999';

  static DateTime? parse(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static String format(DateTime? date, {String pattern = 'dd/MM/yyyy'}) {
    return date == null ? '-' : DateFormat(pattern).format(date);
  }

  static String formatStored(String? value, {String pattern = 'dd/MM/yyyy'}) {
    return format(parse(value), pattern: pattern);
  }
}
