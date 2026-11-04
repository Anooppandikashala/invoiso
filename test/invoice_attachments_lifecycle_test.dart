// Attachments + private notes through the invoice lifecycle, via the real
// create form: quotation → invoice convert copies them, clone and credit note
// start without, re-saving an edit doesn't duplicate them, trash / restore
// keeps them, permanent delete removes rows and files.
// Same ffi sqflite + path_provider harness as credit_note_form_test.dart.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:invoiso/database/customer_service.dart';
import 'package:invoiso/database/database_helper.dart';
import 'package:invoiso/database/invoice_attachment_service.dart';
import 'package:invoiso/database/invoice_service.dart';
import 'package:invoiso/database/product_service.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/models/customer.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/invoice_attachment.dart';
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
  late String photo;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tmp = Directory.systemTemp.createTempSync('invoiso_attach_life_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => tmp.path);
    await DatabaseHelper().switchToFile('attach_life_test.db');
    BackendServices.configure(
      settings: SqliteSettingsRepository(),
      companyInfo: SqliteCompanyInfoRepository(),
      invoices: SqliteInvoiceRepository(),
      payments: SqlitePaymentRepository(),
      installation: SqliteInstallationRepository(),
    );
    photo = join(tmp.path, 'picked.jpg');
    File(photo).writeAsBytesSync(img.encodeJpg(img.Image(width: 40, height: 30)));
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

  // Real DB / file I/O only advances inside runAsync, about one await per
  // pass — saving photos (copy + transaction) needs more passes than a
  // plain invoice save.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 80; i++) {
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

  /// Saves [id] with a public + a private photo and a private note.
  Future<Invoice> seed(String id, String type) async {
    await InvoiceService.insertInvoice(Invoice(
      id: id,
      invoiceNumber: id,
      customer: customer,
      items: [InvoiceItem(product: product, quantity: 1)],
      date: DateTime(2026, 11, 4),
      type: type,
      privateNotes: 'secret $id',
    ));
    await InvoiceService.updateInvoice(
        (await InvoiceService.getInvoiceById(id))!); // stamps derived fields
    await InvoiceAttachmentService.sync(id, [
      AttachmentDraft(path: photo, isPublic: true, caption: 'Before'),
      AttachmentDraft(path: photo, isPublic: false, caption: 'Receipt'),
    ]);
    return (await InvoiceService.getInvoiceById(id))!;
  }

  Future<Set<String>> invoiceIds() async =>
      (await InvoiceService.getAllInvoices()).map((i) => i.id).toSet();

  testWidgets('quotation → invoice copies photos and private notes',
      (tester) async {
    final quote = (await tester.runAsync(() async {
      await ProductService.insertProduct(product);
      await CustomerService.insertCustomer(customer);
      return seed('q1', 'Quotation');
    }))!;
    final before = (await tester.runAsync(invoiceIds))!;

    await openForm(
        tester,
        CreateInvoiceScreenV2(
            cloneFrom: quote, cloneType: 'Invoice', convertFromQuotationId: 'q1'));
    expect(find.text('1 customer · 1 private'), findsOneWidget);
    await tapAndSettle(tester, Icons.save_outlined);

    await tester.runAsync(() async {
      final newId = (await invoiceIds()).difference(before).single;
      final inv = (await InvoiceService.getInvoiceById(newId))!;
      expect(inv.privateNotes, 'secret q1');
      final copies = await InvoiceAttachmentService.listFor(newId);
      expect(copies.map((a) => [a.isPublic, a.caption]), [
        [true, 'Before'],
        [false, 'Receipt'],
      ]);
      for (final a in copies) {
        expect(File(InvoiceAttachmentService.filePath(a)).existsSync(), isTrue);
      }
      // The quotation keeps its own files.
      expect((await InvoiceAttachmentService.listFor('q1')).length, 2);
    });
  });

  testWidgets('clone and credit note start without photos or private notes',
      (tester) async {
    final inv = (await tester.runAsync(() => seed('i1', 'Invoice')))!;

    for (final type in ['Invoice', 'Credit Note']) {
      final before = (await tester.runAsync(invoiceIds))!;
      // New key per run, or Flutter reuses the last (already saved) form.
      await openForm(tester,
          CreateInvoiceScreenV2(key: ValueKey(type), cloneFrom: inv, cloneType: type));
      expect(find.text('No photos'), findsOneWidget, reason: type);
      await tapAndSettle(tester, Icons.save_outlined);

      await tester.runAsync(() async {
        final newId = (await invoiceIds()).difference(before).single;
        expect((await InvoiceService.getInvoiceById(newId))!.privateNotes,
            isNull, reason: type);
        expect(await InvoiceAttachmentService.listFor(newId), isEmpty,
            reason: type);
      });
    }
  });

  testWidgets('editing and re-saving keeps photos without duplicating them',
      (tester) async {
    final inv = (await tester.runAsync(() => seed('i2', 'Invoice')))!;
    final ids = (await tester.runAsync(() async =>
        (await InvoiceAttachmentService.listFor('i2')).map((a) => a.id).toList()))!;

    await openForm(tester, CreateInvoiceScreenV2(invoiceToEdit: inv));
    expect(find.text('1 customer · 1 private'), findsOneWidget);
    await tapAndSettle(tester, Icons.update);

    await tester.runAsync(() async {
      final after = await InvoiceAttachmentService.listFor('i2');
      expect(after.map((a) => a.id), ids);
      expect((await InvoiceService.getInvoiceById('i2'))!.privateNotes, 'secret i2');
    });
  });

  testWidgets('trash and restore keep photos; permanent delete removes them',
      (tester) async {
    await tester.runAsync(() async {
      await seed('i3', 'Invoice');
      final dir = Directory(InvoiceAttachmentService.invoiceDir('i3'));

      await InvoiceService.softDeleteInvoice('i3');
      await InvoiceService.restoreInvoice('i3');
      expect((await InvoiceAttachmentService.listFor('i3')).length, 2);
      expect(dir.existsSync(), isTrue);

      await InvoiceService.softDeleteInvoice('i3');
      await InvoiceService.permanentDeleteInvoice('i3');
      expect(await InvoiceAttachmentService.listFor('i3'), isEmpty);
      expect(dir.existsSync(), isFalse);
    });
  });
}
