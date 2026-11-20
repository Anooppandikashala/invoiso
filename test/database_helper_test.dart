// Exercises the *real* DatabaseHelper migration code (via the
// @visibleForTesting createDbForTest/upgradeDbForTest hooks) against an
// in-memory sqflite_common_ffi database — no device/emulator, no
// path_provider platform channel needed.
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:invoiso/database/database_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  final currentVersion = DatabaseHelper().dbVersion;

  test('fresh create has all expected tables', () async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: currentVersion,
      onCreate: (db, v) => DatabaseHelper().createDbForTest(db, v),
    );

    final tables = await db
        .rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    final tableNames = tables.map((r) => r['name']).toSet();

    expect(
      tableNames,
      containsAll([
        'customers',
        'products',
        'invoices',
        'invoice_items',
        'users',
        'company_info',
        'settings',
        'invoice_payments',
        'customer_credits',
        'refunds',
      ]),
    );

    await db.close();
  });

  test('fresh create invoices table has current-version columns', () async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: currentVersion,
      onCreate: (db, v) => DatabaseHelper().createDbForTest(db, v),
    );

    final cols = await db.rawQuery('PRAGMA table_info(invoices)');
    final colNames = cols.map((r) => r['name']).toSet();

    expect(
      colNames,
      containsAll([
        'customer_business_name',
        'currency_code',
        'currency_symbol',
        'tax_mode',
        'invoice_number',
        'status',
        'converted_to_invoice_id',
        'converted_from_invoice_id',
        'customer_shipping_same_as_billing',
        'customer_shipping_name',
        'customer_shipping_phone',
        'customer_shipping_address',
        'customer_dob',
        'customer_age',
        'customer_gender',
        'customer_custom_fields',
      ]),
    );

    await db.close();
  });

  test('fresh create customers table has shipping/personal/custom columns',
      () async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: currentVersion,
      onCreate: (db, v) => DatabaseHelper().createDbForTest(db, v),
    );

    final cols = await db.rawQuery('PRAGMA table_info(customers)');
    final colNames = cols.map((r) => r['name']).toSet();

    expect(
      colNames,
      containsAll([
        'shipping_same_as_billing',
        'shipping_name',
        'shipping_phone',
        'shipping_address',
        'dob',
        'age',
        'gender',
        'custom_fields',
      ]),
    );

    await db.close();
  });

  test('fresh create invoice_items has the per-line description column',
      () async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: currentVersion,
      onCreate: (db, v) => DatabaseHelper().createDbForTest(db, v),
    );

    final cols = await db.rawQuery('PRAGMA table_info(invoice_items)');
    final colNames = cols.map((r) => r['name']).toSet();

    // `description` is the line-level text typed on the invoice;
    // `product_description` is the product's own text, snapshotted at
    // invoice time. Both must exist — the first falls back to the second.
    expect(colNames, containsAll(['description', 'product_description']));

    // v44: JSON snapshot of the product's metadata for the Grid Classic PDF.
    expect(colNames, contains('line_metadata'));

    await db.close();
  });

  test('fresh create company_info has country column defaulting to India',
      () async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: currentVersion,
      onCreate: (db, v) => DatabaseHelper().createDbForTest(db, v),
    );

    final rows = await db.query('company_info');
    expect(rows, isNotEmpty);
    expect(rows.first['country'], 'India');

    await db.close();
  });

  test('default admin user is seeded on fresh create', () async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: currentVersion,
      onCreate: (db, v) => DatabaseHelper().createDbForTest(db, v),
    );

    final users = await db.query('users', where: 'username = ?', whereArgs: ['admin']);
    expect(users, hasLength(1));
    expect(users.first['user_type'], 'admin');

    await db.close();
  });

  test('v61 adds GST columns and backfills customer state from GSTIN',
      () async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: currentVersion,
      onCreate: (db, v) => DatabaseHelper().createDbForTest(db, v),
    );
    // Back to the v60 shape.
    for (final (table, col) in const [
      ('customers', 'state_code'),
      ('invoices', 'place_of_supply'),
      ('invoices', 'reverse_charge'),
      ('products', 'uqc'),
      ('products', 'gst_category'),
      ('invoice_items', 'product_uqc'),
      ('invoice_items', 'product_gst_category'),
    ]) {
      await db.execute('ALTER TABLE $table DROP COLUMN $col');
    }
    await db.insert('customers', {'id': 'c1', 'gstin': '33ABCDE1234F1Z5'});
    await db.insert('customers', {'id': 'c2', 'gstin': '123'});
    await db.insert('customers', {'id': 'c3', 'gstin': ''});

    await DatabaseHelper().upgradeDbForTest(db, 60, 61);

    Future<Set<Object?>> cols(String t) async =>
        (await db.rawQuery('PRAGMA table_info($t)')).map((r) => r['name']).toSet();
    expect(await cols('customers'), contains('state_code'));
    expect(await cols('invoices'), containsAll(['place_of_supply', 'reverse_charge']));
    expect(await cols('products'), containsAll(['uqc', 'gst_category']));
    expect(await cols('invoice_items'),
        containsAll(['product_uqc', 'product_gst_category']));
    final states = {
      for (final r in await db.query('customers')) r['id']: r['state_code']
    };
    expect(states, {'c1': '33', 'c2': '', 'c3': ''});

    await db.close();
  });

  test('v62 adds purchase bill GST columns and copies supplier GSTINs', () async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: currentVersion,
      onCreate: (db, v) => DatabaseHelper().createDbForTest(db, v),
    );
    for (final col in ['supplier_gstin', 'due_date', 'reverse_charge']) {
      await db.execute('ALTER TABLE purchase_bills DROP COLUMN $col'); // v61 shape
    }
    await db.insert('suppliers', {'id': 's1', 'name': 'Acme', 'gstin': ' 33AAAAA1111A1Z5 '});
    await db.insert('suppliers', {'id': 's2', 'name': 'No GST', 'gstin': ''});
    await db.insert('purchase_bills', {'id': 'b1', 'supplier_id': 's1', 'bill_date': '2026-11-01'});
    await db.insert('purchase_bills', {'id': 'b2', 'supplier_id': 's2', 'bill_date': '2026-11-01'});
    await db.insert('purchase_bills', {'id': 'b3', 'supplier_id': null, 'bill_date': '2026-11-01'});
    await db.insert('purchase_bills', {'id': 'b4', 'supplier_id': 'gone', 'bill_date': '2026-11-01'});

    await DatabaseHelper().upgradeDbForTest(db, 61, 62);

    final rows = {
      for (final r in await db.query('purchase_bills')) r['id']: r
    };
    expect(rows['b1']!['supplier_gstin'], '33AAAAA1111A1Z5');
    expect([for (final id in ['b2', 'b3', 'b4']) rows[id]!['supplier_gstin']],
        ['', '', '']);
    expect([rows['b1']!['due_date'], rows['b1']!['reverse_charge']], [null, 0]);
    await db.close();
  });

  test('re-running upgrade at the same version does not throw', () async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: currentVersion,
      onCreate: (db, v) => DatabaseHelper().createDbForTest(db, v),
    );

    await expectLater(
      DatabaseHelper()
          .upgradeDbForTest(db, currentVersion, currentVersion),
      completes,
    );

    await db.close();
  });
}
