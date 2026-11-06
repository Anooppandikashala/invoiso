// InvoiceAttachmentService: compression, sync (add / edit / reorder /
// remove), public limit, counts, deleteAll, and per-company folders.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:invoiso/database/database_helper.dart';
import 'package:invoiso/database/invoice_attachment_service.dart';
import 'package:invoiso/models/customer.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/invoice_attachment.dart';
import 'package:invoiso/repositories/sqlite/sqlite_company_info_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_installation_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_invoice_attachment_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_company_registry_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_return_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_invoice_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_payment_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_settings_repository.dart';
import 'package:invoiso/services/backend_services.dart';
import 'package:invoiso/services/pdf/pdf_service.dart';

/// Smooth gradient JPEG — compresses like a photo, unlike random noise.
Uint8List _jpeg(int w, int h, {int? exifOrientation}) {
  final image = img.Image(width: w, height: h);
  for (final p in image) {
    p.setRgb(p.x * 255 ~/ w, p.y * 255 ~/ h, 128);
  }
  if (exifOrientation != null) {
    image.exif.imageIfd.orientation = exifOrientation;
  }
  return img.encodeJpg(image, quality: 95);
}

void main() {
  late Database db;
  late Directory tmp;

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

  Future<Database> openDb() => databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: DatabaseHelper().dbVersion,
          onCreate: (d, v) => DatabaseHelper().createDbForTest(d, v),
          singleInstance: false,
        ),
      );

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('attach_test');
    db = await openDb();
    DatabaseHelper.setTestDatabase(db);
    InvoiceAttachmentService.rootOverride = join(tmp.path, 'company_a');
  });

  tearDown(() async {
    InvoiceAttachmentService.rootOverride = null;
    DatabaseHelper.setTestDatabase(null);
    await db.close();
    await tmp.delete(recursive: true);
  });

  Future<String> picked(String name, {int w = 800, int h = 600}) async {
    final f = File(join(tmp.path, 'picked', name));
    await f.parent.create(recursive: true);
    await f.writeAsBytes(_jpeg(w, h));
    return f.path;
  }

  test('compress scales the long edge to 1600 and stays under 400 KB', () {
    final out = InvoiceAttachmentService.compress(_jpeg(4000, 3000));
    final decoded = img.decodeJpg(out)!;
    expect(decoded.width, 1600);
    expect(decoded.height, 1200);
    expect(out.length, lessThanOrEqualTo(InvoiceAttachmentService.maxBytes));
  });

  test('compress applies EXIF rotation (phone portrait photo)', () {
    final out = InvoiceAttachmentService.compress(
        _jpeg(400, 200, exifOrientation: 6));
    final decoded = img.decodeJpg(out)!;
    expect([decoded.width, decoded.height], [200, 400]);
  });

  test('compress rejects a non-image file', () {
    expect(() => InvoiceAttachmentService.compress(Uint8List.fromList([1, 2, 3])),
        throwsFormatException);
  });

  test('sync adds, edits, reorders and removes', () async {
    await InvoiceAttachmentService.sync('1', [
      AttachmentDraft(path: await picked('a.jpg'), isPublic: true, caption: ' Before '),
      AttachmentDraft(path: await picked('b.jpg'), isPublic: false),
    ]);
    var list = await InvoiceAttachmentService.listFor('1');
    expect(list.map((a) => [a.isPublic, a.caption, a.sortOrder]), [
      [true, 'Before', 0],
      [false, null, 1],
    ]);
    for (final a in list) {
      expect(File(InvoiceAttachmentService.filePath(a)).existsSync(), isTrue);
    }

    // Swap order, flip visibility, set caption, then drop the first.
    final drafts = await InvoiceAttachmentService.draftsFor('1');
    drafts[1]
      ..isPublic = true
      ..caption = 'Receipt';
    await InvoiceAttachmentService.sync('1', [drafts[1], drafts[0]]);
    list = await InvoiceAttachmentService.listFor('1');
    expect(list.map((a) => [a.id, a.isPublic, a.caption]), [
      [drafts[1].id, true, 'Receipt'],
      [drafts[0].id, true, 'Before'],
    ]);

    final removedPath = drafts[0].path;
    await InvoiceAttachmentService.sync('1', [drafts[1]]);
    expect((await InvoiceAttachmentService.listFor('1')).single.id, drafts[1].id);
    expect(File(removedPath).existsSync(), isFalse);
  });

  test('public limit: 11 customer photos are refused, nothing written', () async {
    final path = await picked('a.jpg', w: 50, h: 50);
    final drafts = [
      for (var i = 0; i <= InvoiceAttachmentService.publicLimit; i++)
        AttachmentDraft(path: path, isPublic: true),
    ];
    await expectLater(
        InvoiceAttachmentService.sync('1', drafts), throwsStateError);
    expect(await InvoiceAttachmentService.listFor('1'), isEmpty);
    expect(Directory(InvoiceAttachmentService.invoiceDir('1')).existsSync(),
        isFalse);
    // Private photos have no limit.
    await InvoiceAttachmentService.sync('1', [
      for (var i = 0; i < 15; i++) AttachmentDraft(path: path, isPublic: false),
    ]);
    expect((await InvoiceAttachmentService.listFor('1')).length, 15);
  });

  test('a stored file carried to another invoice is copied byte-for-byte',
      () async {
    await InvoiceAttachmentService.sync(
        'Q1', [AttachmentDraft(path: await picked('a.jpg'), isPublic: true)]);
    final quoteDraft = (await InvoiceAttachmentService.draftsFor('Q1')).single;
    // Quotation → invoice convert: same file, as a new draft.
    await InvoiceAttachmentService.sync(
        '2', [AttachmentDraft(path: quoteDraft.path, isPublic: true)]);
    final copy = (await InvoiceAttachmentService.draftsFor('2')).single;
    expect(copy.path, isNot(quoteDraft.path));
    expect(File(copy.path).readAsBytesSync(), File(quoteDraft.path).readAsBytesSync());
    expect(File(quoteDraft.path).existsSync(), isTrue); // quotation keeps its own
  });

  test('countsFor and deleteAll', () async {
    final path = await picked('a.jpg', w: 50, h: 50);
    await InvoiceAttachmentService.sync('1', [
      AttachmentDraft(path: path, isPublic: true),
      AttachmentDraft(path: path, isPublic: false),
      AttachmentDraft(path: path, isPublic: false),
    ]);
    await InvoiceAttachmentService.sync(
        '2', [AttachmentDraft(path: path, isPublic: true)]);
    final counts = await InvoiceAttachmentService.countsFor(['1', '2', '3']);
    expect(counts['1'], (public: 1, private: 2));
    expect(counts['2'], (public: 1, private: 0));
    expect(counts.containsKey('3'), isFalse);

    await InvoiceAttachmentService.deleteAll('1');
    expect(await InvoiceAttachmentService.listFor('1'), isEmpty);
    expect(Directory(InvoiceAttachmentService.invoiceDir('1')).existsSync(), isFalse);
    expect((await InvoiceAttachmentService.listFor('2')).length, 1);
  });

  test('two companies with the same invoice id keep separate photos', () async {
    final path = await picked('a.jpg', w: 50, h: 50);
    await InvoiceAttachmentService.sync(
        '1042', [AttachmentDraft(path: path, isPublic: true)]);
    final companyAFile =
        (await InvoiceAttachmentService.draftsFor('1042')).single.path;

    // Switch to company B: its own database and folder.
    final dbB = await openDb();
    DatabaseHelper.setTestDatabase(dbB);
    InvoiceAttachmentService.rootOverride = join(tmp.path, 'company_b');
    await InvoiceAttachmentService.sync(
        '1042', [AttachmentDraft(path: path, isPublic: false)]);
    await InvoiceAttachmentService.deleteAll('1042');
    await dbB.close();

    expect(File(companyAFile).existsSync(), isTrue);
    DatabaseHelper.setTestDatabase(db);
    InvoiceAttachmentService.rootOverride = join(tmp.path, 'company_a');
    expect((await InvoiceAttachmentService.listFor('1042')).single.isPublic, isTrue);
  });

  test('company folder is named after its database file', () {
    expect(
        InvoiceAttachmentService.companyDirFor('/data', 'invoice_manager.db'),
        join('/data', 'attachments', 'invoice_manager'));
    expect(
        InvoiceAttachmentService.companyDirFor(
            '/data', 'invoice_manager_6c1e.db'),
        join('/data', 'attachments', 'invoice_manager_6c1e'));
  });

  test('PDF loader takes customer photos only, in order, skipping missing files',
      () async {
    final path = await picked('a.jpg', w: 50, h: 50);
    await InvoiceAttachmentService.sync('1', [
      AttachmentDraft(path: path, isPublic: true, caption: 'first'),
      AttachmentDraft(path: path, isPublic: false, caption: 'secret'),
      AttachmentDraft(path: path, isPublic: true, caption: 'gone'),
      AttachmentDraft(path: path, isPublic: true, caption: 'third'),
    ]);
    final gone = (await InvoiceAttachmentService.listFor('1'))
        .firstWhere((a) => a.caption == 'gone');
    File(InvoiceAttachmentService.filePath(gone)).deleteSync();

    final invoice = Invoice(
      id: '1',
      customer: Customer(
          id: 'c', name: 'C', email: '', phone: '', address: '', gstin: ''),
      items: const [],
      date: DateTime(2026, 11, 4),
      type: 'Invoice',
    );
    await PDFService.attachPdfAttachments(invoice);
    expect(invoice.pdfAttachments.map((p) => p.caption), ['first', 'third']);
    expect(invoice.pdfAttachments.first.bytes, isNotEmpty);
  });
}
