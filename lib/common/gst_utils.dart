/// India GST helpers.
class GstUtils {
  static final _gstinPattern =
      RegExp(r'^\d{2}[A-Z]{5}\d{4}[A-Z][1-9A-Z]Z[0-9A-Z]$');
  static final _hsnPattern = RegExp(r'^(\d{4}|\d{6}|\d{8})$');

  /// GSTR-1 accepts HSN/SAC of 4, 6 or 8 digits. Empty is allowed (optional field).
  static bool isValidHsn(String hsn) {
    final h = hsn.trim();
    return h.isEmpty || _hsnPattern.hasMatch(h);
  }

  /// 2-digit state code (first two digits of a valid GSTIN), or null.
  static String? stateCodeFromGstin(String? gstin) {
    final g = gstin?.trim().toUpperCase() ?? '';
    return _gstinPattern.hasMatch(g) ? g.substring(0, 2) : null;
  }
}
