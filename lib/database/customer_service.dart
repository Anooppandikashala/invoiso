import 'package:invoiso/models/customer.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class CustomerService
{
  static final dbHelper = DatabaseHelper();
  // ─────────────────────────────────────────────
  // CRUD for Customer
  static Future<void> insertCustomer(Customer customer) async {
    final db = await dbHelper.database;
    await db.insert(
      'customers',
      customer.toMap(),
      //conflictAlgorithm: ConflictAlgorithm.replace, // optional, avoids duplicate ID errors
    );
  }

  static Future<void> updateCustomer(Customer customer) async {
    final db = await dbHelper.database;

    // Create a map without 'id' for update
    final updateMap = customer.toMap()..remove('id');

    await db.update(
      'customers',
      updateMap,
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  static Future<Customer?> getCustomerById(String id) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Customer.fromMap(maps.first);
    }
    return null;
  }

  static Future<List<Customer>> getAllCustomers() async {
    final db = await dbHelper.database;
    final maps = await db.query('customers');
    return maps.map((c) => Customer.fromMap(c)).toList();
  }

  static Future<int> getTotalCustomerCount() async {
    final db = await dbHelper.database; // your initialized Database object
    final result = await db.rawQuery('SELECT COUNT(*) FROM customers');
    int count = Sqflite.firstIntValue(result) ?? 0;
    return count;
  }

  static Future<void> deleteCustomer(String id) async {
    final db = await dbHelper.database;
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

}