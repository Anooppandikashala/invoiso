// Reports → Tax tab (TaxTabRedesignPlan.md): sub-tabs, HSN summary loaded on
// first view, paging, B2B/B2C filter and HSN search.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/database/database_helper.dart';
import 'package:invoiso/database/invoice_service.dart';
import 'package:invoiso/l10n/app_localizations.dart';
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
import 'package:invoiso/screens/reports_screen.dart';
import 'package:invoiso/services/backend_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tmp = Directory.systemTemp.createTempSync('invoiso_reports_tax_tab_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => tmp.path);
    await DatabaseHelper().switchToFile('reports_tax_tab_test.db');
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

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 40)));
      await tester.pump();
    }
  }

  Product p(String hsn) => Product(
      id: 'p$hsn', name: 'Item $hsn', description: '', price: 100, stock: 0,
      hsncode: hsn, tax_rate: 18, unlimitedStock: true);

  testWidgets('Tax sub-tabs: HSN loads on demand, pages, filters, searches',
      (tester) async {
    await tester.runAsync(() async {
      // 30 HSN codes on a B2B invoice + one on a B2C invoice, dated today.
      await InvoiceService.insertInvoice(Invoice(
        id: 'i1', invoiceNumber: '00000001',
        customer: Customer(id: 'c1', name: 'Reg', email: '', phone: '',
            address: '', gstin: '33PQRST6789L1ZQ'),
        items: [for (var h = 1001; h <= 1030; h++) InvoiceItem(product: p('$h'), quantity: 1)],
        date: DateTime.now(), type: 'Invoice', taxMode: TaxMode.perItem));
      await InvoiceService.insertInvoice(Invoice(
        id: 'i2', invoiceNumber: '00000002',
        customer: Customer(id: 'c2', name: 'Walk-in', email: '', phone: '',
            address: '', gstin: ''),
        items: [InvoiceItem(product: p('9999'), quantity: 1)],
        date: DateTime.now(), type: 'Invoice', taxMode: TaxMode.perItem));
    });

    // The test font draws every glyph as a wide box, so long nav labels
    // overflow here only — ignore layout overflow, check behaviour.
    final onError = FlutterError.onError;
    FlutterError.onError = (d) {
      if (!d.exceptionAsString().contains('overflowed')) onError?.call(d);
    };
    addTearDown(() => FlutterError.onError = onError);
    tester.view.physicalSize = const Size(1600, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: sqliteRepositoryOverrides,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: ReportsScreen()),
      ),
    ));
    await settle(tester);
    await tester.tap(find.text('Tax').first);
    await settle(tester);

    // By rate first; the HSN table isn't built (or loaded) yet.
    expect(find.text('HSN summary'), findsOneWidget); // the sub-tab
    expect(find.text('1001'), findsNothing);

    await tester.tap(find.text('HSN summary'));
    await settle(tester);
    expect(find.text('1001'), findsOneWidget);
    expect(find.text('1025'), findsOneWidget);
    expect(find.text('1026'), findsNothing); // page 1 of 25 rows

    await tester.tap(find.widgetWithText(ChoiceChip, 'B2C'));
    await settle(tester);
    expect(find.text('9999'), findsOneWidget);
    expect(find.text('1001'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await tester.enterText(find.byType(TextField), '1030');
    await settle(tester);
    expect(find.text('1030'), findsNWidgets(2)); // search box + the row
    expect(find.text('1029'), findsNothing);
    expect(find.text('1001'), findsNothing);
  });
}
