import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'package:invoiso/common/common.dart';
import '../common/supported_currencies.dart';
import '../models/custom_field_def.dart';
import 'database_helper.dart';

class SettingsService {
  static final dbHelper = DatabaseHelper();

  static Future<void> setInvoiceTemplate(InvoiceTemplate template) async {
    final db = await dbHelper.database;
    await db.insert(
      'settings',
      {'key': 'invoice_template', 'value': template.name},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<InvoiceTemplate> getInvoiceTemplate() async {
    final db = await dbHelper.database;
    final result = await db
        .query('settings', where: 'key = ?', whereArgs: ['invoice_template']);

    if (result.isNotEmpty) {
      return InvoiceTemplate.values.firstWhere(
        (e) => e.name == result.first['value'],
        orElse: () => InvoiceTemplate.classic,
      );
    }
    return InvoiceTemplate.classic;
  }

  static Future<void> setPdfThemeColor(String hexColor) async {
    await setSetting(
        SettingKey.pdfThemeColor, normalizePdfThemeColor(hexColor));
  }

  static Future<void> clearPdfThemeColor() async {
    final db = await dbHelper.database;
    await db.delete(
      'settings',
      where: 'key = ?',
      whereArgs: [SettingKey.pdfThemeColor.key],
    );
  }

  static Future<String?> getPdfThemeColor() async {
    final value = await getSetting(SettingKey.pdfThemeColor);
    if (value == null || value.trim().isEmpty) return null;
    try {
      return normalizePdfThemeColor(value);
    } catch (_) {
      return null;
    }
  }

  static String normalizePdfThemeColor(String hexColor) {
    final normalized = hexColor.trim().replaceFirst('#', '').toUpperCase();
    if (!RegExp(r'^[0-9A-F]{6}$').hasMatch(normalized)) {
      throw ArgumentError('PDF theme color must be a 6-digit hex value.');
    }
    return '#$normalized';
  }

  static Future<void> setCompanyLogo(String base64Logo) async {
    final db = await dbHelper.database;
    await db.insert(
      'settings',
      {'key': 'company_logo', 'value': base64Logo},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<String?> getCompanyLogo() async {
    final db = await dbHelper.database;
    final result = await db
        .query('settings', where: 'key = ?', whereArgs: ['company_logo']);
    return result.isNotEmpty ? result.first['value'] as String : null;
  }

  // general services
  static Future<void> setSetting(SettingKey key, String value) async {
    final db = await dbHelper.database;
    await db.insert(
      'settings',
      {'key': key.key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<LogoPosition> getLogoPosition() async {
    String pos = await getSetting(SettingKey.logoPosition) ?? "left";
    if (pos == "right") {
      return LogoPosition.right;
    }
    return LogoPosition.left;
  }

  static Future<String?> getSetting(SettingKey key) async {
    final db = await dbHelper.database;
    final result =
        await db.query('settings', where: 'key = ?', whereArgs: [key.key]);
    return result.isNotEmpty ? result.first['value'] as String : null;
  }

  static Future<void> deleteSetting(SettingKey key) async {
    final db = await dbHelper.database;
    await db.delete('settings', where: 'key = ?', whereArgs: [key.key]);
  }

  static Future<void> setCurrency(String currencyCode) async {
    await setSetting(SettingKey.currency, currencyCode);
  }

  static Future<CurrencyOption> getCurrency() async {
    final code = await getSetting(SettingKey.currency) ?? 'INR';
    return SupportedCurrencies.fromCode(code);
  }

  /// Returns the list of saved UPI accounts.
  /// Falls back to the old single [SettingKey.upiId] value for users upgrading
  /// from a previous version that had only one UPI ID field.
  static Future<List<UpiEntry>> getUpiIds() async {
    final json = await getSetting(SettingKey.upiIds);
    if (json != null && json.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(json);
      return decoded
          .map((e) => UpiEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    // Backward-compat: migrate old single UPI ID to list format.
    final oldId = await getSetting(SettingKey.upiId);
    if (oldId != null && oldId.trim().isNotEmpty) {
      return [UpiEntry(label: '', id: oldId.trim(), isDefault: true)];
    }
    return [];
  }

  static Future<void> setUpiIds(List<UpiEntry> entries) async {
    final encoded = jsonEncode(entries.map((e) => e.toJson()).toList());
    await setSetting(SettingKey.upiIds, encoded);
  }

  /// Default custom-field definitions, matching the reference Tally-style
  /// GST invoice grid — seeded once so users get a working starting point
  /// instead of a blank list. Freely deletable/renameable afterward.
  static const List<String> _defaultCustomFieldLabels = [
    'Delivery Note',
    'Mode/Terms of Payment',
    'Reference No. & Date',
    'Other References',
    "Buyer's Order No.",
    "Buyer's Order Date",
    'Dispatch Doc No.',
    'Delivery Note Date',
    'Dispatched Through',
    'Destination',
    'Bill of Lading/LR-RR No.',
    'Motor Vehicle No.',
    'Terms of Delivery',
  ];

  /// Returns the saved custom-field definitions. On first-ever call (no
  /// settings row yet — distinct from an explicitly saved empty list after
  /// the user deletes every default) seeds and persists the default list.
  static Future<List<CustomFieldDef>> getCustomFieldDefs() async {
    final json = await getSetting(SettingKey.customFieldDefs);
    if (json == null) {
      final defaults = [
        for (var i = 0; i < _defaultCustomFieldLabels.length; i++)
          CustomFieldDef(
              id: 'cf-${i + 1}', label: _defaultCustomFieldLabels[i], sortOrder: i),
      ];
      await setCustomFieldDefs(defaults);
      return defaults;
    }
    return CustomFieldDef.listFromJson(json);
  }

  static Future<void> setCustomFieldDefs(List<CustomFieldDef> defs) async {
    await setSetting(SettingKey.customFieldDefs, CustomFieldDef.listToJson(defs));
  }

  /// Returns whether GST/GSTIN fields should be shown.
  /// Defaults to true so existing users are unaffected.
  static Future<bool> getShowGstFields() async {
    final val = await getSetting(SettingKey.showGstFields);
    return val != 'false';
  }

  static Future<bool> getShowInvoiceFooterBranding() async {
    final val = await getSetting(SettingKey.showInvoiceFooterBranding);
    return val != 'false'; // default ON
  }

  static Future<bool> getFractionalQuantity() async {
    final val = await getSetting(SettingKey.fractionalQuantity);
    return val == 'true'; // off by default
  }

  static Future<String> getQuantityLabel() async {
    return await getSetting(SettingKey.quantityLabel) ?? '';
  }

  /// Returns the logo size key: 'small' | 'medium' | 'large'. Defaults to 'medium'.
  static Future<String> getLogoSize() async {
    return await getSetting(SettingKey.logoSize) ?? 'medium';
  }

  static Future<BusinessType> getBusinessType() async {
    final val = await getSetting(SettingKey.businessType);
    return BusinessTypeExtension.fromKey(val);
  }

  static Future<void> setBusinessType(BusinessType type) async {
    await setSetting(SettingKey.businessType, type.key);
  }

  /// Whether the quantity field is shown. Defaults to true.
  static Future<bool> getShowQuantity() async {
    final val = await getSetting(SettingKey.showQuantity);
    return val != 'false';
  }

  static Future<void> setShowQuantity(bool show) async {
    await setSetting(SettingKey.showQuantity, show.toString());
  }

  static Future<List<BankAccount>> getBankAccounts() async {
    final json = await getSetting(SettingKey.bankAccounts);
    if (json != null && json.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(json);
      return decoded
          .map((e) => BankAccount.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  static Future<void> setBankAccounts(List<BankAccount> accounts) async {
    final encoded = jsonEncode(accounts.map((e) => e.toJson()).toList());
    await setSetting(SettingKey.bankAccounts, encoded);
  }

  static Future<ProductColumnsConfig> getProductColumnsConfig() async {
    final json = await getSetting(SettingKey.productColumnsConfig);
    if (json != null && json.isNotEmpty) {
      return ProductColumnsConfig.fromJson(jsonDecode(json) as Map<String, dynamic>);
    }
    return const ProductColumnsConfig();
  }

  static Future<void> setProductColumnsConfig(ProductColumnsConfig config) async {
    await setSetting(SettingKey.productColumnsConfig, jsonEncode(config.toJson()));
  }

  /// Which optional columns are visible in the product list table.
  /// Stored keys only; absent keys fall back to the screen's defaults.
  static Future<Map<String, bool>> getProductListColumns() async {
    final json = await getSetting(SettingKey.productListColumnsConfig);
    if (json == null || json.isEmpty) return const {};
    final m = jsonDecode(json) as Map<String, dynamic>;
    return m.map((k, v) => MapEntry(k, v == true));
  }

  static Future<void> setProductListColumns(Map<String, bool> cols) async {
    await setSetting(SettingKey.productListColumnsConfig, jsonEncode(cols));
  }

  static Future<bool> getShowBankDetails() async {
    final val = await getSetting(SettingKey.showBankDetails);
    return val == 'true';
  }

  static Future<void> setShowBankDetails(bool show) async {
    await setSetting(SettingKey.showBankDetails, show.toString());
  }

  /// Whether the company phone is shown on PDFs. Defaults to true.
  static Future<bool> getShowPhone() async {
    final val = await getSetting(SettingKey.showPhone);
    return val != 'false';
  }

  static Future<void> setShowPhone(bool show) async {
    await setSetting(SettingKey.showPhone, show.toString());
  }

  /// Whether the company email is shown on PDFs. Defaults to true.
  static Future<bool> getShowEmail() async {
    final val = await getSetting(SettingKey.showEmail);
    return val != 'false';
  }

  static Future<void> setShowEmail(bool show) async {
    await setSetting(SettingKey.showEmail, show.toString());
  }

  /// Whether the company name is shown on PDFs. Defaults to true.
  static Future<bool> getShowCompanyName() async {
    final val = await getSetting(SettingKey.showCompanyName);
    return val != 'false';
  }

  static Future<void> setShowCompanyName(bool show) async {
    await setSetting(SettingKey.showCompanyName, show.toString());
  }

  /// Whether the company PAN is shown on PDFs. Defaults to true.
  static Future<bool> getShowPan() async {
    final val = await getSetting(SettingKey.showPan);
    return val != 'false';
  }

  static Future<void> setShowPan(bool show) async {
    await setSetting(SettingKey.showPan, show.toString());
  }

  /// Whether the company FSSAI code is shown on PDFs. Defaults to true.
  static Future<bool> getShowFssai() async {
    final val = await getSetting(SettingKey.showFssai);
    return val != 'false';
  }

  static Future<void> setShowFssai(bool show) async {
    await setSetting(SettingKey.showFssai, show.toString());
  }

  /// Whether the company website is shown on PDFs. Defaults to true.
  static Future<bool> getShowWebsite() async {
    final val = await getSetting(SettingKey.showWebsite);
    return val != 'false';
  }

  static Future<void> setShowWebsite(bool show) async {
    await setSetting(SettingKey.showWebsite, show.toString());
  }

  /// Whether the company address is shown on PDFs. Defaults to true.
  static Future<bool> getShowAddress() async {
    final val = await getSetting(SettingKey.showAddress);
    return val != 'false';
  }

  static Future<void> setShowAddress(bool show) async {
    await setSetting(SettingKey.showAddress, show.toString());
  }

  /// Whether the company logo is shown on PDFs. Defaults to true.
  static Future<bool> getShowLogo() async {
    final val = await getSetting(SettingKey.showLogo);
    return val != 'false';
  }

  static Future<void> setShowLogo(bool show) async {
    await setSetting(SettingKey.showLogo, show.toString());
  }

  /// Whether the customer business name is shown on PDFs. Defaults to true.
  static Future<bool> getShowCustomerBusinessName() async {
    final val = await getSetting(SettingKey.showCustomerBusinessNameInPdf);
    return val != 'false';
  }

  static Future<void> setShowCustomerBusinessName(bool show) async {
    await setSetting(
        SettingKey.showCustomerBusinessNameInPdf, show.toString());
  }

  /// Whether the customer address is shown on PDFs. Defaults to true.
  static Future<bool> getShowCustomerAddress() async {
    final val = await getSetting(SettingKey.showCustomerAddressInPdf);
    return val != 'false';
  }

  static Future<void> setShowCustomerAddress(bool show) async {
    await setSetting(SettingKey.showCustomerAddressInPdf, show.toString());
  }

  /// Whether the customer phone is shown on PDFs. Defaults to true.
  static Future<bool> getShowCustomerPhone() async {
    final val = await getSetting(SettingKey.showCustomerPhoneInPdf);
    return val != 'false';
  }

  static Future<void> setShowCustomerPhone(bool show) async {
    await setSetting(SettingKey.showCustomerPhoneInPdf, show.toString());
  }

  /// Whether the customer email is shown on PDFs. Defaults to true.
  static Future<bool> getShowCustomerEmail() async {
    final val = await getSetting(SettingKey.showCustomerEmailInPdf);
    return val != 'false';
  }

  static Future<void> setShowCustomerEmail(bool show) async {
    await setSetting(SettingKey.showCustomerEmailInPdf, show.toString());
  }

  /// Whether the customer GSTIN/tax id is shown on PDFs. Defaults to true.
  static Future<bool> getShowCustomerGstin() async {
    final val = await getSetting(SettingKey.showCustomerGstinInPdf);
    return val != 'false';
  }

  static Future<void> setShowCustomerGstin(bool show) async {
    await setSetting(SettingKey.showCustomerGstinInPdf, show.toString());
  }

  /// Whether the invoice creation time is shown on PDFs. Defaults to true.
  static Future<bool> getShowTimeInPdf() async {
    final val = await getSetting(SettingKey.showTimeInPdf);
    return val != 'false';
  }

  static Future<void> setShowTimeInPdf(bool show) async {
    await setSetting(SettingKey.showTimeInPdf, show.toString());
  }

  /// PDF time format: '24' (HH:mm) or '12' (h:mm a). Defaults to '24'.
  static Future<String> getPdfTimeFormat() async {
    final val = await getSetting(SettingKey.pdfTimeFormat);
    return val == '12' ? '12' : '24';
  }

  static Future<void> setPdfTimeFormat(String format) async {
    await setSetting(SettingKey.pdfTimeFormat, format == '12' ? '12' : '24');
  }

  /// Whether the Sl No column prints in the A4/Letter items table. Defaults to true.
  static Future<bool> getShowSlNoInPdf() async {
    final val = await getSetting(SettingKey.showSlNoInPdf);
    return val != 'false';
  }

  static Future<void> setShowSlNoInPdf(bool show) async {
    await setSetting(SettingKey.showSlNoInPdf, show.toString());
  }

  /// Whether the Grid Classic invoice PDF renders in landscape. Defaults to false.
  static Future<bool> getPdfLandscape() async {
    final val = await getSetting(SettingKey.pdfLandscape);
    return val == 'true';
  }

  static Future<void> setPdfLandscape(bool landscape) async {
    await setSetting(SettingKey.pdfLandscape, landscape.toString());
  }

  static Future<bool> getShowDiscount() async {
    final val = await getSetting(SettingKey.showDiscount);
    return val != 'false'; // default true
  }

  static Future<void> setShowDiscount(bool show) async {
    await setSetting(SettingKey.showDiscount, show.toString());
  }

  static Future<bool> getShowTypeTag() async {
    final val = await getSetting(SettingKey.showTypeTag);
    return val != 'false'; // default true
  }

  static Future<void> setShowTypeTag(bool show) async {
    await setSetting(SettingKey.showTypeTag, show.toString());
  }

  static Future<void> setSignatureImage(String base64Image) async {
    await setSetting(SettingKey.signatureImage, base64Image);
  }

  static Future<String?> getSignatureImage() async {
    return getSetting(SettingKey.signatureImage);
  }

  static Future<void> setWatermarkImage(String base64Image) async {
    await setSetting(SettingKey.watermarkImage, base64Image);
  }

  static Future<String?> getWatermarkImage() async {
    return getSetting(SettingKey.watermarkImage);
  }

  static Future<void> setWatermarkOpacity(double opacity) async {
    await setSetting(SettingKey.watermarkOpacity, opacity.toString());
  }

  static Future<double> getWatermarkOpacity() async {
    final val = await getSetting(SettingKey.watermarkOpacity);
    return val != null ? double.tryParse(val) ?? 0.12 : 0.12;
  }

  static Future<void> setDefaultInvoiceTitle(String? title) async {
    await setSetting(SettingKey.defaultInvoiceTitle, title ?? '');
  }

  static Future<String?> getDefaultInvoiceTitle() async {
    final val = await getSetting(SettingKey.defaultInvoiceTitle);
    return (val == null || val.isEmpty) ? null : val;
  }

  static Future<String> getSignaturePosition() async {
    return await getSetting(SettingKey.signaturePosition) ?? 'left';
  }

  static Future<String> getDefaultTaxMode() async {
    return await getSetting(SettingKey.defaultTaxMode) ?? 'global';
  }

  /// Returns the signature size key: 'small' | 'medium' | 'large'. Defaults to 'medium'.
  static Future<String> getSignatureSize() async {
    return await getSetting(SettingKey.signatureSize) ?? 'medium';
  }

  static Future<bool> getShowPreviousBalance() async {
    final val = await getSetting(SettingKey.showPreviousBalance);
    return val == 'true';
  }

  static Future<void> setShowPreviousBalance(bool show) async {
    await setSetting(SettingKey.showPreviousBalance, show.toString());
  }

  static Future<DateFormatOption> getDateFormat() async {
    final val = await getSetting(SettingKey.dateFormat);
    return DateFormatOptionExtension.fromKey(val);
  }

  static Future<void> setDateFormat(DateFormatOption option) async {
    await setSetting(SettingKey.dateFormat, option.key);
  }

  static Future<PageSize> getPageSize() async {
    final val = await getSetting(SettingKey.pageSize);
    return PageSizeExtension.fromKey(val);
  }

  static Future<void> setPageSize(PageSize size) async {
    await setSetting(SettingKey.pageSize, size.key);
  }

  static Future<bool> getShowTotalQuantity() async {
    final val = await getSetting(SettingKey.showTotalQuantity);
    return val == 'true';
  }

  static Future<void> setShowTotalQuantity(bool show) async {
    await setSetting(SettingKey.showTotalQuantity, show.toString());
  }

  static Future<bool> getShowAliasNameInPdf() async
  {
    final val = await getSetting(SettingKey.showAliasNameInPdf);
    return val == 'true';
  }

  static Future<bool> getShowTaxButtonInInvoicePage() async
  {
    final val = await getSetting(SettingKey.showTaxButtonInInvoicePage);
    return val != 'false';
  }

  static Future<bool> getHideInvoiceNumberByDefault() async {
    final val = await getSetting(SettingKey.hideInvoiceNumberByDefault);
    return val == 'true';
  }

  static Future<String> getThemeMode() async {
    final val = await getSetting(SettingKey.themeMode);
    return val ?? 'system';
  }

  static Future<void> setThemeMode(String mode) async {
    await setSetting(SettingKey.themeMode, mode);
  }

  static Future<String?> getAppLocale() async {
    return await getSetting(SettingKey.appLocale);
  }

  static Future<void> setAppLocale(String? languageCode) async {
    if (languageCode == null) {
      await deleteSetting(SettingKey.appLocale);
    } else {
      await setSetting(SettingKey.appLocale, languageCode);
    }
  }

  static Future<bool> getAllowDuplicateInvoiceItems() async {
    return await getSetting(SettingKey.allowDuplicateInvoiceItems) == 'true';
  }

  static Future<void> setAllowDuplicateInvoiceItems(bool allow) async {
    await setSetting(SettingKey.allowDuplicateInvoiceItems, allow.toString());
  }
}
