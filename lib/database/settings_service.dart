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
}