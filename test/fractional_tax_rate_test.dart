// Fractional tax rates (8.5%, 10.25%): display formatting, input pattern,
// legacy integer DB values, and per-item / global tax maths + PDF label.
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/database/database_helper.dart';
import 'package:invoiso/database/invoice_service.dart';
import 'package:invoiso/database/product_service.dart';
import 'package:invoiso/models/customer.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/invoice_item.dart';
import 'package:invoiso/models/product.dart';
import 'package:invoiso/services/pdf/pdf_widgets.dart';
import 'package:invoiso/utils/formatters.dart';

Product _product(double taxRate, {bool priceIncludesTax = false}) => Product(
      id: 'p1',
      name: 'Item',
      description: '',
      price: 100,
      stock: 10,
      hsncode: '',
      tax_rate: taxRate,
      priceIncludesTax: priceIncludesTax,
    );

Invoice _invoice(List<InvoiceItem> items,
        {TaxMode taxMode = TaxMode.perItem, double taxRate = 0}) =>
    Invoice(
      id: 'inv1',
      customer: Customer(
          id: 'c1', name: 'C', email: '', phone: '', address: '', gstin: ''),
      items: items,
      date: DateTime(2026, 11, 4),
      type: 'Invoice',
      taxMode: taxMode,
      taxRate: taxRate,
    );

void main() {
  test('formatTaxRate trims trailing zeros, max 2 decimals', () {
    expect(AppFormatters.formatTaxRate(18), '18');
    expect(AppFormatters.formatTaxRate(18.0), '18');
    expect(AppFormatters.formatTaxRate(0), '0');
    expect(AppFormatters.formatTaxRate(8.5), '8.5');
    expect(AppFormatters.formatTaxRate(10.25), '10.25');
    expect(AppFormatters.formatTaxRate(4.25), '4.25');
    expect(AppFormatters.formatTaxRate(100), '100');
    // Float noise from taxRate * 100 (0.1025 * 100 = 10.250000000000002).
    expect(AppFormatters.formatTaxRate(0.1025 * 100), '10.25');
  });

  test('tax rate input pattern allows up to 2 decimals', () {
    final p = AppFormatters.taxRateInputPattern;
    for (final ok in ['', '8', '18', '100', '8.', '8.5', '10.25', '.5']) {
      expect(p.hasMatch(ok), isTrue, reason: ok);
    }
    for (final bad in ['10.255', '1000', '8.5.1', 'abc', '-5']) {
      expect(p.hasMatch(bad), isFalse, reason: bad);
    }
  });

  test('Product reads legacy integer and fractional tax rates', () {
    expect(Product.fromMap({'tax_rate': 18}).tax_rate, 18.0);
    expect(Product.fromMap({'tax_rate': 8.5}).tax_rate, 8.5);
    expect(Product.fromMap({}).tax_rate, 0.0);
    expect(Product.fromInvoiceItemsMap({'product_tax_rate': 12}).tax_rate, 12.0);
    expect(
        Product.fromInvoiceItemsMap({'product_tax_rate': 10.25}).tax_rate, 10.25);
    expect(_product(8.5).toMap()['tax_rate'], 8.5);
  });

  test('per-item 8.5% tax, exclusive and inclusive', () {
    final exclusive = InvoiceItem(product: _product(8.5), quantity: 2);
    expect(exclusive.taxAmount, closeTo(17.0, 1e-9));

    final inclusive = InvoiceItem(
        product: _product(8.5, priceIncludesTax: true), quantity: 1);
    expect(inclusive.taxAmount, closeTo(100 - 100 / 1.085, 1e-6));

    final inv = _invoice([exclusive]);
    expect(inv.tax, closeTo(17.0, 1e-9));
    expect(inv.total, closeTo(217.0, 1e-9));
  });

  test('global 8.5% tax total and PDF label', () {
    final inv = _invoice(
        [InvoiceItem(product: _product(0), quantity: 2)],
        taxMode: TaxMode.global,
        taxRate: 0.085);
    expect(inv.tax, closeTo(17.0, 1e-9));
    expect(invoiceTaxLabel(inv), 'Tax (8.5%)');
    expect(
        invoiceTaxLabel(_invoice([], taxMode: TaxMode.global, taxRate: 0.18)),
        'Tax (18%)');
  });

  group('SQLite INTEGER columns keep fractional rates', () {
    late Database db;
    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
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

    test('product and invoice item round-trip 10.25%', () async {
      final product = _product(10.25);
      await ProductService.insertProduct(product);
      expect((await ProductService.getProductById('p1'))!.tax_rate, 10.25);

      await InvoiceService.insertInvoice(
          _invoice([InvoiceItem(product: product, quantity: 1)]));
      final saved = (await InvoiceService.getInvoiceById('inv1'))!;
      expect(saved.items.single.product.tax_rate, 10.25);
      expect(saved.tax, closeTo(10.25, 1e-9));
    });

    test('legacy integer rate still reads as double', () async {
      await ProductService.insertProduct(_product(18));
      final row = (await db.query('products', where: "id = 'p1'")).single;
      expect(row['tax_rate'], isA<int>()); // SQLite stores 18.0 as 18
      expect((await ProductService.getProductById('p1'))!.tax_rate, 18.0);
    });
  });
}
