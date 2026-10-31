// Save-time stock check: a draft finalized after another sale took the stock
// warns before going below zero (Cancel keeps the draft, Save anyway goes
// negative). Same ffi sqflite harness as credit_note_form_test.dart.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:invoiso/database/customer_service.dart';
import 'package:invoiso/database/database_helper.dart';
import 'package:invoiso/database/invoice_service.dart';
import 'package:invoiso/database/product_service.dart';
import 'package:invoiso/l10n/app_localizations.dart';
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
import 'package:invoiso/services/invoice_pdf_services.dart';
import 'package:invoiso/screens/create_invoice_screen_v2.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tmp = Directory.systemTemp.createTempSync('invoiso_stock_check_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => tmp.path);
    await DatabaseHelper().switchToFile('stock_check_test.db');
    // The save path numbers documents through BackendServices.
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
    id: 'pA',
    name: 'Product A',
    description: '',
    price: 100,
    stock: 5,
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

  // Busy full-suite runs make fixed waits flaky — settle until [finder] shows.
  Future<void> waitFor(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
      await settle(tester);
    }
  }

  Future<void> waitUntil(
      WidgetTester tester, Future<bool> Function() done) async {
    for (var i = 0; i < 100; i++) {
      await settle(tester);
      if ((await tester.runAsync(done))!) return;
    }
  }

  testWidgets('finalizing a draft after another sale warns before negative stock',
      (tester) async {
    final draft = (await tester.runAsync(() async {
      await ProductService.insertProduct(product);
      await CustomerService.insertCustomer(customer);
      // Draft A × 5 (stock untouched), then a real sale of A × 3 → stock 2.
      await InvoiceService.insertInvoice(Invoice(
        id: '00000001',
        customer: customer,
        items: [InvoiceItem(product: product, quantity: 5)],
        date: DateTime(2026, 1, 1),
        type: 'Invoice',
        isDraft: true,
      ));
      await InvoiceService.insertInvoice(Invoice(
        id: '00000002',
        invoiceNumber: '00000001',
        customer: customer,
        items: [InvoiceItem(product: product, quantity: 3)],
        date: DateTime(2026, 1, 2),
        type: 'Invoice',
      ));
      return InvoiceService.getInvoiceById('00000001');
    }))!;

    tester.view.physicalSize = const Size(1800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: sqliteRepositoryOverrides,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: CreateInvoiceScreenV2(invoiceToEdit: draft)),
      ),
    ));
    await settle(tester);

    // Finalize → back-dated draft asks about the date (keep it), then the
    // warning lists the short product; Cancel keeps the draft.
    await tester.tap(find.byIcon(Icons.task_alt));
    await tester.pump();
    await waitFor(tester, find.textContaining('Keep '));
    await tester.tap(find.textContaining('Keep '));
    await tester.pump();
    await waitFor(tester, find.text('Go back'));
    expect(find.textContaining('Product A: in stock 2, on invoice 5 (short by 3)'),
        findsOneWidget);
    await tester.tap(find.text('Go back'));
    await tester.pump();
    await settle(tester);
    await tester.runAsync(() async {
      expect((await InvoiceService.getInvoiceById('00000001'))!.isDraft, isTrue);
      expect((await ProductService.getProductById('pA'))!.stock, 2);
    });

    // Finalize again → Save anyway → finalized, stock goes negative.
    await tester.tap(find.byIcon(Icons.task_alt));
    await tester.pump();
    await waitFor(tester, find.textContaining('Keep '));
    await tester.tap(find.textContaining('Keep '));
    await tester.pump();
    await waitFor(tester, find.text('Save anyway'));
    await tester.tap(find.text('Save anyway'));
    await tester.pump();
    await waitUntil(tester, () async =>
        !(await InvoiceService.getInvoiceById('00000001'))!.isDraft);
    await tester.runAsync(() async {
      expect((await InvoiceService.getInvoiceById('00000001'))!.isDraft, isFalse);
      expect((await ProductService.getProductById('pA'))!.stock, -3);
    });
  });

  testWidgets('finalizing a back-dated draft: Use today + Payment choice',
      (tester) async {
    // Unlimited stock: no stock warning, independent of the test above.
    final service = Product(
      id: 'pB',
      name: 'Product B',
      description: '',
      price: 100,
      stock: 0,
      hsncode: '',
      tax_rate: 0,
      unlimitedStock: true,
    );
    final draft = (await tester.runAsync(() async {
      await ProductService.insertProduct(service);
      await InvoiceService.insertInvoice(Invoice(
        id: '00000003',
        customer: customer,
        items: [InvoiceItem(product: service, quantity: 1)],
        date: DateTime(2026, 1, 3),
        type: 'Invoice',
        isDraft: true,
      ));
      return InvoiceService.getInvoiceById('00000003');
    }))!;

    tester.view.physicalSize = const Size(1800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: sqliteRepositoryOverrides,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: CreateInvoiceScreenV2(invoiceToEdit: draft)),
      ),
    ));
    await settle(tester);

    // A draft has no number yet — the header previews the next one.
    final next = await tester.runAsync(
        () => InvoicePdfServices.peekNextInvoiceNumber('Invoice'));
    expect(find.textContaining('#[$next]'), findsOneWidget);

    await tester.ensureVisible(find.text('Paid'));
    await tester.tap(find.text('Paid'));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.task_alt));
    await tester.pump();
    await waitFor(tester, find.text('Use today'));
    await tester.tap(find.text('Use today'));
    await tester.pump();
    await waitUntil(tester, () async =>
        (await InvoiceService.getInvoiceById('00000003'))!
            .outstandingBalance ==
        0);
    final saved = (await tester.runAsync(
        () => InvoiceService.getInvoiceById('00000003')))!;
    expect(saved.isDraft, isFalse);
    expect(saved.outstandingBalance, 0);
    final now = DateTime.now();
    expect(DateTime(saved.date.year, saved.date.month, saved.date.day),
        DateTime(now.year, now.month, now.day));
  });
}
