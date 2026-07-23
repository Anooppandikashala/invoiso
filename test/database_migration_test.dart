// Regression test for the full historical upgrade chain.
//
// v4 (commit 4fd7ee2, 2025-10-14) is the oldest schema any real installed
// user could still be on — every version before it (v1-v3) predates the
// `path_provider`-based db location and lacked company_info/settings
// tables entirely, so no live install could realistically be stuck there.
// v4's schema is reproduced here verbatim from git history (see
// `git show 4fd7ee2:lib/database/database_helper.dart`) since that code no
// longer exists in the current file.
//
// This exercises the real `_upgradeDB` chain (via the @visibleForTesting
// upgradeDbForTest hook) end to end: v4 -> current dbVersion, on a live
// in-memory sqflite_common_ffi connection — the same way sqflite's real
// onUpgrade callback operates on an already-open Database, just invoked
// directly instead of via a version-triggered reopen (in-memory DBs don't
// survive close/reopen, so that path doesn't apply here anyway). Catches: a
// migration step assuming a column/table that didn't exist yet in v4, a
// step ordering bug, or old data getting clobbered/lost during the chain.
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:invoiso/database/database_helper.dart';

const _v4Schema = [
  '''
    CREATE TABLE customers (
      id TEXT PRIMARY KEY,
      name TEXT,
      email TEXT,
      phone TEXT,
      address TEXT,
      gstin TEXT
    )
  ''',
  '''
    CREATE TABLE products (
      id TEXT PRIMARY KEY,
      name TEXT,
      description TEXT,
      price REAL,
      stock INTEGER,
      hsncode TEXT,
      tax_rate INTEGER
    )
  ''',
  '''
    CREATE TABLE invoices (
      id TEXT PRIMARY KEY,
      customer_id TEXT,
      customer_name TEXT,
      customer_email TEXT,
      customer_phone TEXT,
      customer_address TEXT,
      customer_gstin TEXT,
      date TEXT,
      notes TEXT,
      tax_rate REAL,
      type TEXT
    )
  ''',
  '''
    CREATE TABLE invoice_items (
      invoice_id TEXT,
      product_id TEXT,
      product_name TEXT,
      product_description TEXT,
      product_price REAL,
      product_tax_rate INTEGER,
      product_hsn_code TEXT,
      quantity INTEGER,
      discount REAL,
      PRIMARY KEY (invoice_id, product_id),
      FOREIGN KEY (invoice_id) REFERENCES invoices(id)
    )
  ''',
  '''
    CREATE TABLE users (
      id TEXT PRIMARY KEY,
      username TEXT UNIQUE,
      password TEXT,
      user_type TEXT
    )
  ''',
  '''
    CREATE TABLE company_info (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      address TEXT,
      phone TEXT,
      email TEXT,
      website TEXT,
      gstin TEXT
    )
  ''',
  '''
    CREATE TABLE settings (
      key TEXT PRIMARY KEY,
      value TEXT
    )
  ''',
];

Future<Database> _openV4WithSampleData() async {
  final db = await openDatabase(
    inMemoryDatabasePath,
    version: 4,
    onCreate: (db, v) async {
      for (final stmt in _v4Schema) {
        await db.execute(stmt);
      }
    },
  );

  await db.insert('customers', {
    'id': 'c1',
    'name': 'Old Customer',
    'email': 'old@example.com',
    'phone': '9999999999',
    'address': 'Old Address',
    'gstin': '',
  });
  await db.insert('products', {
    'id': 'p1',
    'name': 'Old Product',
    'description': '',
    'price': 100.0,
    'stock': 5,
    'hsncode': '1234',
    'tax_rate': 18,
  });
  await db.insert('invoices', {
    'id': 'i1',
    'customer_id': 'c1',
    'customer_name': 'Old Customer',
    'customer_email': 'old@example.com',
    'customer_phone': '9999999999',
    'customer_address': 'Old Address',
    'customer_gstin': '',
    'date': '2025-10-14',
    'notes': 'Pre-migration invoice',
    'tax_rate': 18.0,
    'type': 'Invoice',
  });
  await db.insert('invoice_items', {
    'invoice_id': 'i1',
    'product_id': 'p1',
    'product_name': 'Old Product',
    'product_description': '',
    'product_price': 100.0,
    'product_tax_rate': 18,
    'product_hsn_code': '1234',
    'quantity': 2,
    'discount': 0.0,
  });
  await db.insert('users', {
    'id': 'user-001',
    'username': 'admin',
    'password': 'admin',
    'user_type': 'admin',
  });
  await db.insert('company_info', {
    'name': 'Your Company Name',
    'address': '123 Street \nCity, State 12345',
    'phone': '9876543210',
    'email': 'info@yourcompany.com',
    'website': 'www.yourcompany.com',
    'gstin': '',
  });

  return db;
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('upgrading from v4 to current preserves old data and adds new columns',
      () async {
    final db = await _openV4WithSampleData();
    final currentVersion = DatabaseHelper().dbVersion;

    await DatabaseHelper().upgradeDbForTest(db, 4, currentVersion);

    // Old data survived the full chain.
    final invoice =
        (await db.query('invoices', where: 'id = ?', whereArgs: ['i1']))
            .first;
    expect(invoice['notes'], 'Pre-migration invoice');
    expect(invoice['customer_name'], 'Old Customer');

    final item = (await db.query('invoice_items',
            where: 'invoice_id = ?', whereArgs: ['i1']))
        .first;
    expect(item['product_name'], 'Old Product');
    expect(item['quantity'], 2);

    // New columns exist with sane defaults, didn't crash the chain.
    expect(invoice['currency_code'], 'INR');
    expect(invoice['tax_mode'], 'global');
    expect(invoice['customer_business_name'], '');

    final user = (await db.query('users',
            where: 'username = ?', whereArgs: ['admin']))
        .first;
    expect(user['salt'], isNull); // no salt was ever set for this legacy row
    expect(user['password_changed'], 0); // forced reset for admin, per v8 step

    final companyInfo = (await db.query('company_info')).first;
    expect(companyInfo['country'], 'India');
    expect(companyInfo['pan_number'], '');

    await db.close();
  });
}
