/// Converts numbers to words using the Indian numbering system
/// (thousand, lakh, crore) — e.g. 1110 -> "One Thousand One Hundred and Ten".
class AmountInWords {
  static const _ones = [
    '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
    'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
    'Seventeen', 'Eighteen', 'Nineteen',
  ];
  static const _tens = [
    '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty',
    'Ninety',
  ];

  static String _twoDigits(int n) {
    if (n < 20) return _ones[n];
    final ten = _tens[n ~/ 10];
    final one = n % 10;
    return one == 0 ? ten : '$ten ${_ones[one]}';
  }

  static String _threeDigits(int n) {
    final hundred = n ~/ 100;
    final rest = n % 100;
    if (hundred == 0) return _twoDigits(rest);
    final head = '${_ones[hundred]} Hundred';
    return rest == 0 ? head : '$head and ${_twoDigits(rest)}';
  }

  /// Whole-number to words, Indian grouping (crore/lakh/thousand).
  static String number(int n) {
    if (n == 0) return 'Zero';
    if (n < 0) return 'Minus ${number(-n)}';

    final crore = n ~/ 10000000;
    final lakh = (n ~/ 100000) % 100;
    final thousand = (n ~/ 1000) % 100;
    final hundred = n % 1000;

    final parts = <String>[];
    if (crore > 0) parts.add('${_twoDigits(crore)} Crore');
    if (lakh > 0) parts.add('${_twoDigits(lakh)} Lakh');
    if (thousand > 0) parts.add('${_twoDigits(thousand)} Thousand');
    if (hundred > 0) parts.add(_threeDigits(hundred));
    return parts.join(' ');
  }

  /// Rounds [value] to the nearest whole unit and renders it in words,
  /// e.g. 1110.0 -> "One Thousand One Hundred and Ten Only".
  static String amount(double value, {String suffix = 'Only'}) {
    final words = number(value.round());
    return suffix.isEmpty ? words : '$words $suffix';
  }
}
