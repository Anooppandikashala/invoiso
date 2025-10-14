import 'package:invoiso/models/company_info.dart';
import 'database_helper.dart';

class CompanyInfoService
{
  static final dbHelper = DatabaseHelper();

  static Future<CompanyInfo?> getCompanyInfo() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> result = await db.query('company_info', limit: 1);

    if (result.isNotEmpty) {
      return CompanyInfo.fromMap(result.first);
    }
    return null;
  }

  static Future<int> insertCompanyInfo(CompanyInfo info) async {
    final db = await dbHelper.database;
    return await db.insert('company_info', info.toMap());
  }

  static Future<int> updateCompanyInfo(CompanyInfo info) async {
    final db = await dbHelper.database;
    return await db.update(
      'company_info',
      info.toMap(),
      where: 'id = ?',
      whereArgs: [info.id],
    );
  }
}