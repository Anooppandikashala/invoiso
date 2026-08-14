export 'setting_key.dart';
export 'pdf_styles.dart';

enum InvoiceTemplate {
  classic,
  modern,
  minimal,
  executive,
  compact, // A6-optimized compact/receipt template
  thermal, // 80mm/58mm thermal receipt template
  gridClassic, // Bordered grid "old style" bill, adaptive A4/A5/A6
}

class ProductUnits {
  static const List<String> presets = [
    'pcs', 'kg', 'gm', 'ltr', 'ml', 'mtr', 'cm', 'box', 'bag',
    'dozen', 'set', 'pair', 'roll', 'sqft', 'unit',
  ];
}

enum BackupType { database, json }

enum PageSize { a4, a5, a6, thermal80, thermal58 }

extension InvoiceTemplatePageSizeExtension on InvoiceTemplate {
  bool supportsPageSize(PageSize pageSize) {
    switch (pageSize) {
      case PageSize.a6:
        return this == InvoiceTemplate.compact ||
            this == InvoiceTemplate.gridClassic;
      case PageSize.a5:
        return this == InvoiceTemplate.gridClassic;
      case PageSize.thermal80:
      case PageSize.thermal58:
        return this == InvoiceTemplate.thermal;
      case PageSize.a4:
        return this != InvoiceTemplate.compact &&
            this != InvoiceTemplate.thermal;
    }
  }
}

InvoiceTemplate defaultInvoiceTemplateForPageSize(PageSize pageSize) {
  switch (pageSize) {
    case PageSize.a6:
      return InvoiceTemplate.compact;
    case PageSize.a5:
      return InvoiceTemplate.gridClassic;
    case PageSize.thermal80:
    case PageSize.thermal58:
      return InvoiceTemplate.thermal;
    default:
      return InvoiceTemplate.classic;
  }
}

InvoiceTemplate effectiveInvoiceTemplateForPageSize(
  InvoiceTemplate template,
  PageSize pageSize,
) {
  return template.supportsPageSize(pageSize)
      ? template
      : defaultInvoiceTemplateForPageSize(pageSize);
}

extension PageSizeExtension on PageSize {
  String get key {
    switch (this) {
      case PageSize.a4:
        return 'a4';
      case PageSize.a5:
        return 'a5';
      case PageSize.a6:
        return 'a6';
      case PageSize.thermal80:
        return 'thermal80';
      case PageSize.thermal58:
        return 'thermal58';
    }
  }

  String get label {
    switch (this) {
      case PageSize.a4:
        return 'Standard A4';
      case PageSize.a5:
        return 'Standard A5';
      case PageSize.a6:
        return 'Standard A6';
      case PageSize.thermal80:
        return 'Thermal Paper 80mm';
      case PageSize.thermal58:
        return 'Thermal Paper 58mm';
    }
  }

  static PageSize fromKey(String? key) {
    switch (key) {
      case 'a5':
        return PageSize.a5;
      case 'a6':
        return PageSize.a6;
      case 'thermal80':
        return PageSize.thermal80;
      case 'thermal58':
        return PageSize.thermal58;
      default:
        return PageSize.a4;
    }
  }
}

enum DateFormatOption {
  ddmmyyyy, // dd/MM/yyyy  — default
  mmddyyyy, // MM/dd/yyyy  — US
  ddMmmyyyy, // dd MMM yyyy — unambiguous
  yyyymmdd, // yyyy-MM-dd  — ISO
}

extension DateFormatOptionExtension on DateFormatOption {
  String get key {
    switch (this) {
      case DateFormatOption.ddmmyyyy:
        return 'dd/MM/yyyy';
      case DateFormatOption.mmddyyyy:
        return 'MM/dd/yyyy';
      case DateFormatOption.ddMmmyyyy:
        return 'dd MMM yyyy';
      case DateFormatOption.yyyymmdd:
        return 'yyyy-MM-dd';
    }
  }

  String get label {
    switch (this) {
      case DateFormatOption.ddmmyyyy:
        return 'DD/MM/YYYY  (e.g. 15/04/2026)';
      case DateFormatOption.mmddyyyy:
        return 'MM/DD/YYYY  (e.g. 04/15/2026)';
      case DateFormatOption.ddMmmyyyy:
        return 'DD MMM YYYY  (e.g. 15 Apr 2026)';
      case DateFormatOption.yyyymmdd:
        return 'YYYY-MM-DD  (e.g. 2026-04-15)';
    }
  }

  static DateFormatOption fromKey(String? key) {
    switch (key) {
      case 'MM/dd/yyyy':
        return DateFormatOption.mmddyyyy;
      case 'dd MMM yyyy':
        return DateFormatOption.ddMmmyyyy;
      case 'yyyy-MM-dd':
        return DateFormatOption.yyyymmdd;
      default:
        return DateFormatOption.ddmmyyyy;
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
      case BusinessType.product:
        return 'product';
      case BusinessType.service:
        return 'service';
      case BusinessType.both:
        return 'both';
    }
  }

  String get label {
    switch (this) {
      case BusinessType.product:
        return 'Product-based';
      case BusinessType.service:
        return 'Service-based';
      case BusinessType.both:
        return 'Both';
    }
  }

  static BusinessType fromKey(String? key) {
    switch (key) {
      case 'product':
        return BusinessType.product;
      case 'service':
        return BusinessType.service;
      default:
        return BusinessType.both;
    }
  }
}

/// A single UPI payment account entry.
class UpiEntry {
  final String label; // friendly name, e.g. "HDFC Bank" (may be empty)
  final String id; // UPI ID, e.g. "business@okhdfcbank"
  final bool isDefault; // whether this is the default account

  const UpiEntry(
      {required this.label, required this.id, this.isDefault = false});

  Map<String, dynamic> toJson() =>
      {'label': label, 'id': id, 'isDefault': isDefault};

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
  final String label; // friendly name, e.g. "Business Account"
  final String bankName; // e.g. "HDFC Bank"
  final String accountNumber; // e.g. "123456789012"
  final String ifscCode; // e.g. "HDFC0001234"
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

enum TaxMode {
  none,
  global,
  perItem,
}

extension TaxModeExtension on TaxMode {
  String get key {
    switch (this) {
      case TaxMode.none:
        return 'none';
      case TaxMode.global:
        return 'global';
      case TaxMode.perItem:
        return 'per_item';
    }
  }

  static TaxMode fromKey(String? key) {
    switch (key) {
      case 'none':
        return TaxMode.none;
      case 'per_item':
        return TaxMode.perItem;
      default:
        return TaxMode.global;
    }
  }
}

enum LogoPosition { left, right }

/// Returns the label used for a company's tax registration number on PDFs.
/// Falls back to 'GSTIN' for India and for unset countries (backward compat).
String taxLabel(String? country) {
  if (country == null || country.isEmpty || country == 'India') return 'GSTIN';
  return 'Tax/VAT No';
}

/// Returns the label for a personal tax ID field.
/// India → 'PAN', everyone else → 'TIN'.
String panLabel(String? country) {
  if (country == null || country.isEmpty || country == 'India') return 'PAN';
  return 'TIN';
}

/// True if country is unset (backward-compat) or explicitly India.
bool isIndiaCountry(String? country) =>
    country == null || country.isEmpty || country.toLowerCase() == 'india';


enum PaymentStatus {
  unpaid,
  partial,
  paid,
}

extension LogoPositionExtension on LogoPosition {
  String get key {
    switch (this) {
      case LogoPosition.left:
        return 'left';
      case LogoPosition.right:
        return 'right';
    }
  }
}

enum LogoSize { xsmall, small, medium, large }

extension LogoSizeExtension on LogoSize {
  String get key {
    switch (this) {
      case LogoSize.xsmall:
        return 'xsmall';
      case LogoSize.small:
        return 'small';
      case LogoSize.medium:
        return 'medium';
      case LogoSize.large:
        return 'large';
    }
  }

  String get label {
    switch (this) {
      case LogoSize.xsmall:
        return 'X-Small';
      case LogoSize.small:
        return 'Small';
      case LogoSize.medium:
        return 'Medium';
      case LogoSize.large:
        return 'Large';
    }
  }

  /// Logo pixel size used when rendering the company logo on PDFs.
  double get pixelSize {
    switch (this) {
      case LogoSize.xsmall:
        return 40;
      case LogoSize.small:
        return 60;
      case LogoSize.medium:
        return 90;
      case LogoSize.large:
        return 120;
    }
  }
}

LogoSize logoSizeFromKey(String? key) {
  return LogoSize.values.firstWhere(
    (s) => s.key == key,
    orElse: () => LogoSize.medium,
  );
}

enum SignatureSize { small, medium, large }

extension SignatureSizeExtension on SignatureSize {
  String get key {
    switch (this) {
      case SignatureSize.small:
        return 'small';
      case SignatureSize.medium:
        return 'medium';
      case SignatureSize.large:
        return 'large';
    }
  }

  String get label {
    switch (this) {
      case SignatureSize.small:
        return 'Small';
      case SignatureSize.medium:
        return 'Medium';
      case SignatureSize.large:
        return 'Large';
    }
  }

  /// Signature image height (px) at the current default template scale (50 = medium).
  double get pixelHeight {
    switch (this) {
      case SignatureSize.small:
        return 35;
      case SignatureSize.medium:
        return 50;
      case SignatureSize.large:
        return 70;
    }
  }
}

SignatureSize signatureSizeFromKey(String? key) {
  return SignatureSize.values.firstWhere(
    (s) => s.key == key,
    orElse: () => SignatureSize.medium,
  );
}
