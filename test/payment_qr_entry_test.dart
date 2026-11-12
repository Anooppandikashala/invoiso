// Uploaded payment QR images: PaymentQrEntry JSON round trip, and the
// per-invoice choice (invoices.payment_qr_id) survives insert / update / reads.
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/database/database_helper.dart';
import 'package:invoiso/database/invoice_service.dart';
import 'package:invoiso/database/product_service.dart';
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

Invoice _invoice(String id, {String? paymentQrId}) => Invoice(
      id: id,
      customer: Customer(
          id: 'c1', name: 'C', email: '', phone: '', address: '', gstin: ''),
      items: [InvoiceItem(product: _product, quantity: 1)],
      date: DateTime(2026, 11, 12),
      type: 'Invoice',
      paymentQrId: paymentQrId,
    );

void main() {
  test('PaymentQrEntry list JSON round trip', () {
    const entries = [
      PaymentQrEntry(
          id: 'q1', label: 'Pay via PayPal', imageBase64: 'AAA', isDefault: true),
      PaymentQrEntry(id: 'q2', label: '', imageBase64: 'BBB'),
    ];
    final back =
        PaymentQrEntry.listFromJson(PaymentQrEntry.listToJson(entries));
    expect(back.map((e) => e.id), ['q1', 'q2']);
    expect(back.first.label, 'Pay via PayPal');
    expect(back.first.imageBase64, 'AAA');
    expect(back.first.isDefault, isTrue);
    expect(back.last.isDefault, isFalse);
  });

  test('PaymentQrEntry.listFromJson handles missing setting', () {
    expect(PaymentQrEntry.listFromJson(null), isEmpty);
    expect(PaymentQrEntry.listFromJson(''), isEmpty);
  });

  group('invoices.payment_qr_id', () {
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

    test('insert, update and read keep the picked QR', () async {
      await InvoiceService.insertInvoice(_invoice('1', paymentQrId: 'q1'));
      var saved = (await InvoiceService.getInvoiceById('1'))!;
      expect(saved.paymentQrId, 'q1');

      saved.paymentQrId = 'q2';
      await InvoiceService.updateInvoice(saved);
      saved = (await InvoiceService.getInvoiceById('1'))!;
      expect(saved.paymentQrId, 'q2');

      // List path (_buildInvoiceList) reads it too.
      final all = await InvoiceService.getAllInvoices();
      expect(all.single.paymentQrId, 'q2');
    });

    test('no QR picked reads back as null', () async {
      await InvoiceService.insertInvoice(_invoice('1'));
      expect((await InvoiceService.getInvoiceById('1'))!.paymentQrId, isNull);
    });
  });
}
