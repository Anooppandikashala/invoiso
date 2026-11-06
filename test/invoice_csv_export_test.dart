// Invoice CSV export column picker: default selection reproduces the old
// fixed CSV exactly; subsets, notes columns, and the saved choice.
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/database/database_helper.dart';
import 'package:invoiso/database/settings_service.dart';
import 'package:invoiso/models/customer.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/invoice_item.dart';
import 'package:invoiso/models/product.dart';
import 'package:invoiso/repositories/sqlite/sqlite_company_info_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_installation_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_invoice_attachment_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_return_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_invoice_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_payment_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_settings_repository.dart';
import 'package:invoiso/services/backend_services.dart';
import 'package:invoiso/services/export_service.dart';

Invoice _invoice() => Invoice(
      id: '7',
      customer: Customer(
          id: 'c1',
          name: 'Asha',
          email: '',
          phone: '98765',
          address: 'MG Road',
          gstin: '32ABC'),
      items: [
        InvoiceItem(
            product: Product(
                id: 'p1',
                name: 'Paint',
                description: '',
                price: 100,
                stock: 10,
                hsncode: '',
                tax_rate: 0),
            quantity: 2),
      ],
      date: DateTime(2026, 11, 4),
      dueDate: DateTime(2026, 11, 14),
      type: 'Invoice',
      notes: 'Thank you',
      privateNotes: 'Paid cash to painter',
      upiId: 'shop@upi',
    );

void main() {
  late Database db;
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    BackendServices.configure(
      settings: SqliteSettingsRepository(),
      companyInfo: SqliteCompanyInfoRepository(),
      invoices: SqliteInvoiceRepository(),
      payments: SqlitePaymentRepository(),
      installation: SqliteInstallationRepository(),
    attachments: SqliteInvoiceAttachmentRepository(),
    returns: SqliteReturnRepository(),
    );
  });
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

  test('default columns match the old fixed CSV', () async {
    final csv = await ExportService.buildInvoicesCsv([_invoice()]);
    expect(
        csv,
        '"Invoice ID","Date","Due Date","Customer","Phone","Address",'
        '"Customer GSTIN","Type","Status","Subtotal","Tax","Total",'
        '"Currency","UPI","Items"\n'
        '"7","04/11/2026","14/11/2026","Asha","98765","MG Road","32ABC",'
        '"Invoice","","200.00","0.00","200.00","INR","shop@upi",'
        '"Paint x2 @INR 100.00"');
  });

  test('GSTIN column dropped while GST fields are off', () async {
    await SettingsService.setSetting(SettingKey.showGstFields, 'false');
    final csv = await ExportService.buildInvoicesCsv([_invoice()]);
    expect(csv.split('\n').first, isNot(contains('GSTIN')));
    expect(csv, isNot(contains('32ABC')));
  });

  test('subset with notes and private notes', () async {
    final csv = await ExportService.buildInvoicesCsv([_invoice()],
        type: 'Quotation',
        columns: [
          InvoiceCsvColumn.id,
          InvoiceCsvColumn.total,
          InvoiceCsvColumn.notes,
          InvoiceCsvColumn.privateNotes,
        ]);
    expect(
        csv,
        '"Quotation ID","Total","Notes","Private Notes"\n'
        '"7","200.00","Thank you","Paid cash to painter"');
  });

  test('saved choice: round-trip, unknown names, bad JSON', () async {
    expect(await ExportService.loadCsvColumns(), InvoiceCsvColumn.defaults);

    await ExportService.saveCsvColumns(
        [InvoiceCsvColumn.id, InvoiceCsvColumn.privateNotes]);
    expect(await ExportService.loadCsvColumns(),
        [InvoiceCsvColumn.id, InvoiceCsvColumn.privateNotes]);

    await SettingsService.setSetting(
        SettingKey.invoiceCsvColumns, '["total","removedColumn"]');
    expect(await ExportService.loadCsvColumns(), [InvoiceCsvColumn.total]);

    await SettingsService.setSetting(SettingKey.invoiceCsvColumns, 'not json');
    expect(await ExportService.loadCsvColumns(), InvoiceCsvColumn.defaults);
  });

  test('private notes are not in the default selection', () {
    expect(InvoiceCsvColumn.defaults, isNot(contains(InvoiceCsvColumn.privateNotes)));
    expect(InvoiceCsvColumn.defaults, isNot(contains(InvoiceCsvColumn.notes)));
  });
}
