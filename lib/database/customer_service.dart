import 'package:invoiso/models/customer.dart';
import 'package:sqflite/sqflite.dart';
import 'package:invoiso/models/customer_list_stats.dart';
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

  static Future<Customer?> findByPhone(String phone) async {
    if (phone.trim().isEmpty) return null;
    final db = await dbHelper.database;
    final maps = await db.query(
      'customers',
      where: 'phone = ?',
      whereArgs: [phone.trim()],
      limit: 1,
    );
    return maps.isNotEmpty ? Customer.fromMap(maps.first) : null;
  }

  static Future<Customer?> findByEmail(String email) async {
    if (email.trim().isEmpty) return null;
    final db = await dbHelper.database;
    final maps = await db.query(
      'customers',
      where: 'email = ?',
      whereArgs: [email.trim()],
      limit: 1,
    );
    return maps.isNotEmpty ? Customer.fromMap(maps.first) : null;
  }

  /// Find an existing customer that matches by email OR phone.
  static Future<Customer?> findDuplicate(String email, String phone) async {
    final db = await dbHelper.database;
    final conditions = <String>[];
    final args = <String>[];
    if (email.trim().isNotEmpty) { conditions.add('email = ?'); args.add(email.trim()); }
    if (phone.trim().isNotEmpty) { conditions.add('phone = ?'); args.add(phone.trim()); }
    if (conditions.isEmpty) return null;
    final maps = await db.query(
      'customers',
      where: conditions.join(' OR '),
      whereArgs: args,
      limit: 1,
    );
    return maps.isNotEmpty ? Customer.fromMap(maps.first) : null;
  }

  static Future<void> deleteAllCustomers() async {
    final db = await dbHelper.database;
    await db.delete('customers');
  }

  static Future<List<Customer>> getCustomersPaginated({
    required int offset,
    required int limit,
    String query = '',
    String orderBy = 'name',
    bool orderASC = true,
  }) async {
    final db = await dbHelper.database;
    final order = orderASC ? "ASC" : "DESC";

    String? where;
    List<dynamic>? whereArgs;
    if (query.isNotEmpty) {
      final queryLower = query.toLowerCase();
      where =
          'LOWER(name) LIKE ? OR LOWER(email) LIKE ? OR LOWER(phone) LIKE ? OR LOWER(gstin) LIKE ? OR LOWER(business_name) LIKE ?';
      whereArgs = [
        '%$queryLower%',
        '%$queryLower%',
        '%$queryLower%',
        '%$queryLower%',
        '%$queryLower%'
      ];
    }

    final maps = await db.query(
      'customers',
      where: where,
      whereArgs: whereArgs,
      orderBy: '$orderBy COLLATE NOCASE $order',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  /// Insert a batch of customers in a single transaction.
  static Future<void> insertBatch(List<Customer> customers) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      for (final c in customers) {
        await txn.insert('customers', c.toMap());
      }
    });
  }

  // ─────────────────────────────────────────────
  // Customer management list (Issues.md #43) — one page + counts in SQL,
  // instead of loading every customer into memory. Rules mirror the old
  // in-memory V2 filter; COALESCE matches Customer.fromMap's '' defaults.

  // Dart's trim() also strips tabs/newlines, not just spaces.
  static String _isBlank(String col) =>
      "TRIM(COALESCE($col, ''), ' ' || char(9) || char(10) || char(13)) = ''";

  /// [tab]: 'all' | 'business' | 'individual' | 'tax' | 'no_tax'.
  static (String?, List<Object?>) _customerListWhere(String query, String tab) {
    final parts = <String>[];
    final args = <Object?>[];
    if (query.isNotEmpty) {
      final q = query
          .replaceAll(r'\', r'\\')
          .replaceAll('%', r'\%')
          .replaceAll('_', r'\_');
      const cols = ['name', 'email', 'phone', 'business_name', 'address', 'gstin'];
      parts.add('(${cols.map((c) => "$c LIKE ? ESCAPE '\\'").join(' OR ')})');
      args.addAll(List.filled(cols.length, '%$q%'));
    }
    switch (tab) {
      case 'business':
        parts.add('NOT ${_isBlank('business_name')}');
      case 'individual':
        parts.add(_isBlank('business_name'));
      case 'tax':
        parts.add('NOT ${_isBlank('gstin')}');
      case 'no_tax':
        parts.add(_isBlank('gstin'));
    }
    return (parts.isEmpty ? null : parts.join(' AND '), args);
  }

  static String _customerListOrder(String orderBy, bool ascending) {
    final dir = ascending ? 'ASC' : 'DESC';
    return switch (orderBy) {
      'name' => 'name COLLATE NOCASE $dir, id ASC',
      'id' => 'id $dir',
      _ => 'id ASC',
    };
  }

  static Future<List<Customer>> getCustomerListPage({
    required int offset,
    required int limit,
    String query = '',
    String tab = 'all',
    String orderBy = 'name', // 'name' | 'id'
    bool ascending = true,
  }) async {
    final db = await dbHelper.database;
    final (where, args) = _customerListWhere(query, tab);
    final maps = await db.query(
      'customers',
      where: where,
      whereArgs: args,
      orderBy: _customerListOrder(orderBy, ascending),
      limit: limit,
      offset: offset,
    );
    return maps.map((m) => Customer.fromMap(m)).toList();
  }

  static Future<int> getCustomerListCount(
      {String query = '', String tab = 'all'}) async {
    final db = await dbHelper.database;
    final (where, args) = _customerListWhere(query, tab);
    final rows = await db.rawQuery(
      'SELECT COUNT(*) FROM customers${where == null ? '' : ' WHERE $where'}',
      args,
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  /// Ids only (not full rows) of every matching customer, in list order —
  /// for orderings SQL can't do yet (outstanding, Issues.md #41).
  static Future<List<String>> getCustomerListIds({
    String query = '',
    String tab = 'all',
    String orderBy = 'name',
    bool ascending = true,
  }) async {
    final db = await dbHelper.database;
    final (where, args) = _customerListWhere(query, tab);
    final rows = await db.query(
      'customers',
      columns: ['id'],
      where: where,
      whereArgs: args,
      orderBy: _customerListOrder(orderBy, ascending),
    );
    return rows.map((r) => r['id'] as String).toList();
  }

  /// Customers for [ids], returned in the same order as [ids].
  static Future<List<Customer>> getCustomersByIds(List<String> ids) async {
    final db = await dbHelper.database;
    final rows = await queryInChunks(
      ids,
      (chunk, placeholders) => db.query('customers',
          where: 'id IN ($placeholders)', whereArgs: chunk),
    );
    final byId = {for (final r in rows) r['id'] as String: Customer.fromMap(r)};
    return [for (final id in ids) if (byId[id] != null) byId[id]!];
  }

  static Future<CustomerListStats> getCustomerListStats() async {
    final db = await dbHelper.database;
    final r = (await db.rawQuery(
      'SELECT COUNT(*) AS all_count, '
      "COALESCE(SUM(NOT ${_isBlank('business_name')}), 0) AS businesses, "
      "COALESCE(SUM(${_isBlank('business_name')}), 0) AS individuals, "
      "COALESCE(SUM(NOT ${_isBlank('gstin')}), 0) AS tax_registered "
      'FROM customers',
    ))
        .first;
    int v(String k) => (r[k] as num?)?.toInt() ?? 0;
    return (
      all: v('all_count'),
      businesses: v('businesses'),
      individuals: v('individuals'),
      taxRegistered: v('tax_registered'),
    );
  }
}
