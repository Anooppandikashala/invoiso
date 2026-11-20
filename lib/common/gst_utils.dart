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

  /// GST state codes → names, exactly as in the GSTR-1 Excel template v2.1
  /// (master sheet). No 28 (pre-2014 Andhra Pradesh); 31 is spelled as there.
  static const states = <String, String>{
    '01': 'Jammu & Kashmir',
    '02': 'Himachal Pradesh',
    '03': 'Punjab',
    '04': 'Chandigarh',
    '05': 'Uttarakhand',
    '06': 'Haryana',
    '07': 'Delhi',
    '08': 'Rajasthan',
    '09': 'Uttar Pradesh',
    '10': 'Bihar',
    '11': 'Sikkim',
    '12': 'Arunachal Pradesh',
    '13': 'Nagaland',
    '14': 'Manipur',
    '15': 'Mizoram',
    '16': 'Tripura',
    '17': 'Meghalaya',
    '18': 'Assam',
    '19': 'West Bengal',
    '20': 'Jharkhand',
    '21': 'Odisha',
    '22': 'Chhattisgarh',
    '23': 'Madhya Pradesh',
    '24': 'Gujarat',
    '25': 'Daman & Diu',
    '26': 'Dadra & Nagar Haveli & Daman & Diu',
    '27': 'Maharashtra',
    '29': 'Karnataka',
    '30': 'Goa',
    '31': 'Lakshdweep',
    '32': 'Kerala',
    '33': 'Tamil Nadu',
    '34': 'Puducherry',
    '35': 'Andaman & Nicobar Islands',
    '36': 'Telangana',
    '37': 'Andhra Pradesh',
    '38': 'Ladakh',
    '96': 'Foreign Country',
    '97': 'Other Territory',
  };

  /// "33-Tamil Nadu" (GSTR-1 place-of-supply format), or the bare code if unknown.
  static String stateLabel(String code) =>
      states.containsKey(code) ? '$code-${states[code]}' : code;

  /// GST unit quantity codes (UQC) as in the GSTR-1 template v2.1 master
  /// sheet, plus 'NA' (services in the HSN summary).
  static const uqcCodes = <String, String>{
    'BAG': 'BAGS', 'BAL': 'BALE', 'BDL': 'BUNDLES', 'BKL': 'BUCKLES',
    'BOU': 'BILLION OF UNITS', 'BOX': 'BOX', 'BTL': 'BOTTLES', 'BUN': 'BUNCHES',
    'CAN': 'CANS', 'CBM': 'CUBIC METERS', 'CCM': 'CUBIC CENTIMETERS',
    'CMS': 'CENTIMETERS', 'CTN': 'CARTONS', 'DOZ': 'DOZENS', 'DRM': 'DRUMS',
    'GGK': 'GREAT GROSS', 'GMS': 'GRAMMES', 'GRS': 'GROSS', 'GYD': 'GROSS YARDS',
    'KGS': 'KILOGRAMS', 'KLR': 'KILOLITRE', 'KME': 'KILOMETRE', 'LTR': 'LITRES',
    'MLT': 'MILILITRE', 'MTR': 'METERS', 'MTS': 'METRIC TON', 'NOS': 'NUMBERS',
    'PAC': 'PACKS', 'PCS': 'PIECES', 'PRS': 'PAIRS', 'QTL': 'QUINTAL',
    'ROL': 'ROLLS', 'SET': 'SETS', 'SQF': 'SQUARE FEET', 'SQM': 'SQUARE METERS',
    'SQY': 'SQUARE YARDS', 'TBS': 'TABLETS', 'TGM': 'TEN GROSS',
    'THD': 'THOUSANDS', 'TON': 'TONNES', 'TUB': 'TUBES', 'UGS': 'US GALLONS',
    'UNT': 'UNITS', 'YDS': 'YARDS', 'OTH': 'OTHERS', 'NA': 'NOT APPLICABLE',
  };

  static const _unitAliases = <String, String>{
    'pc': 'PCS', 'pcs': 'PCS', 'piece': 'PCS', 'pieces': 'PCS',
    'no': 'NOS', 'nos': 'NOS', 'number': 'NOS', 'numbers': 'NOS',
    'kg': 'KGS', 'kgs': 'KGS', 'kilo': 'KGS', 'kilogram': 'KGS', 'kilograms': 'KGS',
    'g': 'GMS', 'gm': 'GMS', 'gms': 'GMS', 'gram': 'GMS', 'grams': 'GMS',
    'l': 'LTR', 'lt': 'LTR', 'ltr': 'LTR', 'litre': 'LTR', 'liter': 'LTR',
    'litres': 'LTR', 'liters': 'LTR', 'ml': 'MLT',
    'm': 'MTR', 'mtr': 'MTR', 'meter': 'MTR', 'metre': 'MTR', 'meters': 'MTR',
    'metres': 'MTR', 'cm': 'CMS', 'km': 'KME',
    'pkt': 'PAC', 'packet': 'PAC', 'pack': 'PAC', 'packs': 'PAC',
    'pair': 'PRS', 'pairs': 'PRS', 'dozen': 'DOZ', 'bottle': 'BTL',
    'bottles': 'BTL', 'bags': 'BAG', 'boxes': 'BOX', 'roll': 'ROL',
    'rolls': 'ROL', 'sets': 'SET', 'sqft': 'SQF', 'sq ft': 'SQF',
    'sqm': 'SQM', 'sq m': 'SQM', 'tonne': 'TON', 'tonnes': 'TON', 'ton': 'TON',
    'unit': 'UNT', 'units': 'UNT', 'carton': 'CTN', 'cartons': 'CTN',
    'quintal': 'QTL', 'tablet': 'TBS', 'tablets': 'TBS',
  };

  /// UQC implied by free-text [unit] (an exact code, or a common name like
  /// "kg" / "pcs"); services → 'NA'; null when unknown.
  static String? suggestUqc(String unit, {bool isService = false}) {
    if (isService) return 'NA';
    final u = unit.trim();
    if (uqcCodes.containsKey(u.toUpperCase())) return u.toUpperCase();
    return _unitAliases[u.toLowerCase()];
  }

  /// "PCS-PIECES" (GSTR-1 UQC format), or the bare code if unknown.
  static String uqcLabel(String code) =>
      uqcCodes.containsKey(code) ? '$code-${uqcCodes[code]}' : code;

  /// 2-digit state code (first two digits of a valid GSTIN), or null.
  static String? stateCodeFromGstin(String? gstin) {
    final g = gstin?.trim().toUpperCase() ?? '';
    return _gstinPattern.hasMatch(g) ? g.substring(0, 2) : null;
  }
}
