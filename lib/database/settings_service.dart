import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../common.dart';
import 'database_helper.dart';


class SettingsService
{
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
    final result = await db.query('settings',
        where: 'key = ?', whereArgs: ['invoice_template']);

    if (result.isNotEmpty) {
      return InvoiceTemplate.values.firstWhere(
            (e) => e.name == result.first['value'],
        orElse: () => InvoiceTemplate.classic,
      );
    }
    return InvoiceTemplate.classic;
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
    final result = await db.query('settings', where: 'key = ?', whereArgs: ['company_logo']);
    return result.isNotEmpty ? result.first['value'] as String : null;
  }

  // general services
  static Future<void> setSetting(SettingKey key, String value) async
  {
    final db = await dbHelper.database;
    await db.insert(
      'settings',
      {'key': key.key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<LogoPosition> getLogoPosition() async
  {
      String pos = await getSetting(SettingKey.logoPosition) ?? "left";
      if(pos == "right")
      {
        return LogoPosition.right;
      }
      return LogoPosition.left;
  }

  static Future<String?> getSetting(SettingKey key) async
  {
    final db = await dbHelper.database;
    final result =
    await db.query('settings', where: 'key = ?', whereArgs: [key.key]);
    return result.isNotEmpty ? result.first['value'] as String : null;
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

  /// Returns whether GST/GSTIN fields should be shown.
  /// Defaults to true so existing users are unaffected.
  static Future<bool> getShowGstFields() async {
    final val = await getSetting(SettingKey.showGstFields);
    return val != 'false';
  }

  static Future<bool> getFractionalQuantity() async {
    final val = await getSetting(SettingKey.fractionalQuantity);
    return val == 'true';  // off by default
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

  static Future<bool> getShowBankDetails() async {
    final val = await getSetting(SettingKey.showBankDetails);
    return val == 'true';
  }

  static Future<void> setShowBankDetails(bool show) async {
    await setSetting(SettingKey.showBankDetails, show.toString());
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

  static Future<DateFormatOption> getDateFormat() async {
    final val = await getSetting(SettingKey.dateFormat);
    return DateFormatOptionExtension.fromKey(val);
  }

  static Future<void> setDateFormat(DateFormatOption option) async {
    await setSetting(SettingKey.dateFormat, option.key);
  }
}