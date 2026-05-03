
enum InvoiceTemplate
{
  classic,
  modern,
  minimal,
}

enum BackupType
{
  database,
  json
}

enum SettingKey {
  logoPosition,
  invoicePrefix,
  additionalInfo,
  thankYouNote,
  currency,
  upiId,      // kept for backward-compat read only
  showUpiQr,
  upiIds,         // JSON list of UpiEntry objects
  showGstFields,       // whether to show GST/GSTIN fields
  fractionalQuantity,  // whether to allow decimal quantities (e.g. 1.5 hrs)
  quantityLabel,       // default label for the Qty column (e.g. "Words", "Hours")
  logoSize,            // logo size on PDF: 'small' | 'medium' | 'large'
  businessType,        // 'product' | 'service' | 'both'
  showQuantity,        // whether to show quantity field (default true)
  bankAccounts,        // JSON list of BankAccount objects
  showBankDetails,     // whether to show bank details on PDF
  showDiscount,        // whether to show discount column on PDF (default true)
  showTypeTag,         // whether to show product/service tag on invoice items (default true)
  lastUpdateCheck,     // ISO timestamp of last GitHub release API call
  lastKnownLatestVersion, // latest version tag returned by last API call
  lastNotifiedVersion, // version for which the update dialog was last shown
  dateFormat,          // date display pattern: 'dd/MM/yyyy' | 'MM/dd/yyyy' | 'dd MMM yyyy' | 'yyyy-MM-dd'
}

extension SettingKeyExtension on SettingKey
{
  String get key {
    switch (this) {
      case SettingKey.logoPosition:
        return 'logo_position';
      case SettingKey.invoicePrefix:
        return 'invoice_prefix';
      case SettingKey.additionalInfo:
        return 'additional_info';
      case SettingKey.thankYouNote:
        return 'thank_you_note';
      case SettingKey.currency:
        return 'currency';
      case SettingKey.upiId:
        return 'upi_id';
      case SettingKey.showUpiQr:
        return 'show_upi_qr';
      case SettingKey.upiIds:
        return 'upi_ids';
      case SettingKey.showGstFields:
        return 'show_gst_fields';
      case SettingKey.fractionalQuantity:
        return 'fractional_quantity';
      case SettingKey.quantityLabel:
        return 'quantity_label';
      case SettingKey.logoSize:
        return 'logo_size';
      case SettingKey.businessType:
        return 'business_type';
      case SettingKey.showQuantity:
        return 'show_quantity';
      case SettingKey.bankAccounts:
        return 'bank_accounts';
      case SettingKey.showBankDetails:
        return 'show_bank_details';
      case SettingKey.showDiscount:
        return 'show_discount';
      case SettingKey.showTypeTag:
        return 'show_type_tag';
      case SettingKey.lastUpdateCheck:
        return 'last_update_check';
      case SettingKey.lastKnownLatestVersion:
        return 'last_known_latest_version';
      case SettingKey.lastNotifiedVersion:
        return 'last_notified_version';
      case SettingKey.dateFormat:
        return 'date_format';
    }
  }
}

enum DateFormatOption {
  ddmmyyyy,   // dd/MM/yyyy  — default
  mmddyyyy,   // MM/dd/yyyy  — US
  ddMmmyyyy,  // dd MMM yyyy — unambiguous
  yyyymmdd,   // yyyy-MM-dd  — ISO
}

extension DateFormatOptionExtension on DateFormatOption {
  String get key {
    switch (this) {
      case DateFormatOption.ddmmyyyy:  return 'dd/MM/yyyy';
      case DateFormatOption.mmddyyyy:  return 'MM/dd/yyyy';
      case DateFormatOption.ddMmmyyyy: return 'dd MMM yyyy';
      case DateFormatOption.yyyymmdd:  return 'yyyy-MM-dd';
    }
  }

  String get label {
    switch (this) {
      case DateFormatOption.ddmmyyyy:  return 'DD/MM/YYYY  (e.g. 15/04/2026)';
      case DateFormatOption.mmddyyyy:  return 'MM/DD/YYYY  (e.g. 04/15/2026)';
      case DateFormatOption.ddMmmyyyy: return 'DD MMM YYYY  (e.g. 15 Apr 2026)';
      case DateFormatOption.yyyymmdd:  return 'YYYY-MM-DD  (e.g. 2026-04-15)';
    }
  }

  static DateFormatOption fromKey(String? key) {
    switch (key) {
      case 'MM/dd/yyyy':  return DateFormatOption.mmddyyyy;
      case 'dd MMM yyyy': return DateFormatOption.ddMmmyyyy;
      case 'yyyy-MM-dd':  return DateFormatOption.yyyymmdd;
      default:            return DateFormatOption.ddmmyyyy;
    }
  }
}

enum BusinessType {
  product,
  service,
  both,
}

extension BusinessTypeExtension on BusinessType {
  String get key {
    switch (this) {
      case BusinessType.product: return 'product';
      case BusinessType.service: return 'service';
      case BusinessType.both:    return 'both';
    }
  }

  String get label {
    switch (this) {
      case BusinessType.product: return 'Product-based';
      case BusinessType.service: return 'Service-based';
      case BusinessType.both:    return 'Both';
    }
  }

  static BusinessType fromKey(String? key) {
    switch (key) {
      case 'product': return BusinessType.product;
      case 'service': return BusinessType.service;
      default:        return BusinessType.both;
    }
  }
}

/// A single UPI payment account entry.
class UpiEntry {
  final String label;     // friendly name, e.g. "HDFC Bank" (may be empty)
  final String id;        // UPI ID, e.g. "business@okhdfcbank"
  final bool isDefault;   // whether this is the default account

  const UpiEntry({required this.label, required this.id, this.isDefault = false});

  Map<String, dynamic> toJson() => {'label': label, 'id': id, 'isDefault': isDefault};

  factory UpiEntry.fromJson(Map<String, dynamic> json) => UpiEntry(
        label: json['label'] as String? ?? '',
        id: json['id'] as String? ?? '',
        isDefault: json['isDefault'] as bool? ?? false,
      );

  /// Returns the label if set, otherwise falls back to the UPI ID itself.
  String get displayLabel => label.trim().isNotEmpty ? label.trim() : id;
}

/// A single bank account entry.
class BankAccount {
  final String label;         // friendly name, e.g. "Business Account"
  final String bankName;      // e.g. "HDFC Bank"
  final String accountNumber; // e.g. "123456789012"
  final String ifscCode;      // e.g. "HDFC0001234"
  final bool isDefault;

  const BankAccount({
    required this.label,
    required this.bankName,
    required this.accountNumber,
    required this.ifscCode,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'bankName': bankName,
        'accountNumber': accountNumber,
        'ifscCode': ifscCode,
        'isDefault': isDefault,
      };

  factory BankAccount.fromJson(Map<String, dynamic> json) => BankAccount(
        label: json['label'] as String? ?? '',
        bankName: json['bankName'] as String? ?? '',
        accountNumber: json['accountNumber'] as String? ?? '',
        ifscCode: json['ifscCode'] as String? ?? '',
        isDefault: json['isDefault'] as bool? ?? false,
      );

  String get displayLabel =>
      label.trim().isNotEmpty ? label.trim() : bankName.trim();
}

class CurrencyOption {
  final String code;
  final String symbol;
  final String name;

  const CurrencyOption({
    required this.code,
    required this.symbol,
    required this.name,
  });
}

class SupportedCurrencies {
  static const List<CurrencyOption> all = [
    CurrencyOption(code: 'INR', symbol: 'Rs.', name: 'Indian Rupee'),
    CurrencyOption(code: 'USD', symbol: '\$',  name: 'US Dollar'),
    CurrencyOption(code: 'EUR', symbol: '€',   name: 'Euro'),
    CurrencyOption(code: 'GBP', symbol: '£',   name: 'British Pound'),
    CurrencyOption(code: 'JPY', symbol: '¥',   name: 'Japanese Yen'),
    CurrencyOption(code: 'AED', symbol: 'AED', name: 'UAE Dirham'),
    CurrencyOption(code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar'),
    CurrencyOption(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar'),
    CurrencyOption(code: 'CAD', symbol: 'C\$', name: 'Canadian Dollar'),
    CurrencyOption(code: 'JMD', symbol: 'J\$', name: 'Jamaican Dollar'),
    CurrencyOption(code: 'ZAR', symbol: 'R',   name: 'South African Rand'),
  ];

  static CurrencyOption fromCode(String code) {
    return all.firstWhere(
      (c) => c.code == code,
      orElse: () => all.first,
    );
  }
}

enum TaxMode {
  none,
  global,
  perItem,
}

extension TaxModeExtension on TaxMode {
  String get key {
    switch (this) {
      case TaxMode.none:    return 'none';
      case TaxMode.global:  return 'global';
      case TaxMode.perItem: return 'per_item';
    }
  }

  static TaxMode fromKey(String? key) {
    switch (key) {
      case 'none':     return TaxMode.none;
      case 'per_item': return TaxMode.perItem;
      default:         return TaxMode.global;
    }
  }
}

enum LogoPosition
{
  left,
  right
}

/// Returns the label used for a company's tax registration number on PDFs.
/// Falls back to 'GSTIN' for India and for unset countries (backward compat).
String taxLabel(String? country) {
  if (country == null || country.isEmpty || country == 'India') return 'GSTIN';
  return 'Tax/VAT No';
}

/// Full list of world countries (alphabetical).
class AppCountries {
  static const List<String> all = [
    'Afghanistan', 'Albania', 'Algeria', 'Andorra', 'Angola',
    'Antigua and Barbuda', 'Argentina', 'Armenia', 'Australia', 'Austria',
    'Azerbaijan', 'Bahamas', 'Bahrain', 'Bangladesh', 'Barbados',
    'Belarus', 'Belgium', 'Belize', 'Benin', 'Bhutan',
    'Bolivia', 'Bosnia and Herzegovina', 'Botswana', 'Brazil', 'Brunei',
    'Bulgaria', 'Burkina Faso', 'Burundi', 'Cabo Verde', 'Cambodia',
    'Cameroon', 'Canada', 'Central African Republic', 'Chad', 'Chile',
    'China', 'Colombia', 'Comoros', 'Congo (Brazzaville)', 'Congo (Kinshasa)',
    'Costa Rica', 'Croatia', 'Cuba', 'Cyprus', 'Czech Republic',
    'Denmark', 'Djibouti', 'Dominica', 'Dominican Republic', 'Ecuador',
    'Egypt', 'El Salvador', 'Equatorial Guinea', 'Eritrea', 'Estonia',
    'Eswatini', 'Ethiopia', 'Fiji', 'Finland', 'France',
    'Gabon', 'Gambia', 'Georgia', 'Germany', 'Ghana',
    'Greece', 'Grenada', 'Guatemala', 'Guinea', 'Guinea-Bissau',
    'Guyana', 'Haiti', 'Honduras', 'Hungary', 'Iceland',
    'India', 'Indonesia', 'Iran', 'Iraq', 'Ireland',
    'Israel', 'Italy', 'Jamaica', 'Japan', 'Jordan',
    'Kazakhstan', 'Kenya', 'Kiribati', 'Kosovo', 'Kuwait',
    'Kyrgyzstan', 'Laos', 'Latvia', 'Lebanon', 'Lesotho',
    'Liberia', 'Libya', 'Liechtenstein', 'Lithuania', 'Luxembourg',
    'Madagascar', 'Malawi', 'Malaysia', 'Maldives', 'Mali',
    'Malta', 'Marshall Islands', 'Mauritania', 'Mauritius', 'Mexico',
    'Micronesia', 'Moldova', 'Monaco', 'Mongolia', 'Montenegro',
    'Morocco', 'Mozambique', 'Myanmar', 'Namibia', 'Nauru',
    'Nepal', 'Netherlands', 'New Zealand', 'Nicaragua', 'Niger',
    'Nigeria', 'North Korea', 'North Macedonia', 'Norway', 'Oman',
    'Pakistan', 'Palau', 'Palestine', 'Panama', 'Papua New Guinea',
    'Paraguay', 'Peru', 'Philippines', 'Poland', 'Portugal',
    'Qatar', 'Romania', 'Russia', 'Rwanda', 'Saint Kitts and Nevis',
    'Saint Lucia', 'Saint Vincent and the Grenadines', 'Samoa', 'San Marino', 'Sao Tome and Principe',
    'Saudi Arabia', 'Senegal', 'Serbia', 'Seychelles', 'Sierra Leone',
    'Singapore', 'Slovakia', 'Slovenia', 'Solomon Islands', 'Somalia',
    'South Africa', 'South Korea', 'South Sudan', 'Spain', 'Sri Lanka',
    'Sudan', 'Suriname', 'Sweden', 'Switzerland', 'Syria',
    'Taiwan', 'Tajikistan', 'Tanzania', 'Thailand', 'Timor-Leste',
    'Togo', 'Tonga', 'Trinidad and Tobago', 'Tunisia', 'Turkey',
    'Turkmenistan', 'Tuvalu', 'Uganda', 'Ukraine', 'United Arab Emirates',
    'United Kingdom', 'United States', 'Uruguay', 'Uzbekistan', 'Vanuatu',
    'Vatican City', 'Venezuela', 'Vietnam', 'Yemen', 'Zambia', 'Zimbabwe',
  ];
}

enum PaymentStatus {
  unpaid,
  partial,
  paid,
}

extension LogoPositionExtension on LogoPosition
{
  String get key {
    switch (this) {
      case LogoPosition.left:
        return 'left';
      case LogoPosition.right:
        return 'right';
    }
  }
}