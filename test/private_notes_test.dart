// Private notes: stored on invoices.private_notes, survive insert / update /
// list reads, and are kept on a credit note's own row.
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:invoiso/database/database_helper.dart';
import 'package:invoiso/database/invoice_service.dart';
import 'package:invoiso/database/product_service.dart';
import 'package:invoiso/database/return_service.dart';
import 'package:invoiso/models/customer.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/invoice_item.dart';
import 'package:invoiso/models/product.dart';

final _product = Product(
    id: 'p1',
    name: 'Item',
    description: '',
    price: 100,
    stock: 10,
    hsncode: '',
    tax_rate: 0);

Invoice _invoice(String id, {String type = 'Invoice', String? privateNotes}) =>
    Invoice(
      id: id,
      customer: Customer(
          id: 'c1', name: 'C', email: '', phone: '', address: '', gstin: ''),
      items: [InvoiceItem(product: _product, quantity: 1)],
      date: DateTime(2026, 11, 4),
      type: type,
      notes: 'Thanks for your business',
      privateNotes: privateNotes,
    );

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
    await ProductService.insertProduct(_product);
  });
  tearDown(() async {
    DatabaseHelper.setTestDatabase(null);
    await db.close();
  });

  test('insert, update and read keep private notes', () async {
    await InvoiceService.insertInvoice(
        _invoice('1', privateNotes: 'Bought cement at 380/bag'));
    var saved = (await InvoiceService.getInvoiceById('1'))!;
    expect(saved.privateNotes, 'Bought cement at 380/bag');
    expect(saved.notes, 'Thanks for your business');

    saved.privateNotes = 'Customer asked for discount next time';
    await InvoiceService.updateInvoice(saved);
    saved = (await InvoiceService.getInvoiceById('1'))!;
    expect(saved.privateNotes, 'Customer asked for discount next time');

    // List path (_buildInvoiceList) reads it too.
    final all = await InvoiceService.getAllInvoices();
    expect(all.single.privateNotes, 'Customer asked for discount next time');
  });

  test('no private notes reads back as null', () async {
    await InvoiceService.insertInvoice(_invoice('1'));
    expect((await InvoiceService.getInvoiceById('1'))!.privateNotes, isNull);
  });

  test('credit note stores its own private notes', () async {
    final original = _invoice('1', privateNotes: 'original secret');
    await InvoiceService.insertInvoice(original);
    await ReturnService.createCreditNote(
      creditNote: _invoice('2', type: 'Credit Note', privateNotes: 'cn note')
        ..originalInvoiceId = '1',
      originalInvoice: original,
    );
    final row = (await db.query('invoices', where: "id = '2'")).single;
    expect(row['private_notes'], 'cn note');
  });
}
