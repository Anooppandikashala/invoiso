import 'package:invoiso/models/supplier.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class SupplierService {
  static final dbHelper = DatabaseHelper();

  // ─────────────────────────────────────────────
  // CRUD for Supplier
  static Future<void> insertSupplier(Supplier supplier) async {
    final db = await dbHelper.database;
    await db.insert('suppliers', supplier.toMap());
  }

  static Future<void> updateSupplier(Supplier supplier) async {
    final db = await dbHelper.database;

    final updateMap = supplier.toMap()..remove('id');

    await db.update(
      'suppliers',
      updateMap,
      where: 'id = ?',
      whereArgs: [supplier.id],
    );
  }

  static Future<Supplier?> getSupplierById(String id) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'suppliers',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Supplier.fromMap(maps.first);
    }
    return null;
  }

  static Future<List<Supplier>> getAllSuppliers() async {
    final db = await dbHelper.database;
    final maps = await db.query('suppliers', where: 'deleted_at IS NULL');
    return maps.map((s) => Supplier.fromMap(s)).toList();
  }

  static Future<int> getTotalSupplierCount() async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM suppliers WHERE deleted_at IS NULL',
    );
    int count = Sqflite.firstIntValue(result) ?? 0;
    return count;
  }

  static Future<List<Supplier>> getSuppliersPaginated({
    required int offset,
    required int limit,
    String query = '',
    String orderBy = 'name',
    bool orderASC = true,
  }) async {
    final db = await dbHelper.database;
    final order = orderASC ? "ASC" : "DESC";

    final whereParts = <String>['deleted_at IS NULL'];
    final whereArgs = <dynamic>[];
    if (query.isNotEmpty) {
      final queryLower = query.toLowerCase();
      whereParts.add(
        '(LOWER(name) LIKE ? OR LOWER(business_name) LIKE ? OR LOWER(phone) LIKE ? OR LOWER(gstin) LIKE ?)',
      );
      whereArgs.addAll(
          ['%$queryLower%', '%$queryLower%', '%$queryLower%', '%$queryLower%']);
    }

    final maps = await db.query(
      'suppliers',
      where: whereParts.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: '$orderBy $order',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => Supplier.fromMap(map)).toList();
  }

  static Future<int> getSupplierCount([String query = '']) async {
    final db = await dbHelper.database;
    final whereParts = <String>['deleted_at IS NULL'];
    final whereArgs = <dynamic>[];
    if (query.isNotEmpty) {
      final queryLower = query.toLowerCase();
      whereParts.add(
        '(LOWER(name) LIKE ? OR LOWER(business_name) LIKE ? OR LOWER(phone) LIKE ? OR LOWER(gstin) LIKE ?)',
      );
      whereArgs.addAll(
          ['%$queryLower%', '%$queryLower%', '%$queryLower%', '%$queryLower%']);
    }
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM suppliers WHERE ${whereParts.join(' AND ')}',
      whereArgs,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ─────────────────────────────────────────────
  // Soft Delete
  static Future<void> softDeleteSupplier(String id) async {
    final db = await dbHelper.database;
    await db.update(
      'suppliers',
      {'deleted_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> restoreSupplier(String id) async {
    final db = await dbHelper.database;
    await db.update(
      'suppliers',
      {'deleted_at': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<List<Supplier>> getDeletedSuppliers() async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'suppliers',
      where: 'deleted_at IS NOT NULL',
      orderBy: 'deleted_at DESC',
    );
    return maps.map((s) => Supplier.fromMap(s)).toList();
  }

  // ─────────────────────────────────────────────
  // Live aggregate: SUM(purchase_bills.total_amount) - SUM(supplier_payments.amount_paid)
  // for this supplier's non-deleted bills (D5 — compute, don't cache).
  static Future<double> getOutstandingBalance(String supplierId) async {
    final db = await dbHelper.database;

    final billedResult = await db.rawQuery(
      'SELECT COALESCE(SUM(total_amount), 0.0) AS total FROM purchase_bills '
      'WHERE supplier_id = ? AND deleted_at IS NULL',
      [supplierId],
    );
    final billed = (billedResult.first['total'] as num).toDouble();

    final paidResult = await db.rawQuery(
      'SELECT COALESCE(SUM(sp.amount_paid), 0.0) AS paid '
      'FROM supplier_payments sp '
      'JOIN purchase_bills pb ON sp.bill_id = pb.id '
      'WHERE pb.supplier_id = ? AND pb.deleted_at IS NULL',
      [supplierId],
    );
    final paid = (paidResult.first['paid'] as num).toDouble();

    return billed - paid;
  }
}
