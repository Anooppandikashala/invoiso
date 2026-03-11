import 'package:intl/intl.dart';

class AppFormatters {
  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _shortDateFormat = DateFormat('dd/MM/yyyy');
  static final _numberFormat = NumberFormat('#,##0.00');

  static String formatDate(DateTime? date) =>
      date != null ? _dateFormat.format(date) : 'Unknown date';

  static String formatShortDate(DateTime? date) =>
      date != null ? _shortDateFormat.format(date) : '-';

  static String formatAmount(double amount, String symbol) =>
      '$symbol ${_numberFormat.format(amount)}';
}
