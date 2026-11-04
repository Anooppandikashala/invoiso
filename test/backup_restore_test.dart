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
import 'package:invoiso/database/invoice_attachment_service.dart';
import 'package:invoiso/models/invoice_attachment.dart';
import 'package:archive/archive_io.dart';
import 'package:image/image.dart' as img;

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

  // A v49 (v4.4.6) database: current schema minus the purchase-bill tables.
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
      {'future_table': [{'id': 'x'}]},
      {'customers': [{'id': 'c1', 'name': 'New', 'loyalty_tier': 'gold'}]},
    ]) {
      final result = await BackupManager()
          .restoreBackup(backupPath: writeJson('newer.json', data));
      expect(result.success, isFalse);
      expect(result.message, contains('newer version'));
    }
    expect(await db.query('customers', where: "id = 'keep'"), hasLength(1));
  });

  // ── Invoice photos in .invoicedb backups ──

  Future<void> addPhotos(String invoiceId, int count) async {
    final src = join(tmp.path, 'src_$invoiceId.jpg');
    File(src).writeAsBytesSync(img.encodeJpg(img.Image(width: 20, height: 10)));
    await InvoiceAttachmentService.sync(invoiceId, [
      for (var i = 0; i < count; i++)
        AttachmentDraft(path: src, isPublic: i.isEven, caption: 'c$i'),
    ]);
  }

  bool isZip(String path) {
    final b = File(path).readAsBytesSync();
    return b.length > 2 && b[0] == 0x50 && b[1] == 0x4B;
  }

  Future<String> backup() async {
    final r = await BackupManager().createBackup(
        companyId: 'default', companyName: 'Test', customPath: join(tmp.path, 'out'));
    expect(r.success, isTrue, reason: r.message);
    return r.filePath!;
  }

  test('no photos: backup stays a bare SQLite file', () async {
    final path = await backup();
    expect(isZip(path), isFalse);
    expect(await BackupManager().verifyBackup(path), isTrue);
  });

  test('photos: zip backup round-trips database rows and files', () async {
    await addPhotos('inv1', 3);
    final before = await InvoiceAttachmentService.listFor('inv1');
    final bytes = {
      for (final a in before)
        a.fileName: File(InvoiceAttachmentService.filePath(a)).readAsBytesSync()
    };
    final path = await backup();
    expect(isZip(path), isTrue);
    expect(await BackupManager().verifyBackup(path), isTrue);

    // Change things after the backup: drop a photo, add another invoice's.
    await InvoiceAttachmentService.sync('inv1', []);
    await addPhotos('inv2', 1);

    final r = await BackupManager().restoreBackup(backupPath: path);
    expect(r.success, isTrue, reason: r.message);

    final after = await InvoiceAttachmentService.listFor('inv1');
    expect(after.map((a) => [a.id, a.isPublic, a.caption]),
        before.map((a) => [a.id, a.isPublic, a.caption]));
    for (final a in after) {
      expect(File(InvoiceAttachmentService.filePath(a)).readAsBytesSync(),
          bytes[a.fileName]);
    }
    expect(await InvoiceAttachmentService.listFor('inv2'), isEmpty);
    expect(Directory(InvoiceAttachmentService.invoiceDir('inv2')).existsSync(),
        isFalse);
    // No leftovers next to the database.
    final dbDir = Directory(dirname(DatabaseHelper.path!));
    expect(
        dbDir.listSync(recursive: true).map((e) => e.path).where(
            (p) => p.contains('.restore_') || p.contains('.pre_restore')),
        isEmpty);
  });

  test('restoring a photo-less backup clears the current photos', () async {
    final path = await backup(); // bare SQLite, no photos
    await addPhotos('inv1', 2);
    final r = await BackupManager().restoreBackup(backupPath: path);
    expect(r.success, isTrue, reason: r.message);
    expect(await InvoiceAttachmentService.listFor('inv1'), isEmpty);
    expect(Directory(InvoiceAttachmentService.companyDir).existsSync(), isFalse);
  });

  test('zip entries outside the backup layout are never written', () async {
    await addPhotos('inv1', 1);
    final good = await backup();
    // Rebuild the zip with an extra "../escape.txt" entry.
    final archive = ZipDecoder().decodeBytes(File(good).readAsBytesSync());
    archive.addFile(ArchiveFile('../escape.txt', 4, [1, 2, 3, 4]));
    archive.addFile(ArchiveFile('attachments/../../escape2.txt', 4, [1, 2, 3, 4]));
    final evil = join(tmp.path, 'evil.invoicedb');
    File(evil).writeAsBytesSync(ZipEncoder().encode(archive));

    final r = await BackupManager().restoreBackup(backupPath: evil);
    expect(r.success, isTrue, reason: r.message);
    final dbDir = dirname(DatabaseHelper.path!);
    expect(File(join(dirname(dbDir), 'escape.txt')).existsSync(), isFalse);
    expect(File(join(dbDir, 'escape.txt')).existsSync(), isFalse);
    expect(File(join(dbDir, 'escape2.txt')).existsSync(), isFalse);
    expect((await InvoiceAttachmentService.listFor('inv1')).length, 1);
  });

  test('a zip without a database is refused and current data kept', () async {
    await addPhotos('inv1', 1);
    final bad = join(tmp.path, 'nodb.invoicedb');
    File(bad).writeAsBytesSync(ZipEncoder().encode(
        Archive()..addFile(ArchiveFile('attachments/x/y.jpg', 3, [1, 2, 3]))));
    expect(await BackupManager().verifyBackup(bad), isFalse);
    final r = await BackupManager().restoreBackup(backupPath: bad);
    expect(r.success, isFalse);
    expect((await InvoiceAttachmentService.listFor('inv1')).length, 1);
  });
}
