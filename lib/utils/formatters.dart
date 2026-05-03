import 'package:intl/intl.dart';

/// Converts a list of rows to CSV with every field double-quoted.
/// Internal double quotes are escaped by doubling them (RFC 4180).
String buildQuotedCsv(List<List<dynamic>> rows) {
  return rows.map((row) {
    return row.map((cell) {
      final s = cell.toString().replaceAll('"', '""');
      return '"$s"';
    }).join(',');
  }).join('\n');
}

class AppFormatters {
  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _numberFormat = NumberFormat('#,##0.00');

  static String formatDate(DateTime? date) =>
      date != null ? _dateFormat.format(date) : 'Unknown date';

  static String formatShortDate(DateTime? date, {String pattern = 'dd/MM/yyyy'}) =>
      date != null ? DateFormat(pattern).format(date) : '-';

  static String formatAmount(double amount, String symbol) =>
      '$symbol ${_numberFormat.format(amount)}';
}

extension StringLimit on String {
  String limit(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return substring(0, maxLength) + suffix;
  }
}
