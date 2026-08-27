import 'package:flutter/widgets.dart';
import 'package:invoiso/l10n/app_localizations.dart';

export 'setting_key.dart';
export 'pdf_styles.dart';

/// Shared "X-Small"/"Small"/"Medium"/"Large" labels for [LogoSize],
/// [SignatureSize], and [ThermalCompanyNameSize] — same wording, so one
/// ARB key set covers all three instead of tripling near-identical keys.
String _genericSizeLabel(BuildContext context, String key) {
  final l10n = AppLocalizations.of(context)!;
  switch (key) {
    case 'xsmall':
      return l10n.sizeXSmallLabel;
    case 'small':
      return l10n.sizeSmallLabel;
    case 'medium':
      return l10n.sizeMediumLabel;
    default:
      return l10n.sizeLargeLabel;
  }
}

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
    'pcs',
    'kg',
    'gm',
    'ltr',
    'ml',
    'mtr',
    'cm',
    'box',
    'bag',
    'dozen',
    'set',
    'pair',
    'roll',
    'sqft',
    'unit',
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

String pageSizeLabel(BuildContext context, PageSize size) {
  final l10n = AppLocalizations.of(context)!;
  switch (size) {
    case PageSize.a4:
      return l10n.pageSizeA4Label;
    case PageSize.a5:
      return l10n.pageSizeA5Label;
    case PageSize.a6:
      return l10n.pageSizeA6Label;
    case PageSize.thermal80:
      return l10n.pageSizeThermal80Label;
    case PageSize.thermal58:
      return l10n.pageSizeThermal58Label;
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

String dateFormatOptionLabel(BuildContext context, DateFormatOption option) {
  final l10n = AppLocalizations.of(context)!;
  switch (option) {
    case DateFormatOption.ddmmyyyy:
      return l10n.dateFormatDdmmyyyyLabel;
    case DateFormatOption.mmddyyyy:
      return l10n.dateFormatMmddyyyyLabel;
    case DateFormatOption.ddMmmyyyy:
      return l10n.dateFormatDdMmmyyyyLabel;
    case DateFormatOption.yyyymmdd:
      return l10n.dateFormatYyyymmddLabel;
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

String logoSizeLabel(BuildContext context, LogoSize size) =>
    _genericSizeLabel(context, size.key);

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

String signatureSizeLabel(BuildContext context, SignatureSize size) =>
    _genericSizeLabel(context, size.key);

/// Which optional Product fields (and the unrelated invoice Extra Cost
/// field, bundled in here for a single settings screen) are shown/editable.
/// All default true so existing installs see zero behavior change until
/// they opt into hiding fields. Name and Price are never toggleable —
/// intentionally absent from this class.
class ProductColumnsConfig {
  final bool aliasName;
  final bool taxRate;
  final bool hsncode;
  final bool description;
  final bool purchasePrice;
  final bool defaultDiscount;
  final bool unit;
  final bool type;
  final bool extraCost;
  final bool stock;
  final bool productMetadata;
  final bool metaStorageLocation;
  final bool metaContainerNumber;
  final bool metaBatchNumber;
  final bool metaExpiryDate;
  final bool metaManufactureDate;
  final bool metaSupplierName;
  final bool metaSkuCode;
  final bool metaNotes;

  const ProductColumnsConfig({
    this.aliasName = true,
    this.taxRate = true,
    this.hsncode = true,
    this.description = true,
    this.purchasePrice = true,
    this.defaultDiscount = true,
    this.unit = true,
    this.type = true,
    this.extraCost = true,
    this.stock = true,
    this.productMetadata = true,
    this.metaStorageLocation = true,
    this.metaContainerNumber = true,
    this.metaBatchNumber = true,
    this.metaExpiryDate = true,
    this.metaManufactureDate = true,
    this.metaSupplierName = true,
    this.metaSkuCode = true,
    this.metaNotes = true,
  });

  Map<String, dynamic> toJson() => {
        'aliasName': aliasName,
        'taxRate': taxRate,
        'hsncode': hsncode,
        'description': description,
        'purchasePrice': purchasePrice,
        'defaultDiscount': defaultDiscount,
        'unit': unit,
        'type': type,
        'extraCost': extraCost,
        'stock': stock,
        'productMetadata': productMetadata,
        'metaStorageLocation': metaStorageLocation,
        'metaContainerNumber': metaContainerNumber,
        'metaBatchNumber': metaBatchNumber,
        'metaExpiryDate': metaExpiryDate,
        'metaManufactureDate': metaManufactureDate,
        'metaSupplierName': metaSupplierName,
        'metaSkuCode': metaSkuCode,
        'metaNotes': metaNotes,
      };

  factory ProductColumnsConfig.fromJson(Map<String, dynamic> json) =>
      ProductColumnsConfig(
        aliasName: json['aliasName'] as bool? ?? true,
        taxRate: json['taxRate'] as bool? ?? true,
        hsncode: json['hsncode'] as bool? ?? true,
        description: json['description'] as bool? ?? true,
        purchasePrice: json['purchasePrice'] as bool? ?? true,
        defaultDiscount: json['defaultDiscount'] as bool? ?? true,
        unit: json['unit'] as bool? ?? true,
        type: json['type'] as bool? ?? true,
        extraCost: json['extraCost'] as bool? ?? true,
        stock: json['stock'] as bool? ?? true,
        productMetadata: json['productMetadata'] as bool? ?? true,
        metaStorageLocation: json['metaStorageLocation'] as bool? ?? true,
        metaContainerNumber: json['metaContainerNumber'] as bool? ?? true,
        metaBatchNumber: json['metaBatchNumber'] as bool? ?? true,
        metaExpiryDate: json['metaExpiryDate'] as bool? ?? true,
        metaManufactureDate: json['metaManufactureDate'] as bool? ?? true,
        metaSupplierName: json['metaSupplierName'] as bool? ?? true,
        metaSkuCode: json['metaSkuCode'] as bool? ?? true,
        metaNotes: json['metaNotes'] as bool? ?? true,
      );

  ProductColumnsConfig copyWith({
    bool? aliasName,
    bool? taxRate,
    bool? hsncode,
    bool? description,
    bool? purchasePrice,
    bool? defaultDiscount,
    bool? unit,
    bool? type,
    bool? extraCost,
    bool? stock,
    bool? productMetadata,
    bool? metaStorageLocation,
    bool? metaContainerNumber,
    bool? metaBatchNumber,
    bool? metaExpiryDate,
    bool? metaManufactureDate,
    bool? metaSupplierName,
    bool? metaSkuCode,
    bool? metaNotes,
  }) =>
      ProductColumnsConfig(
        aliasName: aliasName ?? this.aliasName,
        taxRate: taxRate ?? this.taxRate,
        hsncode: hsncode ?? this.hsncode,
        description: description ?? this.description,
        purchasePrice: purchasePrice ?? this.purchasePrice,
        defaultDiscount: defaultDiscount ?? this.defaultDiscount,
        unit: unit ?? this.unit,
        type: type ?? this.type,
        extraCost: extraCost ?? this.extraCost,
        stock: stock ?? this.stock,
        productMetadata: productMetadata ?? this.productMetadata,
        metaStorageLocation: metaStorageLocation ?? this.metaStorageLocation,
        metaContainerNumber: metaContainerNumber ?? this.metaContainerNumber,
        metaBatchNumber: metaBatchNumber ?? this.metaBatchNumber,
        metaExpiryDate: metaExpiryDate ?? this.metaExpiryDate,
        metaManufactureDate: metaManufactureDate ?? this.metaManufactureDate,
        metaSupplierName: metaSupplierName ?? this.metaSupplierName,
        metaSkuCode: metaSkuCode ?? this.metaSkuCode,
        metaNotes: metaNotes ?? this.metaNotes,
      );
}

enum InvoiceDiscountType {
  percent,
  amount,
}

extension InvoiceDiscountTypeExtension on InvoiceDiscountType {
  String get key {
    switch (this) {
      case InvoiceDiscountType.percent:
        return 'percent';
      case InvoiceDiscountType.amount:
        return 'amount';
    }
  }

  static InvoiceDiscountType fromKey(String? key) {
    switch (key) {
      case 'amount':
        return InvoiceDiscountType.amount;
      default:
        return InvoiceDiscountType.percent;
    }
  }
}

enum ThermalCompanyNameSize { xsmall, small, medium, large }

extension ThermalCompanyNameSizeExtension on ThermalCompanyNameSize {
  String get key {
    switch (this) {
      case ThermalCompanyNameSize.xsmall:
        return 'xsmall';
      case ThermalCompanyNameSize.small:
        return 'small';
      case ThermalCompanyNameSize.medium:
        return 'medium';
      case ThermalCompanyNameSize.large:
        return 'large';
    }
  }

  /// Multiplier applied to [PdfLayout.thermalPrinterHeadFontSize] for the
  /// company name on thermal receipts. 'medium' matches the previous
  /// hardcoded 0.9 factor so existing receipts don't change by default.
  double get scale {
    switch (this) {
      case ThermalCompanyNameSize.xsmall:
        return 0.7;
      case ThermalCompanyNameSize.small:
        return 0.8;
      case ThermalCompanyNameSize.medium:
        return 0.9;
      case ThermalCompanyNameSize.large:
        return 1.1;
    }
  }
}

ThermalCompanyNameSize thermalCompanyNameSizeFromKey(String? key) {
  return ThermalCompanyNameSize.values.firstWhere(
    (s) => s.key == key,
    orElse: () => ThermalCompanyNameSize.medium,
  );
}

String thermalCompanyNameSizeLabel(
        BuildContext context, ThermalCompanyNameSize size) =>
    _genericSizeLabel(context, size.key);
