// GSTR-1 builder (Gstr1ExportPlan.md Part C): rate split, place of supply,
// b2b / b2cl / b2cs classification, exclusions. Pure — no database.
import 'package:flutter_test/flutter_test.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/models/additional_cost.dart';
import 'package:invoiso/models/customer.dart';
import 'package:invoiso/models/gstr1_report.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/invoice_item.dart';
import 'package:invoiso/models/product.dart';
import 'package:invoiso/services/gst/gstr1_builder.dart';

const _company = '33ABCDE1234F1Z5'; // Tamil Nadu

Product _p(double price, double rate, {bool incl = false}) => Product(
    id: 'p$price-$rate',
    name: 'Item $rate',
    description: '',
    price: price,
    stock: 0,
    hsncode: '8471',
    tax_rate: rate,
    priceIncludesTax: incl);

Invoice _inv(
  String id, {
  String gstin = '',
  required List<InvoiceItem> items,
  TaxMode mode = TaxMode.perItem,
  double globalRate = 0,
  bool inter = false,
  String? pos,
  String currency = 'INR',
  List<AdditionalCost> charges = const [],
  String type = 'Invoice',
  String? original,
}) =>
    Invoice(
      id: id,
      invoiceNumber: id,
      customer: Customer(
          id: 'c$id', name: 'Cust $id', email: '', phone: '', address: '', gstin: gstin),
      items: items,
      date: DateTime(2026, 11, 5),
      type: type,
      originalInvoiceId: original,
      taxMode: mode,
      taxRate: globalRate,
      isInterState: inter,
      placeOfSupply: pos,
      currencyCode: currency,
      additionalCosts: charges,
    );

Gstr1Report _build(List<Invoice> docs, {List<Invoice> originals = const []}) =>
    Gstr1Builder.build(Gstr1Input(
        companyGstin: _company,
        documents: docs,
        numberOf: (i) => 'INV-${i.id}',
        originals: {for (final o in originals) o.id: o}));

void main() {
  test('rate split: per-item rates, tax-inclusive line, line discount', () {
    final inv = _inv('1', items: [
      InvoiceItem(product: _p(118, 18, incl: true), quantity: 2), // 200 + 36
      InvoiceItem(product: _p(100, 5), quantity: 3, discount: 50), // 250 + 12.5
    ]);
    final split = Gstr1Builder.rateSplit(inv);
    expect(split[18]!.taxable, closeTo(200, 1e-9));
    expect(split[18]!.tax, closeTo(36, 1e-9));
    expect(split[5]!.taxable, closeTo(250, 1e-9));
    expect(split[5]!.tax, closeTo(12.5, 1e-9));
  });

  test('rate split: global rate includes taxable charges, not untaxed ones', () {
    final inv = _inv('1',
        mode: TaxMode.global,
        globalRate: 0.18,
        items: [InvoiceItem(product: _p(1000, 0), quantity: 1)],
        charges: const [
          AdditionalCost(label: 'Freight', amount: 100, taxable: true),
          AdditionalCost(label: 'Courier', amount: 50),
        ]);
    final s = Gstr1Builder.rateSplit(inv)[18]!;
    expect(s.taxable, closeTo(1100, 1e-9));
    expect(s.tax, closeTo(198, 1e-9));
  });

  test('b2b: one row per rate, document fields repeated, CGST/SGST halves', () {
    final r = _build([
      _inv('1', gstin: '33PQRST6789L1ZQ', pos: '33', items: [
        InvoiceItem(product: _p(100, 18), quantity: 1),
        InvoiceItem(product: _p(100, 5), quantity: 2),
      ]),
    ]);
    expect(r.b2b, hasLength(2));
    final at18 = r.b2b.firstWhere((x) => x.rate == 18);
    expect([at18.number, at18.gstin, at18.pos], ['INV-1', '33PQRST6789L1ZQ', '33']);
    expect(at18.value, 328); // 118 + 210
    expect([at18.taxable, at18.cgst, at18.sgst, at18.igst], [100, 9, 9, 0]);
    expect(r.b2cl, isEmpty);
    expect(r.b2cs, isEmpty);
  });

  test('b2cl over ₹1 lakh inter-state; at or below the limit → b2cs', () {
    final big = _inv('1', pos: '29', inter: true,
        items: [InvoiceItem(product: _p(100000, 18), quantity: 1)]); // 118000
    final small = _inv('2', pos: '29', inter: true,
        items: [InvoiceItem(product: _p(50000, 18), quantity: 1)]);
    final r = _build([big, small]);
    expect(r.b2cl.single.invoiceId, '1');
    expect(r.b2cl.single.igst, 18000);
    expect(r.b2cs.single.pos, '29');
    expect([r.b2cs.single.taxable, r.b2cs.single.igst], [50000, 9000]);
  });

  test('b2cs sums invoices by place of supply × rate; intra-state stays b2cs', () {
    final r = _build([
      _inv('1', pos: '33', items: [InvoiceItem(product: _p(100000, 18), quantity: 2)]),
      _inv('2', pos: '33', items: [InvoiceItem(product: _p(100, 18), quantity: 1)]),
    ]);
    expect(r.b2cl, isEmpty); // big but same state
    expect(r.b2cs.single.taxable, 200100);
    expect([r.b2cs.single.cgst, r.b2cs.single.sgst], [18009, 18009]);
  });

  test('old invoices: place of supply from GSTIN, else company state, else excluded',
      () {
    final r = _build([
      _inv('1', gstin: '29ABCDE1234F1Z5', inter: true,
          items: [InvoiceItem(product: _p(100, 18), quantity: 1)]),
      _inv('2', items: [InvoiceItem(product: _p(100, 18), quantity: 1)]),
      _inv('3', inter: true, items: [InvoiceItem(product: _p(100, 18), quantity: 1)]),
    ]);
    expect(r.b2b.single.pos, '29');
    expect(r.b2cs.single.pos, '33');
    expect(r.excluded.single.kind, Gstr1IssueKind.missingPlaceOfSupply);
    expect(r.excluded.single.number, 'INV-3');
  });

  test('non-INR excluded; 0 % lines left out of rate sections',
      () {
    final r = _build([
      _inv('1', currency: 'USD', items: [InvoiceItem(product: _p(100, 18), quantity: 1)]),
      _inv('2', gstin: '33PQRST6789L1ZQ', pos: '33', items: [
        InvoiceItem(product: _p(100, 18), quantity: 1),
        InvoiceItem(product: _p(40, 0), quantity: 1),
      ]),
    ]);
    expect(r.excluded.single.kind, Gstr1IssueKind.nonInr);
    expect(r.b2b.single.rate, 18);
    expect(r.b2b.single.value, 158); // invoice value still includes the 0 % line
  });

  group('credit / debit notes', () {
    test('registered notes → cdnr per rate, type C / D, positive values', () {
      final r = _build([
        _inv('cn1', type: 'Credit Note', gstin: '29ABCDE1234F1Z5', pos: '29',
            inter: true, items: [InvoiceItem(product: _p(100, 18), quantity: 3)]),
        _inv('dn1', type: 'Debit Note', gstin: '33PQRST6789L1ZQ', pos: '33',
            items: [InvoiceItem(product: _p(50, 5), quantity: 1)]),
      ]);
      expect(r.b2b, isEmpty);
      final cn = r.cdnr.firstWhere((x) => x.invoiceId == 'cn1');
      expect([cn.noteType, cn.value, cn.taxable, cn.igst], ['C', 354, 300, 54]);
      final dn = r.cdnr.firstWhere((x) => x.invoiceId == 'dn1');
      expect([dn.noteType, dn.cgst, dn.sgst], ['D', 1.25, 1.25]);
    });

    test('unregistered note against a B2C Large invoice → cdnur', () {
      final big = _inv('i1', pos: '29', inter: true,
          items: [InvoiceItem(product: _p(100000, 18), quantity: 1)]);
      final r = _build([
        _inv('cn1', type: 'Credit Note', pos: '29', inter: true, original: 'i1',
            items: [InvoiceItem(product: _p(10000, 18), quantity: 1)]),
      ], originals: [big]);
      expect(r.cdnur.single.noteType, 'C');
      expect([r.cdnur.single.taxable, r.cdnur.single.igst], [10000, 1800]);
      expect(r.b2cs, isEmpty);
    });

    test('other unregistered notes net into b2cs (credit −, debit +)', () {
      final inv = _inv('i1', pos: '33',
          items: [InvoiceItem(product: _p(100, 18), quantity: 10)]);
      final r = _build([
        inv,
        _inv('cn1', type: 'Credit Note', pos: '33', original: 'i1',
            items: [InvoiceItem(product: _p(100, 18), quantity: 3)]),
        _inv('dn1', type: 'Debit Note', pos: '33',
            items: [InvoiceItem(product: _p(100, 18), quantity: 1)]),
      ], originals: [inv]);
      expect(r.cdnr, isEmpty);
      expect(r.cdnur, isEmpty);
      expect([r.b2cs.single.taxable, r.b2cs.single.cgst], [800, 72]);
    });

    test('old note without place of supply takes it from the original', () {
      final orig = _inv('i1', pos: '29', inter: true,
          items: [InvoiceItem(product: _p(100, 18), quantity: 1)]);
      final r = _build([
        _inv('cn1', type: 'Credit Note', inter: true, original: 'i1',
            items: [InvoiceItem(product: _p(100, 18), quantity: 1)]),
      ], originals: [orig]);
      expect(r.excluded, isEmpty);
      expect([r.b2cs.single.pos, r.b2cs.single.taxable], ['29', -100]);
    });
  });
}
