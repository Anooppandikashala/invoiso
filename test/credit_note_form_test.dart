// Credit note from an invoice is made in the create-invoice form: lines are
// prefilled at the qty still returnable, discounts carry over, save restocks
// and settles. Same ffi sqflite harness as invoice_update_test.dart.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/database/customer_service.dart';
import 'package:invoiso/database/database_helper.dart';
import 'package:invoiso/database/invoice_service.dart';
import 'package:invoiso/database/product_service.dart';
import 'package:invoiso/database/return_service.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/models/additional_cost.dart';
import 'package:invoiso/models/customer.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/invoice_item.dart';
import 'package:invoiso/models/product.dart';
import 'package:invoiso/providers/sqlite_repository_overrides.dart';
import 'package:invoiso/repositories/sqlite/sqlite_company_info_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_installation_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_invoice_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_payment_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_settings_repository.dart';
import 'package:invoiso/services/backend_services.dart';
import 'package:invoiso/screens/create_invoice_screen_v2.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tmp = Directory.systemTemp.createTempSync('invoiso_cn_form_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => tmp.path);
    await DatabaseHelper().switchToFile('cn_form_test.db');
    // The create path numbers new documents through BackendServices.
    BackendServices.configure(
      settings: SqliteSettingsRepository(),
      companyInfo: SqliteCompanyInfoRepository(),
      invoices: SqliteInvoiceRepository(),
      payments: SqlitePaymentRepository(),
      installation: SqliteInstallationRepository(),
    );
  });

  tearDownAll(() async {
    await DatabaseHelper().close();
    tmp.deleteSync(recursive: true);
  });

  final product = Product(
    id: 'p1',
    name: 'Widget',
    description: '',
    price: 100,
    stock: 10,
    hsncode: '',
    tax_rate: 0,
  );
  final customer = Customer(
    id: 'c1',
    name: 'Test Customer',
    email: '',
    phone: '',
    address: '',
    gstin: '',
  );

  // DB work is real I/O — let it finish outside the fake clock.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
    }
  }

  // Opens the form as "Credit Note against [inv]" and taps Save.
  Future<void> saveCreditNoteFor(WidgetTester tester, Invoice inv) async {
    tester.view.physicalSize = const Size(1800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: sqliteRepositoryOverrides,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
            body: CreateInvoiceScreenV2(
                cloneFrom: inv, cloneType: 'Credit Note')),
      ),
    ));
    await settle(tester);

    await tester.tap(find.byIcon(Icons.save_outlined));
    await tester.pump();
    await settle(tester);
  }

  testWidgets(
      'credit note from invoice: Left qty, % line + flat invoice discount, '
      'restock, reduce invoice', (tester) async {
    final inv = (await tester.runAsync(() async {
      await ProductService.insertProduct(product);
      await CustomerService.insertCustomer(customer);
      // 4 × 100 at 10% off = 360; flat 40 off the bill; 20 shipping.
      await InvoiceService.insertInvoice(Invoice(
        id: 'i1',
        invoiceNumber: '00000001',
        customer: customer,
        items: [
          InvoiceItem(
              product: product,
              quantity: 4,
              discount: 10,
              discountIsPercent: true)
        ],
        date: DateTime(2026, 1, 1),
        type: 'Invoice',
        additionalCosts: const [AdditionalCost(label: 'Shipping', amount: 20)],
        invoiceDiscountType: InvoiceDiscountType.amount,
        invoiceDiscountValue: 40,
      ));
      // One unit already returned on an earlier credit note.
      await ReturnService.createCreditNote(
        creditNote: Invoice(
          id: 'cn0',
          invoiceNumber: '00000001',
          customer: customer,
          items: [InvoiceItem(product: product, quantity: 1)],
          date: DateTime(2026, 1, 2),
          type: 'Credit Note',
          originalInvoiceId: 'i1',
          creditSettlement: CreditSettlement.customerCredit,
        ),
      );
      return InvoiceService.getInvoiceById('i1');
    }))!;

    await saveCreditNoteFor(tester, inv);

    await tester.runAsync(() async {
      final notes = await ReturnService.getNotesForInvoice('i1');
      final cn = notes.singleWhere((n) => n.id != 'cn0');
      final line = cn.items.single;
      expect(line.quantity, 3);
      expect(line.discountIsPercent, isTrue);
      expect(line.discount, 10);
      // Flat invoice discount scaled to the returned share: 40 × 270 / 360.
      expect(cn.invoiceDiscountValue, closeTo(30, 0.001));
      // Extra costs go back only on the first return (cn0 was first).
      expect(cn.additionalCosts, isEmpty);
      expect(cn.invoiceTitle, salesReturnTitle);
      expect(cn.creditSettlement, CreditSettlement.reduceInvoice);

      // 10 − 4 sold + 1 earlier return + 3 now.
      expect((await ProductService.getProductById('p1'))!.stock, 10);

      final original = (await InvoiceService.getInvoiceById('i1'))!;
      final cnPayment =
          original.payments.singleWhere((p) => p.paymentMethod == 'Credit Note');
      expect(cnPayment.amountPaid, closeTo(cn.total, 0.001));
    });
  });

  testWidgets(
      'first credit note: invoice customer kept even if no longer saved, '
      'extra costs and currency carried', (tester) async {
    // Customer c9 was never saved (or was deleted) in Customers.
    final gone = Customer(
      id: 'c9',
      name: 'Walk-in Buyer',
      email: '',
      phone: '',
      address: '',
      gstin: '',
    );
    final inv = (await tester.runAsync(() async {
      await InvoiceService.insertInvoice(Invoice(
        id: 'i2',
        invoiceNumber: '00000002',
        customer: gone,
        items: [InvoiceItem(product: product, quantity: 2)],
        date: DateTime(2026, 1, 5),
        type: 'Invoice',
        additionalCosts: const [AdditionalCost(label: 'Shipping', amount: 15)],
        currencyCode: 'USD',
        currencySymbol: r'$',
      ));
      return InvoiceService.getInvoiceById('i2');
    }))!;

    await saveCreditNoteFor(tester, inv);

    await tester.runAsync(() async {
      final cn = (await ReturnService.getNotesForInvoice('i2')).single;
      expect(cn.customer.id, 'c9');
      expect(cn.items.single.quantity, 2);
      expect(cn.additionalCosts.single.amount, 15);
      expect(cn.currencyCode, 'USD');
    });
  });

  testWidgets('credit note against a receipt: refund, never reduce balance',
      (tester) async {
    final receipt = (await tester.runAsync(() async {
      await InvoiceService.insertInvoice(Invoice(
        id: 'r1',
        invoiceNumber: '00000001',
        customer: customer,
        items: [InvoiceItem(product: product, quantity: 1)],
        date: DateTime(2026, 1, 6),
        type: 'Receipt',
      ));
      return InvoiceService.getInvoiceById('r1');
    }))!;
    final stockBefore = (await tester
        .runAsync(() => ProductService.getProductById('p1')))!
        .stock;

    await saveCreditNoteFor(tester, receipt);

    await tester.runAsync(() async {
      final cn = (await ReturnService.getNotesForInvoice('r1')).single;
      expect(cn.items.single.quantity, 1);
      expect(cn.creditSettlement, CreditSettlement.refund);
      expect(await ReturnService.getRefundsForCreditNote(cn.id), hasLength(1));
      expect((await InvoiceService.getInvoiceById('r1'))!.payments, isEmpty);
      expect((await ProductService.getProductById('p1'))!.stock,
          stockBefore + 1);
    });
  });
}
