// Exercises ReturnService against a real in-memory sqflite_common_ffi DB
// (via DatabaseHelper.setTestDatabase) — no device, no path_provider.
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:invoiso/common/common.dart';
import 'package:invoiso/database/database_helper.dart';
import 'package:invoiso/database/invoice_service.dart';
import 'package:invoiso/database/payment_service.dart';
import 'package:invoiso/database/product_service.dart';
import 'package:invoiso/database/report_service.dart';
import 'package:invoiso/database/return_service.dart';
import 'package:invoiso/models/customer.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/invoice_item.dart';
import 'package:invoiso/models/product.dart';
import 'package:invoiso/services/pdf/pdf_service.dart';
import 'package:invoiso/services/pdf/pdf_widgets.dart';

Customer _cust({String id = 'c1', String name = 'Ramesh Stores'}) => Customer(
      id: id,
      name: name,
      email: '',
      phone: '',
      address: '',
      gstin: '',
    );

Product _prod({
  String id = 'p1',
  double price = 100,
  int stock = 50,
  int taxRate = 0,
  bool unlimited = false,
}) =>
    Product(
      id: id,
      name: 'Widget $id',
      description: '',
      price: price,
      stock: stock,
      hsncode: '',
      tax_rate: taxRate,
      unlimitedStock: unlimited,
    );

InvoiceItem _item(Product p, double qty, {bool restocked = true}) =>
    InvoiceItem(product: p, quantity: qty, restocked: restocked);

Invoice _invoice({
  required String id,
  required String number,
  required Customer customer,
  required List<InvoiceItem> items,
  String type = 'Invoice',
  DateTime? date,
}) =>
    Invoice(
      id: id,
      invoiceNumber: number,
      customer: customer,
      items: items,
      date: date ?? DateTime(2026, 3, 1),
      type: type,
      taxMode: TaxMode.perItem,
    );

Invoice _creditNote({
  required String id,
  required Invoice original,
  required List<InvoiceItem> items,
  required CreditSettlement settlement,
}) =>
    Invoice(
      id: id,
      invoiceNumber: 'CN-$id',
      customer: original.customer,
      items: items,
      date: DateTime(2026, 3, 10),
      type: 'Credit Note',
      taxMode: TaxMode.perItem,
      originalInvoiceId: original.id,
      originalInvoiceNumber: original.invoiceNumber,
      originalInvoiceDate: original.date,
      returnReason: 'Damaged',
      creditSettlement: settlement,
    );

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;

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

  Future<Invoice> seedPaidInvoice({
    int stock = 50,
    double price = 100,
    int taxRate = 0,
    bool unlimited = false,
    double qty = 10,
  }) async {
    final p = _prod(price: price, stock: stock, taxRate: taxRate, unlimited: unlimited);
    await ProductService.insertProduct(p);
    final inv = _invoice(
      id: 'i1',
      number: '00000001',
      customer: _cust(),
      items: [_item(p, qty)],
    );
    await InvoiceService.insertInvoice(inv);
    // pay it in full
    final loaded = (await InvoiceService.getInvoiceById('i1'))!;
    await PaymentService.addPayment(
      invoice: loaded,
      amountPaid: loaded.total,
      datePaid: DateTime(2026, 3, 2),
      paymentMethod: 'Cash',
    );
    return (await InvoiceService.getInvoiceById('i1'))!;
  }

  test('restocks returned qty; leaves invoice stock deduction intact', () async {
    final original = await seedPaidInvoice(stock: 50, qty: 10); // stock now 40
    expect((await ProductService.getProductById('p1'))!.stock, 40);

    final cn = _creditNote(
      id: 'cn1',
      original: original,
      items: [_item(original.items.first.product, 3)],
      settlement: CreditSettlement.customerCredit,
    );
    await ReturnService.createCreditNote(creditNote: cn, originalInvoice: original);

    expect((await ProductService.getProductById('p1'))!.stock, 43);
  });

  test('restock=false does not touch stock', () async {
    final original = await seedPaidInvoice(stock: 50, qty: 10);
    final cn = _creditNote(
      id: 'cn1',
      original: original,
      items: [_item(original.items.first.product, 4, restocked: false)],
      settlement: CreditSettlement.customerCredit,
    );
    await ReturnService.createCreditNote(creditNote: cn, originalInvoice: original);
    expect((await ProductService.getProductById('p1'))!.stock, 40);
  });

  test('sales-return title stamped on the credit note is persisted', () async {
    final original = await seedPaidInvoice(stock: 50, qty: 10);
    final cn = _creditNote(
      id: 'cn1',
      original: original,
      items: [_item(original.items.first.product, 2)],
      settlement: CreditSettlement.customerCredit,
    )..invoiceTitle = 'Credit Note (Sales Return)';
    await ReturnService.createCreditNote(creditNote: cn, originalInvoice: original);
    expect((await InvoiceService.getInvoiceById('cn1'))!.invoiceTitle,
        'Credit Note (Sales Return)');
  });

  test('unlimited-stock product is never restocked', () async {
    final original = await seedPaidInvoice(stock: 0, qty: 5, unlimited: true);
    final cn = _creditNote(
      id: 'cn1',
      original: original,
      items: [_item(original.items.first.product, 2)],
      settlement: CreditSettlement.customerCredit,
    );
    await ReturnService.createCreditNote(creditNote: cn, originalInvoice: original);
    expect((await ProductService.getProductById('p1'))!.stock, 0);
  });

  test('customerCredit settlement stores a drawable credit balance', () async {
    final original = await seedPaidInvoice(price: 100, qty: 10);
    final cn = _creditNote(
      id: 'cn1',
      original: original,
      items: [_item(original.items.first.product, 3)], // 3 * 100 = 300
      settlement: CreditSettlement.customerCredit,
    );
    await ReturnService.createCreditNote(creditNote: cn, originalInvoice: original);

    final remaining = await ReturnService.getRemainingCustomerCredit(
        customerId: 'c1', currencyCode: 'INR');
    expect(remaining, 300);
  });

  test('reduceInvoice settlement lowers the original invoice outstanding', () async {
    // invoice 10 * 100 = 1000, pay only 600 -> outstanding 400
    final p = _prod(price: 100, stock: 50);
    await ProductService.insertProduct(p);
    final inv = _invoice(
        id: 'i1', number: '00000001', customer: _cust(), items: [_item(p, 10)]);
    await InvoiceService.insertInvoice(inv);
    var loaded = (await InvoiceService.getInvoiceById('i1'))!;
    await PaymentService.addPayment(
        invoice: loaded, amountPaid: 600, datePaid: DateTime(2026, 3, 2));
    loaded = (await InvoiceService.getInvoiceById('i1'))!;
    expect(loaded.outstandingBalance, 400);

    final cn = _creditNote(
      id: 'cn1',
      original: loaded,
      items: [_item(p, 3)], // 300
      settlement: CreditSettlement.reduceInvoice,
    );
    await ReturnService.createCreditNote(creditNote: cn, originalInvoice: loaded);

    final after = (await InvoiceService.getInvoiceById('i1'))!;
    expect(after.outstandingBalance, 100);
    // nothing parked as customer credit — it all went to the invoice
    expect(
        await ReturnService.getRemainingCustomerCredit(
            customerId: 'c1', currencyCode: 'INR'),
        0);
  });

  test('reduceInvoice excess over outstanding becomes customer credit', () async {
    final original = await seedPaidInvoice(price: 100, qty: 10); // fully paid, outstanding 0
    final cn = _creditNote(
      id: 'cn1',
      original: original,
      items: [_item(original.items.first.product, 2)], // 200
      settlement: CreditSettlement.reduceInvoice,
    );
    await ReturnService.createCreditNote(creditNote: cn, originalInvoice: original);
    expect(
        await ReturnService.getRemainingCustomerCredit(
            customerId: 'c1', currencyCode: 'INR'),
        200);
  });

  test('refund settlement with immediate full payout drains the credit', () async {
    final original = await seedPaidInvoice(price: 100, qty: 10);
    final cn = _creditNote(
      id: 'cn1',
      original: original,
      items: [_item(original.items.first.product, 5)], // 500
      settlement: CreditSettlement.refund,
    );
    await ReturnService.createCreditNote(
      creditNote: cn,
      originalInvoice: original,
      immediateRefund: (
        amount: 500,
        method: 'Bank Transfer',
        date: DateTime(2026, 3, 10),
        notes: null,
      ),
    );

    expect(
        await ReturnService.getRemainingCustomerCredit(
            customerId: 'c1', currencyCode: 'INR'),
        0);
    final refunds = await ReturnService.getRefundsForCreditNote('cn1');
    expect(refunds, hasLength(1));
    expect(refunds.first.amount, 500);
  });

  test('credit note PDF notes list each refund', () async {
    final original = await seedPaidInvoice(price: 100, qty: 10);
    final cn = _creditNote(
      id: 'cn1',
      original: original,
      items: [_item(original.items.first.product, 5)], // 500
      settlement: CreditSettlement.refund,
    );
    await ReturnService.createCreditNote(
      creditNote: cn,
      originalInvoice: original,
      immediateRefund: (
        amount: 500,
        method: 'Cash',
        date: DateTime(2026, 3, 10),
        notes: null,
      ),
    );
    final loaded = (await InvoiceService.getInvoiceById('cn1'))!;
    await PDFService.attachRefunds(loaded);
    final refundLine =
        returnInfoLines(loaded).where((l) => l.startsWith('Refund ')).single;
    expect(refundLine, contains('500.00 on 10 Mar 2026 via Cash'));
  });

  test('partial refund then convert the rest', () async {
    final original = await seedPaidInvoice(price: 100, qty: 10);
    final cn = _creditNote(
      id: 'cn1',
      original: original,
      items: [_item(original.items.first.product, 5)], // 500
      settlement: CreditSettlement.refund,
    );
    await ReturnService.createCreditNote(
      creditNote: cn,
      originalInvoice: original,
      immediateRefund: (
        amount: 200,
        method: 'Cash',
        date: DateTime(2026, 3, 10),
        notes: null,
      ),
    );
    expect(
        await ReturnService.getRemainingCustomerCredit(
            customerId: 'c1', currencyCode: 'INR'),
        300);

    await ReturnService.convertCreditToRefund(
        creditNote: cn, amount: 300, date: DateTime(2026, 3, 15));
    expect(
        await ReturnService.getRemainingCustomerCredit(
            customerId: 'c1', currencyCode: 'INR'),
        0);
    expect((await ReturnService.getRefundsForCreditNote('cn1')), hasLength(2));
  });

  test('over-refund is rejected', () async {
    final original = await seedPaidInvoice(price: 100, qty: 10);
    final cn = _creditNote(
      id: 'cn1',
      original: original,
      items: [_item(original.items.first.product, 2)], // 200
      settlement: CreditSettlement.customerCredit,
    );
    await ReturnService.createCreditNote(creditNote: cn, originalInvoice: original);

    expect(
      () => ReturnService.recordRefund(
          creditNote: cn, amount: 250, date: DateTime(2026, 3, 12)),
      throwsA(isA<StateError>()),
    );
  });

  test('repeated partial returns accumulate in getReturnedQtyByLine', () async {
    final original = await seedPaidInvoice(stock: 50, qty: 10);
    final p = original.items.first.product;

    await ReturnService.createCreditNote(
      creditNote: _creditNote(
        id: 'cn1',
        original: original,
        items: [_item(p, 3)],
        settlement: CreditSettlement.customerCredit,
      ),
      originalInvoice: original,
    );
    await ReturnService.createCreditNote(
      creditNote: _creditNote(
        id: 'cn2',
        original: original,
        items: [_item(p, 2)],
        settlement: CreditSettlement.customerCredit,
      ),
      originalInvoice: original,
    );

    final returned = await ReturnService.getReturnedQtyByLine('i1');
    expect(returned['p1'], 5);
  });

  test('applyCustomerCreditToInvoice consumes credit and pays the invoice',
      () async {
    final original = await seedPaidInvoice(price: 100, qty: 10);
    await ReturnService.createCreditNote(
      creditNote: _creditNote(
        id: 'cn1',
        original: original,
        items: [_item(original.items.first.product, 5)], // 500 credit
        settlement: CreditSettlement.customerCredit,
      ),
      originalInvoice: original,
    );

    // new invoice for the same customer: 8 * 100 = 800
    final p2 = _prod(id: 'p2', price: 100, stock: 20);
    await ProductService.insertProduct(p2);
    final inv2 = _invoice(
        id: 'i2', number: '00000002', customer: _cust(), items: [_item(p2, 8)]);
    await InvoiceService.insertInvoice(inv2);
    final loaded2 = (await InvoiceService.getInvoiceById('i2'))!;

    final consumed = await ReturnService.applyCustomerCreditToInvoice(
        invoice: loaded2, amount: 500);
    expect(consumed, 500);

    final after = (await InvoiceService.getInvoiceById('i2'))!;
    expect(after.amountPaid, 500);
    expect(after.outstandingBalance, 300);
    expect(
        await ReturnService.getRemainingCustomerCredit(
            customerId: 'c1', currencyCode: 'INR'),
        0);
  });

  test('voidCreditNote reverses stock and settlement', () async {
    final original = await seedPaidInvoice(stock: 50, qty: 10); // stock 40
    final cn = _creditNote(
      id: 'cn1',
      original: original,
      items: [_item(original.items.first.product, 4)],
      settlement: CreditSettlement.customerCredit,
    );
    await ReturnService.createCreditNote(creditNote: cn, originalInvoice: original);
    expect((await ProductService.getProductById('p1'))!.stock, 44);

    await ReturnService.voidCreditNote('cn1');

    expect((await ProductService.getProductById('p1'))!.stock, 40);
    expect(
        await ReturnService.getRemainingCustomerCredit(
            customerId: 'c1', currencyCode: 'INR'),
        0);
    expect(await InvoiceService.getInvoiceById('cn1'), isNull); // soft-deleted
  });

  test('voidCreditNote is blocked once credit was applied to an invoice',
      () async {
    final original = await seedPaidInvoice(price: 100, qty: 10);
    await ReturnService.createCreditNote(
      creditNote: _creditNote(
        id: 'cn1',
        original: original,
        items: [_item(original.items.first.product, 5)],
        settlement: CreditSettlement.customerCredit,
      ),
      originalInvoice: original,
    );
    final p2 = _prod(id: 'p2', price: 100, stock: 20);
    await ProductService.insertProduct(p2);
    final inv2 = _invoice(
        id: 'i2', number: '00000002', customer: _cust(), items: [_item(p2, 8)]);
    await InvoiceService.insertInvoice(inv2);
    await ReturnService.applyCustomerCreditToInvoice(
        invoice: (await InvoiceService.getInvoiceById('i2'))!, amount: 300);

    expect(
      () => ReturnService.voidCreditNote('cn1'),
      throwsA(isA<StateError>()),
    );
  });

  test('voidCreditNote is blocked once a refund was paid', () async {
    final original = await seedPaidInvoice(stock: 50, qty: 10); // stock 40
    await ReturnService.createCreditNote(
      creditNote: _creditNote(
        id: 'cn1',
        original: original,
        items: [_item(original.items.first.product, 2)],
        settlement: CreditSettlement.refund,
      ),
      originalInvoice: original,
      immediateRefund: (
        amount: 200,
        method: 'Cash',
        date: DateTime(2026, 3, 10),
        notes: null
      ),
    );

    await expectLater(
        ReturnService.voidCreditNote('cn1'), throwsA(isA<StateError>()));
    expect((await ProductService.getProductById('p1'))!.stock, 42);
    expect(await ReturnService.getRefundsForCreditNote('cn1'), hasLength(1));
  });

  test('declineInvoice refuses while an active credit note exists', () async {
    final p = _prod(stock: 50);
    await ProductService.insertProduct(p);
    final inv = _invoice(
        id: 'i1', number: '00000001', customer: _cust(), items: [_item(p, 5)]);
    await InvoiceService.insertInvoice(inv); // stock 45
    await ReturnService.createCreditNote(
      creditNote: _creditNote(
        id: 'cn1',
        original: inv,
        items: [_item(p, 2)],
        settlement: CreditSettlement.customerCredit,
      ),
      originalInvoice: inv,
    ); // stock 47

    await InvoiceService.declineInvoice('i1');
    expect((await InvoiceService.getInvoiceById('i1'))!.status, isNot('declined'));
    expect((await ProductService.getProductById('p1'))!.stock, 47);

    // Void first, then decline returns only what's still out.
    await ReturnService.voidCreditNote('cn1'); // stock 45
    await InvoiceService.declineInvoice('i1'); // stock 50
    expect((await InvoiceService.getInvoiceById('i1'))!.status, 'declined');
    expect((await ProductService.getProductById('p1'))!.stock, 50);
  });

  test('credit notes leave only via void: no trash, no restore, delete cleans',
      () async {
    final original = await seedPaidInvoice(stock: 50, qty: 10);
    await ReturnService.createCreditNote(
      creditNote: _creditNote(
        id: 'cn1',
        original: original,
        items: [_item(original.items.first.product, 3)],
        settlement: CreditSettlement.customerCredit,
      ),
      originalInvoice: original,
    );
    Future<double> credit() => ReturnService.getRemainingCustomerCredit(
        customerId: 'c1', currencyCode: 'INR');
    expect(await credit(), 300);

    await InvoiceService.softDeleteInvoice('cn1');
    expect(await InvoiceService.getInvoiceById('cn1'), isNotNull);

    // A note trashed by an older build: its credit is not spendable.
    await db.update('invoices', {'deleted_at': '2026-03-11T00:00:00'},
        where: 'id = ?', whereArgs: ['cn1']);
    expect(await credit(), 0);
    await InvoiceService.restoreInvoice('cn1');
    expect(await InvoiceService.getInvoiceById('cn1'), isNull);

    await InvoiceService.permanentDeleteInvoice('cn1');
    expect(await db.query('customer_credits', where: "source_id = 'cn1'"),
        isEmpty);
  });

  test('updateInvoice locks customer / lines / total once credit notes exist',
      () async {
    final original = await seedPaidInvoice(stock: 50, qty: 10);
    await ReturnService.createCreditNote(
      creditNote: _creditNote(
        id: 'cn1',
        original: original,
        items: [_item(original.items.first.product, 3)],
        settlement: CreditSettlement.customerCredit,
      ),
      originalInvoice: original,
    );

    final changed = (await InvoiceService.getInvoiceById('i1'))!
      ..items = [_item(original.items.first.product, 12)];
    await expectLater(
        InvoiceService.updateInvoice(changed), throwsA(isA<StateError>()));
    expect((await InvoiceService.getInvoiceById('i1'))!.items.single.quantity,
        10);

    // Notes-only edit still saves.
    final noted = (await InvoiceService.getInvoiceById('i1'))!
      ..notes = 'delivered late';
    await InvoiceService.updateInvoice(noted);
    expect((await InvoiceService.getInvoiceById('i1'))!.notes, 'delivered late');
  });

  group('getPreviousBalanceDueForCustomer with returns', () {
    Future<Invoice> seedPartlyPaid() async {
      final p = _prod(price: 100, stock: 50);
      await ProductService.insertProduct(p);
      final inv = _invoice(
          id: 'i1',
          number: '00000001',
          customer: _cust(),
          items: [_item(p, 10)], // 1000
          date: DateTime(2026, 3, 1));
      await InvoiceService.insertInvoice(inv);
      final loaded = (await InvoiceService.getInvoiceById('i1'))!;
      await PaymentService.addPayment(
          invoice: loaded, amountPaid: 400, datePaid: DateTime(2026, 3, 1));
      return (await InvoiceService.getInvoiceById('i1'))!;
    }

    test('unused customer credit reduces the previous balance', () async {
      final inv = await seedPartlyPaid(); // outstanding 600
      expect(
        await InvoiceService.getPreviousBalanceDueForCustomer(
            customerId: 'c1',
            currencyCode: 'INR',
            asOfDate: DateTime(2026, 4, 1)),
        600,
      );

      await ReturnService.createCreditNote(
        creditNote: _creditNote(
          id: 'cn1',
          original: inv,
          items: [_item(inv.items.first.product, 2)], // 200 credit
          settlement: CreditSettlement.customerCredit,
        ),
        originalInvoice: inv,
      );

      expect(
        await InvoiceService.getPreviousBalanceDueForCustomer(
            customerId: 'c1',
            currencyCode: 'INR',
            asOfDate: DateTime(2026, 4, 1)),
        400,
      );
    });

    test('net customer credit clamps the previous balance at zero', () async {
      final inv = await seedPartlyPaid(); // outstanding 600
      await ReturnService.createCreditNote(
        creditNote: _creditNote(
          id: 'cn1',
          original: inv,
          items: [_item(inv.items.first.product, 8)], // 800 credit > 600
          settlement: CreditSettlement.customerCredit,
        ),
        originalInvoice: inv,
      );
      expect(
        await InvoiceService.getPreviousBalanceDueForCustomer(
            customerId: 'c1',
            currencyCode: 'INR',
            asOfDate: DateTime(2026, 4, 1)),
        0,
      );
    });

    test('an unpaid debit note adds to the previous balance', () async {
      final p = _prod(price: 100, stock: 50);
      await ProductService.insertProduct(p);
      final inv = _invoice(
          id: 'i1',
          number: '00000001',
          customer: _cust(),
          items: [_item(p, 10)],
          date: DateTime(2026, 3, 1));
      await InvoiceService.insertInvoice(inv);
      final loaded = (await InvoiceService.getInvoiceById('i1'))!;
      await PaymentService.addPayment(
          invoice: loaded, amountPaid: 1000, datePaid: DateTime(2026, 3, 1));

      expect(
        await InvoiceService.getPreviousBalanceDueForCustomer(
            customerId: 'c1',
            currencyCode: 'INR',
            asOfDate: DateTime(2026, 4, 1)),
        0,
      );

      final dn = Invoice(
        id: 'dn1',
        invoiceNumber: 'DN-dn1',
        customer: _cust(),
        items: [_item(p, 1)], // 100
        date: DateTime(2026, 3, 15),
        type: 'Debit Note',
        taxMode: TaxMode.perItem,
        originalInvoiceId: 'i1',
        returnReason: 'Price revision',
      );
      await ReturnService.createDebitNote(debitNote: dn, originalInvoice: loaded);

      expect(
        await InvoiceService.getPreviousBalanceDueForCustomer(
            customerId: 'c1',
            currencyCode: 'INR',
            asOfDate: DateTime(2026, 4, 1)),
        100,
      );
    });
  });

  test('customer statement shows credit note + refund lines', () async {
    final p = _prod(price: 100, stock: 50);
    await ProductService.insertProduct(p);
    await InvoiceService.insertInvoice(_invoice(
        id: 'i1',
        number: '00000001',
        customer: _cust(),
        items: [_item(p, 10)],
        date: DateTime(2026, 3, 1)));
    final loaded = (await InvoiceService.getInvoiceById('i1'))!;
    await PaymentService.addPayment(
        invoice: loaded, amountPaid: 1000, datePaid: DateTime(2026, 3, 2));

    await ReturnService.createCreditNote(
      creditNote: _creditNote(
        id: 'cn1',
        original: loaded,
        items: [_item(p, 3)], // 300
        settlement: CreditSettlement.refund,
      ),
      originalInvoice: loaded,
      immediateRefund: (
        amount: 300,
        method: 'Cash',
        date: DateTime(2026, 3, 12),
        notes: null,
      ),
    );

    final statements = await ReportService.getCustomerStatements(
        'c1', DateTime(2026, 1, 1), DateTime(2026, 12, 31),
        currencyCode: 'INR');
    expect(statements, hasLength(1));
    final types = statements.first.lines.map((l) => l.type).toList();
    expect(types, containsAll(['Invoice', 'Payment', 'Credit Note', 'Refund']));
    // invoice 1000 - payment 1000 - CN 300 + refund 300 = 0
    expect(statements.first.closingBalance, closeTo(0, 0.001));
  });

  group('reports net off returns', () {
    Future<void> seedSale({int taxRate = 0}) async {
      final p = _prod(price: 100, stock: 50, taxRate: taxRate);
      await ProductService.insertProduct(p);
      await InvoiceService.insertInvoice(_invoice(
          id: 'i1',
          number: '00000001',
          customer: _cust(),
          items: [_item(p, 10)], // 1000 (+ tax)
          date: DateTime(2026, 3, 5)));
      final loaded = (await InvoiceService.getInvoiceById('i1'))!;
      await PaymentService.addPayment(
          invoice: loaded, amountPaid: loaded.total, datePaid: DateTime(2026, 3, 6));
    }

    final from = DateTime(2026, 1, 1);
    final to = DateTime(2026, 12, 31);

    test('revenue summary subtracts a credit note', () async {
      await seedSale();
      final before = await ReportService.getRevenueSummary(from, to);
      expect(before.billed, 1000);

      final original = (await InvoiceService.getInvoiceById('i1'))!;
      await ReturnService.createCreditNote(
        creditNote: _creditNote(
          id: 'cn1',
          original: original,
          items: [_item(original.items.first.product, 3)], // 300
          settlement: CreditSettlement.customerCredit,
        ),
        originalInvoice: original,
      );

      final after = await ReportService.getRevenueSummary(from, to);
      expect(after.billed, 700);
    });

    test('revenue collected drops by a refund paid out', () async {
      await seedSale();
      final original = (await InvoiceService.getInvoiceById('i1'))!;
      final before = await ReportService.getRevenueSummary(from, to);
      expect(before.collected, 1000);

      await ReturnService.createCreditNote(
        creditNote: _creditNote(
          id: 'cn1',
          original: original,
          items: [_item(original.items.first.product, 2)], // 200
          settlement: CreditSettlement.refund,
        ),
        originalInvoice: original,
        immediateRefund: (
          amount: 200,
          method: 'Cash',
          date: DateTime(2026, 3, 10),
          notes: null,
        ),
      );

      final after = await ReportService.getRevenueSummary(from, to);
      expect(after.collected, 800);
      expect(after.billed, 800);
    });

    test('tax by rate nets a credit note', () async {
      await seedSale(taxRate: 18); // invoice tax = 180
      final original = (await InvoiceService.getInvoiceById('i1'))!;
      await ReturnService.createCreditNote(
        creditNote: _creditNote(
          id: 'cn1',
          original: original,
          items: [_item(original.items.first.product, 5)], // half back → tax 90
          settlement: CreditSettlement.customerCredit,
        ),
        originalInvoice: original,
      );

      final buckets = await ReportService.getTaxByRate(from, to);
      expect(buckets, hasLength(1));
      expect(buckets.first.taxCollected, closeTo(90, 0.01));
    });

    test('top products subtracts returned units', () async {
      await seedSale();
      final original = (await InvoiceService.getInvoiceById('i1'))!;
      await ReturnService.createCreditNote(
        creditNote: _creditNote(
          id: 'cn1',
          original: original,
          items: [_item(original.items.first.product, 4)],
          settlement: CreditSettlement.customerCredit,
        ),
        originalInvoice: original,
      );

      final products = await ReportService.getTopProducts(from, to);
      expect(products, hasLength(1));
      expect(products.first.unitsSold, 6); // 10 sold − 4 returned
      expect(products.first.revenue, 600);
    });
  });

  test('getNotesForInvoice returns linked credit notes', () async {
    final original = await seedPaidInvoice(stock: 50, qty: 10);
    await ReturnService.createCreditNote(
      creditNote: _creditNote(
        id: 'cn1',
        original: original,
        items: [_item(original.items.first.product, 3)],
        settlement: CreditSettlement.customerCredit,
      ),
      originalInvoice: original,
    );
    final notes = await ReturnService.getNotesForInvoice('i1');
    expect(notes, hasLength(1));
    expect(notes.first.type, 'Credit Note');
    expect(notes.first.originalInvoiceId, 'i1');
    expect(notes.first.creditSettlement, CreditSettlement.customerCredit);
  });

  test('getNotesForInvoices groups notes by invoice, skips ones without',
      () async {
    final original = await seedPaidInvoice(stock: 50, qty: 10);
    await ReturnService.createCreditNote(
      creditNote: _creditNote(
        id: 'cn1',
        original: original,
        items: [_item(original.items.first.product, 3)],
        settlement: CreditSettlement.customerCredit,
      ),
      originalInvoice: original,
    );
    final byInvoice =
        await ReturnService.getNotesForInvoices(['i1', 'no-such-invoice']);
    expect(byInvoice.keys, ['i1']);
    expect(byInvoice['i1']!.single.id, 'cn1');
    expect(await ReturnService.getNotesForInvoices([]), isEmpty);
  });

  test('getCustomerCreditSources names the credit note and its invoice',
      () async {
    final original = await seedPaidInvoice(stock: 50, qty: 10);
    await ReturnService.createCreditNote(
      creditNote: _creditNote(
        id: 'cn1',
        original: original,
        items: [_item(original.items.first.product, 3)],
        settlement: CreditSettlement.customerCredit,
      ),
      originalInvoice: original,
    );
    final sources = await ReturnService.getCustomerCreditSources(
        customerId: 'c1', currencyCode: 'INR');
    expect(sources, hasLength(1));
    expect(sources.single.noteNumber, 'CN-cn1');
    expect(sources.single.againstNumber, original.invoiceNumber);
    expect(
        sources.single.remaining,
        await ReturnService.getRemainingCustomerCredit(
            customerId: 'c1', currencyCode: 'INR'));
    expect(
        await ReturnService.getCustomerCreditSources(
            customerId: 'c1', currencyCode: 'USD'),
        isEmpty);
  });
}
