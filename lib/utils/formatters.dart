import 'package:intl/intl.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/services/backend_services.dart';

/// Leading characters that make Excel/LibreOffice treat a cell as a formula.
const _csvFormulaTriggers = ['=', '+', '-', '@', '\t', '\r'];
final _csvPlainNumber = RegExp(r'^-?[\d,]*\.?\d+$');

/// Prefixes formula-like text with `'` so spreadsheets show it as text
/// instead of executing it (CSV formula injection). Plain numbers such as
/// negative amounts are left untouched.
String _neutralizeCsvFormula(String s) {
  if (s.isEmpty || !_csvFormulaTriggers.contains(s[0])) return s;
  if (_csvPlainNumber.hasMatch(s)) return s;
  return "'$s";
}

/// Reverses [_neutralizeCsvFormula] so re-importing an exported CSV
/// doesn't keep the added `'`.
String stripCsvFormulaGuard(String s) =>
    s.length > 1 && s[0] == "'" && _csvFormulaTriggers.contains(s[1])
        ? s.substring(1)
        : s;

/// Converts a list of rows to CSV with every field double-quoted.
/// Internal double quotes are escaped by doubling them (RFC 4180).
String buildQuotedCsv(List<List<dynamic>> rows) {
  return rows.map((row) {
    return row.map((cell) {
      final s = _neutralizeCsvFormula(cell.toString()).replaceAll('"', '""');
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

/// Displayed amounts per the Number format setting (Settings → Invoice
/// Settings). Display only — inputs, CSV exports, the UPI QR amount and the
/// DB keep plain `toStringAsFixed(2)`.
class AmountFormat {
  /// Process-wide cache; [load] refreshes it before a PDF is built.
  static AmountSeparator style = AmountSeparator.none;

  static final _formats = {
    AmountSeparator.none: NumberFormat('0.00', 'en_US'),
    AmountSeparator.international: NumberFormat('#,##0.00', 'en_US'),
    AmountSeparator.indian: NumberFormat('#,##,##0.00', 'en_US'),
  };

  static Future<void> load() async =>
      style = await BackendServices.settings.getAmountSeparator();

  /// 2 decimals, grouped per [style]: 1234567.89 / 1,234,567.89 / 12,34,567.89.
  static String money(double v) => _formats[style]!.format(v);
}

extension StringLimit on String {
  String limit(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return substring(0, maxLength) + suffix;
  }
}
