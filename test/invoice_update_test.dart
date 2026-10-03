// Editing an invoice must persist every field the edit form can change.
// Real InvoiceService against an ffi sqflite file in a temp dir (path_provider
// channel mocked), same harness as invoice_status_test.dart.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/database/database_helper.dart';
import 'package:invoiso/database/invoice_service.dart';
import 'package:invoiso/database/payment_service.dart';
import 'package:invoiso/database/product_service.dart';
import 'package:invoiso/database/settings_service.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/models/additional_cost.dart';
import 'package:invoiso/models/custom_field_value.dart';
import 'package:invoiso/models/customer.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/invoice_item.dart';
import 'package:invoiso/models/product.dart';
import 'package:invoiso/providers/sqlite_repository_overrides.dart';
import 'package:invoiso/screens/create_invoice_screen_v2.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tmp = Directory.systemTemp.createTempSync('invoiso_update_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => tmp.path);
    await DatabaseHelper().switchToFile('update_test.db');
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

  Customer customer(String id, String name) => Customer(
        id: id,
        name: name,
        email: '',
        phone: '',
        address: '',
        gstin: '',
      );

  test('updateInvoice persists every editable field', () async {
    await ProductService.insertProduct(product);
    await InvoiceService.insertInvoice(Invoice(
      id: 'i1',
      customer: customer('c1', 'Old Customer'),
      items: [InvoiceItem(product: product, quantity: 1)],
      date: DateTime(2026, 1, 1, 9, 30),
      type: 'Invoice',
      bankAccountId: 'ACC-OLD',
      upiId: 'old@upi',
    ));

    await InvoiceService.updateInvoice(Invoice(
      id: 'i1',
      customer: customer('c2', 'New Customer'),
      items: [InvoiceItem(product: product, quantity: 2)],
      date: DateTime(2026, 3, 5, 14, 45),
      dueDate: DateTime(2026, 4, 5),
      type: 'Invoice',
      notes: 'new notes',
      taxRate: 0.18,
      taxMode: TaxMode.global,
      isInterState: true,
      invoiceTitle: 'Tax Invoice',
      upiId: 'new@upi',
      bankAccountId: 'ACC-NEW',
      quantityLabel: 'Hours',
      additionalCosts: const [AdditionalCost(label: 'Shipping', amount: 50)],
      invoiceDiscountType: InvoiceDiscountType.amount,
      invoiceDiscountValue: 10,
      hideInvoiceNumber: true,
      customInvoiceNumber: 'CUST-1',
      customFields: const [
        CustomFieldValue(defId: 'd1', label: 'Vehicle No', value: 'KL-01')
      ],
    ));

    final r = (await InvoiceService.getInvoiceById('i1'))!;
    expect(r.date, DateTime(2026, 3, 5, 14, 45));
    expect(r.dueDate, DateTime(2026, 4, 5));
    expect(r.bankAccountId, 'ACC-NEW');
    expect(r.customer.id, 'c2');
    expect(r.customer.name, 'New Customer');
    expect(r.items.single.quantity, 2);
    expect(r.notes, 'new notes');
    expect(r.taxRate, 0.18);
    expect(r.taxMode, TaxMode.global);
    expect(r.isInterState, isTrue);
    expect(r.invoiceTitle, 'Tax Invoice');
    expect(r.upiId, 'new@upi');
    expect(r.quantityLabel, 'Hours');
    expect(r.additionalCosts.single.amount, 50);
    expect(r.invoiceDiscountType, InvoiceDiscountType.amount);
    expect(r.invoiceDiscountValue, 10);
    expect(r.hideInvoiceNumber, isTrue);
    expect(r.customInvoiceNumber, 'CUST-1');
    expect(r.customFields.single.value, 'KL-01');
  });

  test('updateInvoice can clear the bank account', () async {
    final before = (await InvoiceService.getInvoiceById('i1'))!;
    before.bankAccountId = null;
    await InvoiceService.updateInvoice(before);
    expect((await InvoiceService.getInvoiceById('i1'))!.bankAccountId, isNull);
  });

  // Invoice [id] with [qty] × 100 on its own product, optionally [paid].
  Future<Invoice> seed(String id, {double qty = 3, double paid = 0}) async {
    final p = Product(
      id: 'p-$id',
      name: 'Widget $id',
      description: '',
      price: 100,
      stock: 10,
      hsncode: '',
      tax_rate: 0,
    );
    await ProductService.insertProduct(p);
    await InvoiceService.insertInvoice(Invoice(
      id: id,
      customer: customer('c1', 'Customer'),
      items: [InvoiceItem(product: p, quantity: qty)],
      date: DateTime(2026, 1, 10, 9, 30),
      type: 'Invoice',
    ));
    if (paid > 0) {
      await PaymentService.addPayment(
        invoice: (await InvoiceService.getInvoiceById(id))!,
        amountPaid: paid,
        datePaid: DateTime(2026, 1, 10),
      );
    }
    return (await InvoiceService.getInvoiceById(id))!;
  }

  test('updateInvoice refuses a total below the amount paid', () async {
    final inv = await seed('u1', paid: 300);
    inv.items = [InvoiceItem(product: inv.items.single.product, quantity: 1)];
    await expectLater(InvoiceService.updateInvoice(inv), throwsStateError);
    expect((await InvoiceService.getInvoiceById('u1'))!.items.single.quantity, 3);

    // Exactly the paid amount is fine.
    inv.items = [InvoiceItem(product: inv.items.single.product, quantity: 3)];
    await InvoiceService.updateInvoice(inv);
  });

  // DB work is real I/O — let it finish outside the fake clock.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
    }
  }

  Future<void> pumpEditScreen(WidgetTester tester, Invoice invoice) async {
    tester.view.physicalSize = const Size(1800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: sqliteRepositoryOverrides,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: CreateInvoiceScreenV2(invoiceToEdit: invoice)),
      ),
    ));
    await settle(tester);
  }

  testWidgets('edit screen: new date is saved and keeps the old time',
      (tester) async {
    final inv = (await tester.runAsync(() => seed('w1')))!;
    await pumpEditScreen(tester, inv);

    await tester.tap(find.widgetWithText(TextField, 'Order date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('20'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await settle(tester);

    await tester.tap(find.byIcon(Icons.update));
    await tester.pump();
    await settle(tester);

    await tester.runAsync(() async {
      expect((await InvoiceService.getInvoiceById('w1'))!.date,
          DateTime(2026, 1, 20, 9, 30));
    });
  });

  testWidgets('edit screen: save blocked when total drops below paid',
      (tester) async {
    final inv = (await tester.runAsync(() => seed('w2', paid: 300)))!;
    // Open the editor with the quantity already lowered to 1 (total 100).
    inv.items = [InvoiceItem(product: inv.items.single.product, quantity: 1)];
    await pumpEditScreen(tester, inv);

    await tester.tap(find.byIcon(Icons.update));
    await tester.pump();
    await settle(tester);

    expect(find.textContaining('already paid'), findsOneWidget);
    await tester.runAsync(() async {
      expect((await InvoiceService.getInvoiceById('w2'))!.items.single.quantity,
          3);
    });
  });

  testWidgets('edit screen: Order time field picks and saves a new time',
      (tester) async {
    final inv = (await tester.runAsync(() async {
      await SettingsService.setShowTimeInPdf(true);
      return seed('t1');
    }))!;
    await pumpEditScreen(tester, inv);

    // Shows the invoice's current time (24h by default).
    final timeField = find.widgetWithText(TextFormField, 'Order time');
    expect(find.descendant(of: timeField, matching: find.text('09:30')),
        findsOneWidget);

    // Picker in keyboard-entry mode: hour 14, minute 45.
    await tester.tap(timeField);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    final pickerFields = find.descendant(
        of: find.byType(Dialog), matching: find.byType(TextField));
    await tester.enterText(pickerFields.at(0), '14');
    await tester.enterText(pickerFields.at(1), '45');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.descendant(of: timeField, matching: find.text('14:45')),
        findsOneWidget);

    await tester.tap(find.byIcon(Icons.update));
    await tester.pump();
    await settle(tester);
    await tester.runAsync(() async {
      expect((await InvoiceService.getInvoiceById('t1'))!.date,
          DateTime(2026, 1, 10, 14, 45));
    });
  });

  testWidgets('edit screen: Order time hidden when PDF time is off',
      (tester) async {
    final inv = (await tester.runAsync(() async {
      await SettingsService.setShowTimeInPdf(false);
      return seed('t2');
    }))!;
    await pumpEditScreen(tester, inv);
    expect(find.text('Order time'), findsNothing);
    expect(find.text('Order date'), findsOneWidget);
    await tester.runAsync(() => SettingsService.setShowTimeInPdf(true));
  });
}
