import 'package:intl/intl.dart';

/// Number / date formatting shared by every layout. Matches the app's
/// built-in templates (Settings → Number format, date pattern, time format).

final _amountFormats = {
  'none': NumberFormat('0.00', 'en_US'), // 1234567.89
  'international': NumberFormat('#,##0.00', 'en_US'), // 1,234,567.89
  'indian': NumberFormat('#,##,##0.00', 'en_US'), // 12,34,567.89
};

/// 2 decimals, grouped per [separator] ('none' | 'international' | 'indian').
String formatAmount(double value, String separator) =>
    (_amountFormats[separator] ?? _amountFormats['none']!).format(value);

/// Whole numbers without decimals, otherwise up to 2 decimals: 2, 2.5, 2.25.
String formatQuantity(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

/// [pattern] e.g. 'dd/MM/yyyy'; with [withTime], appends the time in
/// [timeFormat] '12' (h:mm a) or anything else (HH:mm).
String formatDate(DateTime date, String pattern,
    {bool withTime = false, String timeFormat = '24'}) {
  final day = DateFormat(pattern, 'en_US').format(date);
  if (!withTime) return day;
  final time = DateFormat(timeFormat == '12' ? 'h:mm a' : 'HH:mm', 'en_US');
  return '$day ${time.format(date)}';
}
