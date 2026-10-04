// Purchase bill drafts (inert: no stock / ledger / purchase price /
// supplier outstanding, no payments), trash restore re-applying stock, and
// product purchase info recomputed from the latest remaining final bill.
// Runs the real PurchaseBillService against an ffi sqflite file in a temp
// dir (path_provider's channel is mocked to point there).
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:invoiso/database/database_helper.dart';
import 'package:invoiso/database/product_service.dart';
import 'package:invoiso/database/purchase_bill_service.dart';
import 'package:invoiso/database/supplier_payment_service.dart';
import 'package:invoiso/database/supplier_service.dart';
import 'package:invoiso/models/product.dart';
import 'package:invoiso/models/purchase_bill.dart';
import 'package:invoiso/models/purchase_bill_item.dart';
import 'package:invoiso/models/supplier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tmp = Directory.systemTemp.createTempSync('invoiso_purchase_draft_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => tmp.path);
  });

  tearDownAll(() async {
    await DatabaseHelper().close();
    tmp.deleteSync(recursive: true);
  });

  // Fresh DB file per test so stock never leaks between cases.
  var dbCounter = 0;
  setUp(() async {
    await DatabaseHelper()
        .switchToFile('purchase_draft_test_${dbCounter++}.db');
    await ProductService.insertProduct(Product(
      id: 'p1',
      name: 'Widget',
      description: '',
      price: 100,
      stock: 10,
      hsncode: '',
      tax_rate: 0,
      purchasePrice: 40,
    ));
    await SupplierService.insertSupplier(Supplier(id: 's1', name: 'Acme'));
  });

  PurchaseBill bill(String id,
          {double qty = 5,
          double cost = 50,
          bool draft = false,
          DateTime? date}) =>
      PurchaseBill(
        id: id,
        supplierId: 's1',
        supplierName: 'Acme',
        billDate: date ?? DateTime(2026, 1, 1),
        items: [
          PurchaseBillItem(
              productId: 'p1',
              productName: 'Widget',
              quantity: qty,
              costPerUnit: cost),
        ],
        isDraft: draft,
      );

  Future<Product> product() async => (await ProductService.getProductById('p1'))!;

  Future<int> ledgerRows() async {
    final db = await DatabaseHelper().database;
    return (await db.query('stock_transactions')).length;
  }

  test('draft insert changes no stock, ledger, price or outstanding', () async {
    await PurchaseBillService.insertPurchaseBill(bill('b1', draft: true));

    final p = await product();
    expect(p.stock, 10);
    expect(p.purchasePrice, 40);
    expect(p.lastPurchaseDate, isNull);
    expect(await ledgerRows(), 0);
    expect(await SupplierService.getOutstandingBalance('s1'), 0);
    expect((await PurchaseBillService.getPurchaseBillById('b1'))!.isDraft,
        isTrue);
  });

  test('finalizing a draft applies stock once', () async {
    await PurchaseBillService.insertPurchaseBill(bill('b1', draft: true));
    await PurchaseBillService.updatePurchaseBill(bill('b1', draft: false));

    final p = await product();
    expect(p.stock, 15);
    expect(p.purchasePrice, 50);
    expect(p.lastPurchaseDate, DateTime(2026, 1, 1));
    expect(await ledgerRows(), 1);
    expect(await SupplierService.getOutstandingBalance('s1'), 250);
    expect((await PurchaseBillService.getPurchaseBillById('b1'))!.isDraft,
        isFalse);
  });

  test('editing a draft as a draft changes no stock', () async {
    await PurchaseBillService.insertPurchaseBill(bill('b1', draft: true));
    await PurchaseBillService.updatePurchaseBill(
        bill('b1', qty: 8, draft: true));

    expect((await product()).stock, 10);
    expect(await ledgerRows(), 0);
  });

  test('a final bill cannot be saved back as a draft', () async {
    await PurchaseBillService.insertPurchaseBill(bill('b1'));

    await expectLater(
        PurchaseBillService.updatePurchaseBill(bill('b1', draft: true)),
        throwsStateError);
    expect((await product()).stock, 15);
    expect((await PurchaseBillService.getPurchaseBillById('b1'))!.isDraft,
        isFalse);
  });

  test('trashing a draft writes no reversal; trashing a final bill does',
      () async {
    await PurchaseBillService.insertPurchaseBill(bill('d1', draft: true));
    await PurchaseBillService.softDeletePurchaseBill('d1');
    expect((await product()).stock, 10);
    expect(await ledgerRows(), 0);

    await PurchaseBillService.insertPurchaseBill(bill('b1'));
    await PurchaseBillService.softDeletePurchaseBill('b1');
    expect((await product()).stock, 10);
    expect(await ledgerRows(), 2); // purchase + reversal
  });

  test('restoring a trashed final bill re-applies its stock', () async {
    await PurchaseBillService.insertPurchaseBill(bill('b1'));
    await PurchaseBillService.softDeletePurchaseBill('b1');
    await PurchaseBillService.restorePurchaseBill('b1');

    expect((await product()).stock, 15);
    expect(await ledgerRows(), 3); // purchase + reversal + restore
  });

  test('restoring a trashed draft leaves stock alone', () async {
    await PurchaseBillService.insertPurchaseBill(bill('d1', draft: true));
    await PurchaseBillService.softDeletePurchaseBill('d1');
    await PurchaseBillService.restorePurchaseBill('d1');

    expect((await product()).stock, 10);
    expect(await ledgerRows(), 0);
  });

  test('purchase price follows the latest remaining final bill', () async {
    await PurchaseBillService.insertPurchaseBill(
        bill('old', cost: 50, date: DateTime(2026, 1, 1)));
    await PurchaseBillService.insertPurchaseBill(
        bill('new', cost: 60, date: DateTime(2026, 2, 1)));
    expect((await product()).purchasePrice, 60);

    // Editing the older bill must not overwrite the newer bill's cost.
    await PurchaseBillService.updatePurchaseBill(
        bill('old', cost: 55, date: DateTime(2026, 1, 1)));
    expect((await product()).purchasePrice, 60);

    // Deleting the newer bill falls back to the older one.
    await PurchaseBillService.softDeletePurchaseBill('new');
    var p = await product();
    expect(p.purchasePrice, 55);
    expect(p.lastPurchaseDate, DateTime(2026, 1, 1));

    // None left: price kept, date cleared.
    await PurchaseBillService.softDeletePurchaseBill('old');
    p = await product();
    expect(p.purchasePrice, 55);
    expect(p.lastPurchaseDate, isNull);

    // A draft never counts.
    await PurchaseBillService.insertPurchaseBill(
        bill('d1', cost: 99, draft: true, date: DateTime(2026, 3, 1)));
    expect((await product()).purchasePrice, 55);
  });

  test('a payment cannot be recorded on a draft', () async {
    final draft = bill('d1', draft: true);
    await PurchaseBillService.insertPurchaseBill(draft);

    await expectLater(
        SupplierPaymentService.addPayment(
            bill: draft, amountPaid: 10, datePaid: DateTime(2026, 1, 2)),
        throwsStateError);
    final db = await DatabaseHelper().database;
    expect(await db.query('supplier_payments'), isEmpty);
  });
}
