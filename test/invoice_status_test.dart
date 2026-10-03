// Quotation lifecycle + invoice decline, exercised through the real
// InvoiceService/ProductService against an ffi sqflite file in a temp dir
// (path_provider's channel is mocked to point there).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:invoiso/database/database_helper.dart';
import 'package:invoiso/database/invoice_service.dart';
import 'package:invoiso/database/payment_service.dart';
import 'package:invoiso/database/product_service.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/models/customer.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/invoice_item.dart';
import 'package:invoiso/models/invoice_list_filter.dart';
import 'package:invoiso/models/product.dart';
import 'package:invoiso/models/user.dart';
import 'package:invoiso/providers/sqlite_repository_overrides.dart';
import 'package:invoiso/screens/invoice_management_screen_v2.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tmp = Directory.systemTemp.createTempSync('invoiso_status_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => tmp.path);
  });

  tearDownAll(() async {
    await DatabaseHelper().close();
    tmp.deleteSync(recursive: true);
  });

  // Fresh DB file per test so stock/status never leak between cases.
  var dbCounter = 0;
  setUp(() async {
    await DatabaseHelper().switchToFile('status_test_${dbCounter++}.db');
  });

  final customer = Customer(
    id: 'c1',
    name: 'Test Customer',
    email: '',
    phone: '',
    address: '',
    gstin: '',
  );

  Future<Product> addProduct({int stock = 10}) async {
    final p = Product(
      id: 'p1',
      name: 'Widget',
      description: '',
      price: 100,
      stock: stock,
      hsncode: '',
      tax_rate: 0,
    );
    await ProductService.insertProduct(p);
    return p;
  }

  Invoice doc(String id, String type, Product p, {double qty = 3}) => Invoice(
        id: id,
        customer: customer,
        items: [InvoiceItem(product: p, quantity: qty)],
        date: DateTime(2026, 1, 1),
        dueDate: DateTime(2026, 1, 15),
        type: type,
      );

  // One active + one declined unpaid invoice (300.00 each, past due).
  Future<void> seedActiveAndDeclined() async {
    final p = await addProduct();
    await InvoiceService.insertInvoice(doc('i1', 'Invoice', p));
    await InvoiceService.insertInvoice(doc('i2', 'Invoice', p));
    await InvoiceService.declineInvoice('i2');
  }

  Future<int> stockOf(String id) async =>
      (await ProductService.getProductById(id))!.stock;

  test('quotation insert and edit do not touch stock', () async {
    final p = await addProduct();
    final q = doc('q1', 'Quotation', p);
    await InvoiceService.insertInvoice(q);
    expect(await stockOf('p1'), 10);

    q.items = [InvoiceItem(product: p, quantity: 5)];
    await InvoiceService.updateInvoice(q);
    expect(await stockOf('p1'), 10);
  });

  test('invoice insert deducts stock', () async {
    final p = await addProduct();
    await InvoiceService.insertInvoice(doc('i1', 'Invoice', p));
    expect(await stockOf('p1'), 7);
  });

  test('declineInvoice restores stock once and drops it from dashboard',
      () async {
    final p = await addProduct();
    await InvoiceService.insertInvoice(doc('i1', 'Invoice', p));
    expect(await stockOf('p1'), 7);

    await InvoiceService.declineInvoice('i1');
    expect(await stockOf('p1'), 10);
    expect((await InvoiceService.getInvoiceById('i1'))!.status, 'declined');

    // One-way: declining again must not restore stock a second time.
    await InvoiceService.declineInvoice('i1');
    expect(await stockOf('p1'), 10);

    final fin = await InvoiceService.getDashboardFinancials();
    expect(fin.count, 0);
    expect(fin.outstanding, 0.0);
  });

  test('declineInvoice ignores quotations', () async {
    final p = await addProduct();
    await InvoiceService.insertInvoice(doc('q1', 'Quotation', p));
    await InvoiceService.declineInvoice('q1');
    expect(await stockOf('p1'), 10);
    expect((await InvoiceService.getInvoiceById('q1'))!.status, isNull);
  });

  test('quotation -> invoice conversion links both and deducts stock once',
      () async {
    final p = await addProduct();
    await InvoiceService.insertInvoice(doc('q1', 'Quotation', p));

    // insertInvoice alone stamps the quotation (same transaction).
    final inv = doc('i1', 'Invoice', p)..convertedFromInvoiceId = 'q1';
    await InvoiceService.insertInvoice(inv);

    final q = (await InvoiceService.getInvoiceById('q1'))!;
    expect(q.status, 'converted');
    expect(q.isConverted, isTrue);
    expect(q.convertedToInvoiceId, 'i1');
    expect((await InvoiceService.getInvoiceById('i1'))!.convertedFromInvoiceId,
        'q1');
    expect(await stockOf('p1'), 7);
  });

  // Quotation q1 converted into invoice i1.
  Future<void> seedConverted() async {
    final p = await addProduct();
    await InvoiceService.insertInvoice(doc('q1', 'Quotation', p));
    await InvoiceService.insertInvoice(
        doc('i1', 'Invoice', p)..convertedFromInvoiceId = 'q1');
  }

  Future<Invoice> quote() async =>
      (await InvoiceService.getInvoiceById('q1'))!;

  test('declining the converted invoice reverts quotation to accepted',
      () async {
    await seedConverted();
    await InvoiceService.declineInvoice('i1');
    expect((await quote()).status, 'accepted');
    expect((await quote()).convertedToInvoiceId, isNull);
  });

  test('trashing the converted invoice reverts quotation; restore re-links',
      () async {
    await seedConverted();
    await InvoiceService.softDeleteInvoice('i1');
    expect((await quote()).status, 'accepted');
    expect((await quote()).convertedToInvoiceId, isNull);

    await InvoiceService.restoreInvoice('i1');
    expect((await quote()).status, 'converted');
    expect((await quote()).convertedToInvoiceId, 'i1');
  });

  test('restore does not re-link a quotation converted again meanwhile',
      () async {
    await seedConverted();
    final p = (await ProductService.getProductById('p1'))!;
    await InvoiceService.softDeleteInvoice('i1');
    await InvoiceService.insertInvoice(
        doc('i2', 'Invoice', p)..convertedFromInvoiceId = 'q1');

    await InvoiceService.restoreInvoice('i1');
    expect((await quote()).convertedToInvoiceId, 'i2');
  });

  test('restoring a declined invoice does not re-link', () async {
    await seedConverted();
    await InvoiceService.declineInvoice('i1');
    await InvoiceService.softDeleteInvoice('i1');
    await InvoiceService.restoreInvoice('i1');
    expect((await quote()).status, 'accepted');
    expect((await quote()).convertedToInvoiceId, isNull);
  });

  test('permanently deleting the converted invoice reverts quotation',
      () async {
    await seedConverted();
    await InvoiceService.permanentDeleteInvoice('i1');
    expect((await quote()).status, 'accepted');
    expect((await quote()).convertedToInvoiceId, isNull);
  });

  test('previous balance due skips declined invoices', () async {
    await seedActiveAndDeclined();
    final due = await InvoiceService.getPreviousBalanceDueForCustomer(
      customerId: 'c1',
      currencyCode: 'INR',
      asOfDate: DateTime(2026, 2, 1),
    );
    expect(due, closeTo(300.0, 0.001));
  });

  test('payments on declined invoices are not revenue', () async {
    await seedActiveAndDeclined();
    for (final id in ['i1', 'i2']) {
      await PaymentService.addPayment(
        invoice: (await InvoiceService.getInvoiceById(id))!,
        amountPaid: 100,
        datePaid: DateTime.now(),
      );
    }

    expect((await InvoiceService.getDashboardFinancials()).revenue, 100.0);
    final monthly = await InvoiceService.getMonthlyRevenue();
    expect(monthly.fold<double>(0, (s, m) => s + (m['revenue'] as double)),
        100.0);
    final top = (await InvoiceService.getTopCustomers()).single;
    expect(top['total_paid'], 100.0);
    expect(top['invoice_count'], 1);
  });

  test('top products skip declined invoices', () async {
    await seedActiveAndDeclined();
    final top = await InvoiceService.getTopProducts();
    expect(top.single['total_qty'], 3.0);
  });

  test('unpaid / overdue list filters skip declined; "all" keeps them',
      () async {
    await seedActiveAndDeclined();
    Future<List<String>> ids(InvoiceListFilter f) async =>
        (await InvoiceService.getInvoicesPaginated(
                filterType: 'Invoice', filter: f))
            .map((i) => i.id)
            .toList();

    expect(await ids(const InvoiceListFilter(paymentStatus: 'unpaid')),
        ['i1']);
    expect(await ids(const InvoiceListFilter(dueDate: 'overdue')), ['i1']);
    expect(
        await InvoiceService.getInvoiceCount(
            filterType: 'Invoice',
            filter: const InvoiceListFilter(paymentStatus: 'unpaid')),
        1);
    expect((await ids(const InvoiceListFilter())).toSet(), {'i1', 'i2'});
  });

  test('"Declined" chip shows only declined; "Hide declined" drops them',
      () async {
    await seedActiveAndDeclined();
    Future<List<String>> ids(InvoiceListFilter f) async =>
        (await InvoiceService.getInvoicesPaginated(
                filterType: 'Invoice', filter: f))
            .map((i) => i.id)
            .toList();

    const declinedOnly = InvoiceListFilter(paymentStatus: 'declined');
    expect(await ids(declinedOnly), ['i2']);
    expect(
        await InvoiceService.getInvoiceCount(
            filterType: 'Invoice', filter: declinedOnly),
        1);
    expect(await ids(const InvoiceListFilter(hideDeclined: true)), ['i1']);
    // Chip combined with a balance filter still returns the declined invoice.
    expect(
        await ids(const InvoiceListFilter(
            paymentStatus: 'declined', hidePaid: true)),
        ['i2']);
    // Chip wins over the hide switch.
    expect(
        await ids(const InvoiceListFilter(
            paymentStatus: 'declined', hideDeclined: true)),
        ['i2']);
  });

  // DB work is real I/O — let it finish outside the fake clock.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
    }
  }

  // Invoice list screen (wide layout) over the seeded active + declined pair.
  Future<void> pumpInvoiceList(WidgetTester tester) async {
    await tester.runAsync(seedActiveAndDeclined);
    tester.view.physicalSize = const Size(1800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: sqliteRepositoryOverrides,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: InvoiceManagementScreenV2(
            onEditInvoice: (_) {},
            onCloneInvoice: (_, __) {},
            user: User(
                id: 'u1', username: 'admin', password: '', userType: 'admin'),
          ),
        ),
      ),
    ));
    await settle(tester);
  }

  testWidgets('bulk Mark Paid skips declined invoices', (tester) async {
    await pumpInvoiceList(tester);
    await tester.tap(find.byType(Checkbox).first); // select all on page
    await tester.pump();
    await tester.tap(find.text('Mark Paid'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Mark as Paid'));
    await tester.pump();
    await settle(tester);

    await tester.runAsync(() async {
      expect(await PaymentService.getPaymentsForInvoice('i1'), hasLength(1));
      expect(await PaymentService.getPaymentsForInvoice('i2'), isEmpty);
    });
  });

  // Header checkbox + one per row.
  int rowCount() => find.byType(Checkbox).evaluate().length - 1;

  Future<void> applyFilter(WidgetTester tester,
      {String? chip, bool hideDeclined = false}) async {
    await tester.tap(find.text('Filter'));
    await tester.pumpAndSettle();
    if (chip != null) {
      await tester.tap(find.widgetWithText(ChoiceChip, chip));
    }
    if (hideDeclined) {
      await tester.tap(find.text('Hide declined invoices'));
    }
    await tester.pump();
    await tester.tap(find.text('Apply'));
    await tester.pump(); // starts the dialog's close animation
    await tester.pump(const Duration(milliseconds: 500));
    await settle(tester);
  }

  testWidgets('filter dialog: Declined chip shows only declined',
      (tester) async {
    await pumpInvoiceList(tester);
    expect(rowCount(), 2);
    await applyFilter(tester, chip: 'Declined');
    expect(rowCount(), 1);
    expect(find.text('Declined'), findsOneWidget); // the row's status pill
  });

  testWidgets('filter dialog: Hide declined switch drops declined',
      (tester) async {
    await pumpInvoiceList(tester);
    await applyFilter(tester, hideDeclined: true);
    expect(rowCount(), 1);
    expect(find.text('Declined'), findsNothing);
  });
}
