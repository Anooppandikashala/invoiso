// Invoice form: uploaded payment QR picker (source = 'image') pre-selects the
// default for a clone, keeps the saved QR on edit, and is hidden in UPI mode.
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
import 'package:invoiso/database/settings_service.dart';
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
import 'package:invoiso/screens/create_invoice_screen_v2.dart';
import 'package:invoiso/services/backend_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tmp = Directory.systemTemp.createTempSync('invoiso_payment_qr_form_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => tmp.path);
    await DatabaseHelper().switchToFile('payment_qr_form_test.db');
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

  Future<void> tapAndSettle(WidgetTester tester, IconData icon) async {
    await tester.tap(find.byIcon(icon));
    await tester.pump();
    await settle(tester);
  }

  Future<void> setSource(String source) async {
    await SettingsService.setSetting(SettingKey.paymentQrSource, source);
    await SettingsService.setSetting(
        SettingKey.paymentQrEntries,
        PaymentQrEntry.listToJson(const [
          PaymentQrEntry(id: 'q1', label: 'PayPal', imageBase64: 'AAA'),
          PaymentQrEntry(
              id: 'q2', label: 'Wise', imageBase64: 'BBB', isDefault: true),
        ]));
  }

  Future<Invoice> seed(String id, {String? paymentQrId}) async {
    await InvoiceService.insertInvoice(Invoice(
      id: id,
      invoiceNumber: id,
      customer: customer,
      items: [InvoiceItem(product: product, quantity: 1)],
      date: DateTime(2026, 11, 12),
      type: 'Invoice',
      paymentQrId: paymentQrId,
    ));
    return (await InvoiceService.getInvoiceById(id))!;
  }

  Future<Set<String>> invoiceIds() async =>
      (await InvoiceService.getAllInvoices()).map((i) => i.id).toSet();

  testWidgets('clone pre-selects the default QR and saves it', (tester) async {
    final inv = (await tester.runAsync(() async {
      await ProductService.insertProduct(product);
      await CustomerService.insertCustomer(customer);
      await setSource('image');
      return seed('i1');
    }))!;
    final before = (await tester.runAsync(invoiceIds))!;

    await openForm(
        tester, CreateInvoiceScreenV2(cloneFrom: inv, cloneType: 'Invoice'));
    expect(find.text('Payment QR'), findsOneWidget);
    expect(find.text('Wise'), findsOneWidget);
    await tapAndSettle(tester, Icons.save_outlined);

    await tester.runAsync(() async {
      final newId = (await invoiceIds()).difference(before).single;
      expect((await InvoiceService.getInvoiceById(newId))!.paymentQrId, 'q2');
    });
  });

  testWidgets('editing keeps the saved QR', (tester) async {
    final inv = (await tester.runAsync(() async {
      await setSource('image');
      return seed('i2', paymentQrId: 'q1');
    }))!;

    await openForm(tester, CreateInvoiceScreenV2(invoiceToEdit: inv));
    expect(find.text('PayPal'), findsOneWidget);
    await tapAndSettle(tester, Icons.update);

    await tester.runAsync(() async {
      expect((await InvoiceService.getInvoiceById('i2'))!.paymentQrId, 'q1');
    });
  });

  testWidgets('UPI mode hides the QR picker', (tester) async {
    final inv = (await tester.runAsync(() async {
      await setSource('upi');
      return seed('i3');
    }))!;

    await openForm(tester, CreateInvoiceScreenV2(invoiceToEdit: inv));
    expect(find.text('Payment QR'), findsNothing);
  });
}
