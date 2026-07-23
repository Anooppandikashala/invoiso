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
      ]),
    );

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
