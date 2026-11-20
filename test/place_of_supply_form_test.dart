// Invoice form, GST place of supply + reverse charge (Gstr1ExportPlan Part B3):
// new invoices default to the company's state, edit keeps the saved values,
// and an old invoice without a place of supply stays without one.
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
import 'package:invoiso/database/company_info_service.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/models/company_info.dart';
import 'package:invoiso/models/customer.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/invoice_item.dart';
import 'package:invoiso/models/product.dart';
import 'package:invoiso/providers/sqlite_repository_overrides.dart';
import 'package:invoiso/repositories/sqlite/sqlite_company_info_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_company_registry_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_installation_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_invoice_attachment_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_invoice_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_payment_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_return_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_settings_repository.dart';
import 'package:invoiso/screens/create_invoice_screen_v2.dart';
import 'package:invoiso/services/backend_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tmp = Directory.systemTemp.createTempSync('invoiso_pos_form_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => tmp.path);
    await DatabaseHelper().switchToFile('pos_form_test.db');
    BackendServices.configure(
      settings: SqliteSettingsRepository(),
      companyInfo: SqliteCompanyInfoRepository(),
      invoices: SqliteInvoiceRepository(),
      payments: SqlitePaymentRepository(),
      installation: SqliteInstallationRepository(),
      attachments: SqliteInvoiceAttachmentRepository(),
      returns: SqliteReturnRepository(),
      companyRegistry: SqliteCompanyRegistryRepository(),
    );
  });

  tearDownAll(() async {
    await DatabaseHelper().close();
    tmp.deleteSync(recursive: true);
  });

  final product = Product(
      id: 'p1', name: 'Widget', description: '', price: 100, stock: 50,
      hsncode: '', tax_rate: 0);
  final customer = Customer(
      id: 'c1', name: 'Test Customer', email: '', phone: '', address: '', gstin: '');

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 60; i++) {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
    }
  }

  Future<void> openForm(WidgetTester tester, CreateInvoiceScreenV2 form) async {
    tester.view.physicalSize = const Size(1800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: sqliteRepositoryOverrides,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: form),
      ),
    ));
    await settle(tester);
  }

  Future<Invoice> seed(String id, {String? pos, bool rcm = false}) async {
    await InvoiceService.insertInvoice(Invoice(
      id: id,
      invoiceNumber: id,
      customer: customer,
      items: [InvoiceItem(product: product, quantity: 1)],
      date: DateTime(2026, 11, 20),
      type: 'Invoice',
      placeOfSupply: pos,
      reverseCharge: rcm,
    ));
    return (await InvoiceService.getInvoiceById(id))!;
  }

  setUp(() async {
    // Company registered in Tamil Nadu (33).
    final db = await DatabaseHelper().database;
    await db.delete('company_info');
    await CompanyInfoService.insertCompanyInfo(CompanyInfo(
        name: 'Co', address: '', phone: '', email: '', website: '',
        gstin: '33ABCDE1234F1Z5'));
  });

  testWidgets('new invoice defaults place of supply to the company state',
      (tester) async {
    await tester.runAsync(() async {
      await ProductService.insertProduct(product);
      await CustomerService.insertCustomer(customer);
    });
    await openForm(tester, const CreateInvoiceScreenV2());
    expect(find.text('Place of Supply'), findsOneWidget);
    expect(find.text('33-Tamil Nadu'), findsOneWidget);
  });

  testWidgets('editing keeps the saved place of supply and reverse charge',
      (tester) async {
    final inv = (await tester.runAsync(() => seed('i1', pos: '29', rcm: true)))!;
    await openForm(tester, CreateInvoiceScreenV2(invoiceToEdit: inv));
    expect(find.text('29-Karnataka'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.update));
    await tester.pump();
    await settle(tester);

    await tester.runAsync(() async {
      final saved = (await InvoiceService.getInvoiceById('i1'))!;
      expect([saved.placeOfSupply, saved.reverseCharge], ['29', true]);
    });
  });

  testWidgets('an old invoice without place of supply stays without one',
      (tester) async {
    final inv = (await tester.runAsync(() => seed('i2')))!;
    await openForm(tester, CreateInvoiceScreenV2(invoiceToEdit: inv));
    expect(find.text('Not set'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.update));
    await tester.pump();
    await settle(tester);

    await tester.runAsync(() async {
      final saved = (await InvoiceService.getInvoiceById('i2'))!;
      expect([saved.placeOfSupply, saved.reverseCharge], [null, false]);
    });
  });
}
