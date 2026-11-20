// GSTR-1 loader against SQLite: period range, printed numbers, originals of
// notes from an earlier month, company GSTIN and documents issued.
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/database/company_info_service.dart';
import 'package:invoiso/database/database_helper.dart';
import 'package:invoiso/database/invoice_service.dart';
import 'package:invoiso/database/product_service.dart';
import 'package:invoiso/models/company_info.dart';
import 'package:invoiso/models/customer.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/invoice_item.dart';
import 'package:invoiso/models/product.dart';
import 'package:invoiso/repositories/sqlite/sqlite_company_info_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_company_registry_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_installation_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_invoice_attachment_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_payment_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_return_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_invoice_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_report_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_settings_repository.dart';
import 'package:invoiso/services/backend_services.dart';
import 'package:invoiso/services/gst/gstr1_service.dart';

final _product = Product(
    id: 'p1', name: 'Mouse', description: '', price: 100000, stock: 0,
    hsncode: '8471', tax_rate: 18, unlimitedStock: true);

Invoice _inv(String id, String number, DateTime date,
        {String gstin = '', String? pos, bool inter = false,
        String type = 'Invoice', String? original, String? status}) =>
    Invoice(
      id: id,
      invoiceNumber: number,
      customer: Customer(
          id: 'c$id', name: 'C$id', email: '', phone: '', address: '', gstin: gstin),
      items: [InvoiceItem(product: _product, quantity: 1)],
      date: date,
      type: type,
      taxMode: TaxMode.perItem,
      isInterState: inter,
      placeOfSupply: pos,
      originalInvoiceId: original,
      status: status,
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
      companyRegistry: SqliteCompanyRegistryRepository(),
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
    await db.delete('company_info');
    await CompanyInfoService.insertCompanyInfo(CompanyInfo(
        name: 'Co', address: '', phone: '', email: '', website: '',
        gstin: '33ABCDE1234F1Z5'));
    await ProductService.insertProduct(_product);
  });
  tearDown(() async {
    DatabaseHelper.setTestDatabase(null);
    await db.close();
  });

  test('quarter and month periods', () {
    final q = Gstr1Period.quarter(2026, 4);
    expect([q.from, q.to], [DateTime(2026, 10), DateTime(2026, 12, 31)]);
    final m = Gstr1Period.month(2026, 2);
    expect(m.to, DateTime(2026, 2, 28));
  });

  test('loads the month: numbers, earlier originals, declined skipped, docs',
      () async {
    // October: B2C Large invoice (inter-state, > 1 lakh) — outside the period.
    await InvoiceService.insertInvoice(_inv(
        'i0', '00000001', DateTime(2026, 10, 20), pos: '29', inter: true));
    // November.
    await InvoiceService.insertInvoice(_inv('i1', '00000002', DateTime(2026, 11, 3),
        gstin: '33PQRST6789L1ZQ', pos: '33'));
    await InvoiceService.insertInvoice(_inv('i2', '00000003', DateTime(2026, 11, 4),
        pos: '33', status: 'declined'));
    await InvoiceService.insertInvoice(_inv('cn1', '00000001', DateTime(2026, 11, 5),
        type: 'Credit Note', pos: '29', inter: true, original: 'i0'));

    final r = await Gstr1Service.load(Gstr1Period.month(2026, 11),
        invoices: SqliteInvoiceRepository(),
        reports: SqliteReportRepository(),
        companyInfo: SqliteCompanyInfoRepository());

    expect(r.companyGstinValid, isTrue);
    expect(r.b2b.single.number, 'INV-00000002');
    expect(r.b2cl, isEmpty); // October invoice not in this period
    expect(r.cdnur.single.number, 'CN-00000001'); // original found in October
    expect(r.b2cs, isEmpty); // declined invoice skipped
    expect(r.docs.map((d) => d.type), containsAll(['Invoice', 'Credit Note']));
  });
}
