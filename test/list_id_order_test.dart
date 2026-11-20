// Customer / product list "ID oldest/newest" sort: ids are random UUIDs, so the
// order must follow when customers were added (SQLite rowid), not the id text.
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:invoiso/database/customer_service.dart';
import 'package:invoiso/database/database_helper.dart';
import 'package:invoiso/database/product_service.dart';
import 'package:invoiso/models/customer.dart';
import 'package:invoiso/models/product.dart';

void main() {
  late Database db;
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: DatabaseHelper().dbVersion,
        onCreate: (d, v) => DatabaseHelper().createDbForTest(d, v),
      ),
    );
    DatabaseHelper.setTestDatabase(db);
  });
  tearDown(() async {
    DatabaseHelper.setTestDatabase(null);
    await db.close();
  });

  test('customer list "ID newest/oldest" follows the order customers were added',
      () async {
    // Random-UUID-like ids whose text order differs from insert order.
    for (final id in ['z-first', 'a-second', 'm-third']) {
      await CustomerService.insertCustomer(Customer(
          id: id, name: id, email: '', phone: '', address: '', gstin: ''));
    }
    Future<List<String>> page(bool asc) async =>
        (await CustomerService.getCustomerListPage(
                offset: 0, limit: 10, orderBy: 'id', ascending: asc))
            .map((c) => c.id)
            .toList();
    expect(await page(false), ['m-third', 'a-second', 'z-first']);
    expect(await page(true), ['z-first', 'a-second', 'm-third']);
  });

  test('product list "ID newest/oldest" follows the order products were added',
      () async {
    for (final id in ['z-first', 'a-second', 'm-third']) {
      await ProductService.insertProduct(Product(
          id: id, name: id, description: '', price: 1, stock: 1, hsncode: '',
          tax_rate: 0));
    }
    Future<List<String>> page(bool asc) async =>
        (await ProductService.getProductListPage(
                offset: 0, limit: 10, orderBy: 'id', ascending: asc))
            .map((p) => p.id)
            .toList();
    expect(await page(false), ['m-third', 'a-second', 'z-first']);
    expect(await page(true), ['z-first', 'a-second', 'm-third']);
  });
}
