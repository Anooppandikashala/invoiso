// Backup restore across app versions (Issues.md #77–80): an older
// .invoicedb is upgraded on reopen, a newer one is refused; old JSON backups
// get item ids and keep the onboarding flag; JSON from a newer build is
// refused cleanly. Real BackupManager + DatabaseHelper against ffi sqflite
// files in a temp dir.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:invoiso/backup/backup_manager.dart';
import 'package:invoiso/database/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tmp = Directory.systemTemp.createTempSync('invoiso_restore_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => tmp.path);
  });

  tearDownAll(() async {
    await DatabaseHelper().close();
    tmp.deleteSync(recursive: true);
  });

  var n = 0;
  setUp(() async => DatabaseHelper().switchToFile('live_${n++}.db'));

  String writeJson(String name, Map<String, dynamic> data) {
    final path = join(tmp.path, name);
    File(path).writeAsStringSync(
        jsonEncode({...data, '_metadata': {'version': '1.0'}}));
    return path;
  }

  // A v49 (v4.4.6) database: current schema minus everything v52 added.
  Future<String> makeV49Backup() async {
    final path = join(tmp.path, 'old_v49.invoicedb');
    final db = await openDatabase(path,
        version: DatabaseHelper().dbVersion,
        onCreate: (db, v) => DatabaseHelper().createDbForTest(db, v));
    for (final t in [
      'suppliers',
      'purchase_bills',
      'purchase_bill_items',
      'stock_transactions',
      'supplier_payments',
    ]) {
      await db.execute('DROP TABLE $t');
    }
    await db.execute('ALTER TABLE products DROP COLUMN last_purchase_date');
    await db.insert('customers', {'id': 'c-old', 'name': 'Old Customer'});
    await db.setVersion(49);
    await db.close();
    return path;
  }

  test('restoring a v49 .invoicedb backup upgrades it to the current schema',
      () async {
    final backupPath = await makeV49Backup();

    final result =
        await BackupManager().restoreBackup(backupPath: backupPath);
    expect(result.success, isTrue, reason: result.message);

    final db = await DatabaseHelper().database;
    expect(await db.getVersion(), DatabaseHelper().dbVersion);
    expect(await db.query('customers', where: "id = 'c-old'"), hasLength(1));
    final tables = (await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type = 'table'"))
        .map((r) => r['name']);
    expect(tables, containsAll(['suppliers', 'purchase_bills']));
    final productCols = (await db.rawQuery('PRAGMA table_info(products)'))
        .map((c) => c['name']);
    expect(productCols, contains('last_purchase_date'));
  });

  test('a .invoicedb from a newer app version is refused', () async {
    final path = join(tmp.path, 'newer.invoicedb');
    final db = await openDatabase(path,
        version: DatabaseHelper().dbVersion,
        onCreate: (db, v) => DatabaseHelper().createDbForTest(db, v));
    await db.setVersion(DatabaseHelper().dbVersion + 1);
    await db.close();

    final result = await BackupManager().restoreBackup(backupPath: path);
    expect(result.success, isFalse);
    expect(result.message, contains('newer version'));
    expect(await (await DatabaseHelper().database).getVersion(),
        DatabaseHelper().dbVersion);
  });

  test('old JSON backup: items without id get one, onboarding flag kept',
      () async {
    final live = await DatabaseHelper().database;
    await live.insert('settings', {'key': 'onboarding_completed', 'value': 'true'},
        conflictAlgorithm: ConflictAlgorithm.replace);
    final path = writeJson('old.json', {
      'invoices': [
        {'id': 'i1', 'customer_name': 'Old', 'type': 'Invoice', 'date': '2025-01-01'}
      ],
      'invoice_items': [
        {'invoice_id': 'i1', 'product_id': 'p1', 'product_name': 'A', 'quantity': 1},
        {'invoice_id': 'i1', 'product_id': 'p2', 'product_name': 'B', 'quantity': 2},
      ],
      'settings': [
        {'key': 'currency', 'value': 'INR'}
      ],
    });

    final result = await BackupManager().restoreBackup(backupPath: path);
    expect(result.success, isTrue, reason: result.message);

    final db = await DatabaseHelper().database;
    final ids = (await db.query('invoice_items')).map((r) => r['id']).toList();
    expect(ids, hasLength(2));
    expect(ids, everyElement(isNotNull));
    expect(ids.toSet(), hasLength(2));
    expect(await db.query('settings', where: "key = 'onboarding_completed'"),
        [{'key': 'onboarding_completed', 'value': 'true'}]);
  });

  test('JSON from a newer build is refused with a readable message', () async {
    final db = await DatabaseHelper().database;
    await db.insert('customers', {'id': 'keep', 'name': 'Keep Me'});

    for (final data in [
      {'cash_ledger': [{'id': 'x'}]},
      {'customers': [{'id': 'c1', 'name': 'New', 'loyalty_tier': 'gold'}]},
    ]) {
      final result = await BackupManager()
          .restoreBackup(backupPath: writeJson('newer.json', data));
      expect(result.success, isFalse);
      expect(result.message, contains('newer version'));
    }
    expect(await db.query('customers', where: "id = 'keep'"), hasLength(1));
  });
}
