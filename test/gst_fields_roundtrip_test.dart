// GSTR-1 prerequisites (schema v61): customer state, invoice place of supply
// + reverse charge, product UQC + GST category and their invoice_items
// snapshots survive insert / update / list reads and credit notes.
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:invoiso/database/customer_service.dart';
import 'package:invoiso/database/database_helper.dart';
import 'package:invoiso/database/invoice_service.dart';
import 'package:invoiso/database/product_service.dart';
import 'package:invoiso/database/return_service.dart';
import 'package:invoiso/models/customer.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/invoice_item.dart';
import 'package:invoiso/models/product.dart';

Product _product() => Product(
    id: 'p1',
    name: 'Rice',
    description: '',
    price: 100,
    stock: 10,
    hsncode: '1006',
    tax_rate: 0,
    uqc: 'KGS',
    gstCategory: 'exempt');

Customer _customer() => Customer(
    id: 'c1',
    name: 'C',
    email: '',
    phone: '',
    address: '',
    gstin: '',
    stateCode: '29');

Invoice _invoice(String id, {String type = 'Invoice'}) => Invoice(
      id: id,
      customer: _customer(),
      items: [InvoiceItem(product: _product(), quantity: 1)],
      date: DateTime(2026, 11, 19),
      type: type,
      placeOfSupply: '29',
      reverseCharge: true,
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
    await ProductService.insertProduct(_product());
  });
  tearDown(() async {
    DatabaseHelper.setTestDatabase(null);
    await db.close();
  });

  test('customer state and product UQC / GST category persist', () async {
    await CustomerService.insertCustomer(_customer());
    final c = (await CustomerService.getAllCustomers()).single;
    expect(c.stateCode, '29');
    final p = (await ProductService.getAllProducts()).single;
    expect([p.uqc, p.gstCategory], ['KGS', 'exempt']);
  });

  test('invoice keeps place of supply, reverse charge and item snapshots',
      () async {
    await InvoiceService.insertInvoice(_invoice('1'));
    var saved = (await InvoiceService.getInvoiceById('1'))!;
    expect(saved.placeOfSupply, '29');
    expect(saved.reverseCharge, isTrue);
    expect(saved.items.single.product.uqc, 'KGS');
    expect(saved.items.single.product.gstCategory, 'exempt');

    saved
      ..placeOfSupply = '33'
      ..reverseCharge = false;
    await InvoiceService.updateInvoice(saved);
    saved = (await InvoiceService.getInvoiceById('1'))!;
    expect([saved.placeOfSupply, saved.reverseCharge], ['33', false]);
    expect(saved.items.single.product.uqc, 'KGS');

    final listed = (await InvoiceService.getAllInvoices()).single;
    expect([listed.placeOfSupply, listed.reverseCharge], ['33', false]);
  });

  test('invoice without place of supply reads back as null / no RCM', () async {
    await InvoiceService.insertInvoice(_invoice('1')
      ..placeOfSupply = null
      ..reverseCharge = false);
    final saved = (await InvoiceService.getInvoiceById('1'))!;
    expect([saved.placeOfSupply, saved.reverseCharge], [null, false]);
  });

  test('credit note row keeps place of supply, RCM and item snapshots',
      () async {
    final original = _invoice('1');
    await InvoiceService.insertInvoice(original);
    await ReturnService.createCreditNote(
      creditNote: _invoice('2', type: 'Credit Note')..originalInvoiceId = '1',
      originalInvoice: original,
    );
    final row = (await db.query('invoices', where: "id = '2'")).single;
    expect([row['place_of_supply'], row['reverse_charge']], ['29', 1]);
    final item = (await db.query('invoice_items', where: "invoice_id = '2'")).single;
    expect([item['product_uqc'], item['product_gst_category']], ['KGS', 'exempt']);
  });
}
