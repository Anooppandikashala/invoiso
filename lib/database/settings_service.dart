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
}