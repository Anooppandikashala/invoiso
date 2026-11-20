// GSTR-3B summary (PurchaseGstReportsPlan.md P5): 3.1 / 3.2 / 4 / 5 from the
// GSTR-1 and purchase builders, and the 6.1 ITC set-off order. Pure.
import 'package:flutter_test/flutter_test.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/models/customer.dart';
import 'package:invoiso/models/gstr3b_summary.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/invoice_item.dart';
import 'package:invoiso/models/product.dart';
import 'package:invoiso/models/purchase_bill.dart';
import 'package:invoiso/models/purchase_bill_item.dart';
import 'package:invoiso/services/gst/gstr1_builder.dart';
import 'package:invoiso/services/gst/gstr3b_builder.dart';
import 'package:invoiso/services/gst/purchase_gst_builder.dart';

const _company = '33ABCDE1234F1Z5'; // Tamil Nadu

Invoice _sale(String id, double price, double rate,
        {String gstin = '', String pos = '33', bool inter = false,
        String type = 'Invoice'}) =>
    Invoice(
      id: id,
      invoiceNumber: id,
      customer: Customer(
          id: 'c$id', name: 'C$id', email: '', phone: '', address: '', gstin: gstin),
      items: [
        InvoiceItem(
            product: Product(
                id: 'p$id', name: 'Item', description: '', price: price,
                stock: 0, hsncode: '8471', tax_rate: rate),
            quantity: 1)
      ],
      date: DateTime(2026, 11, 5),
      type: type,
      taxMode: TaxMode.perItem,
      isInterState: inter,
      placeOfSupply: pos,
    );

PurchaseBill _buy(String id, double cost, double rate,
        {String gstin = '', bool rcm = false}) =>
    PurchaseBill(
      id: id,
      billDate: DateTime(2026, 11, 6),
      items: [
        PurchaseBillItem(
            productName: 'X', quantity: 1, costPerUnit: cost, taxRate: rate)
      ],
      supplierGstin: gstin,
      reverseCharge: rcm,
    );

Gstr3bSummary _build(List<Invoice> sales, List<PurchaseBill> buys) =>
    Gstr3bBuilder.build(
      companyGstin: _company,
      sales: Gstr1Builder.build(Gstr1Input(
          companyGstin: _company, documents: sales, numberOf: (i) => i.id)),
      purchases: PurchaseGstBuilder.build(companyGstin: _company, bills: buys),
    );

void main() {
  test('3.1 / 3.2 / 4 / 5 and 6.1 with reverse charge paid in cash', () {
    final s = _build([
      _sale('1', 1000, 18, gstin: '33PQRST6789L1ZQ'), // CGST 90 + SGST 90
      _sale('2', 500, 18, pos: '29', inter: true), // B2C inter: IGST 90
      _sale('3', 100, 18, gstin: '33PQRST6789L1ZQ', type: 'Credit Note'), // −9 / −9
      _sale('4', 200, 0), // nil rated
    ], [
      _buy('a', 800, 5, gstin: '29ABCDE1234F1Z5'), // ITC IGST 40
      _buy('b', 500, 12, gstin: '33PQRST6789L1ZQ'), // ITC CGST 30 + SGST 30
      _buy('c', 1000, 5, rcm: true), // RCM: CGST 25 + SGST 25
      _buy('d', 300, 0, gstin: '33PQRST6789L1ZQ'), // exempt inward, intra
    ]);

    expect(s.outwardTaxable.taxable, 1400);
    expect([s.outwardTaxable.tax.igst, s.outwardTaxable.tax.cgst], [90, 81]);
    expect(s.outwardNilExempt, 200);
    expect(s.inwardReverseCharge.taxable, 1000);
    expect(s.inwardReverseCharge.tax.cgst, 25);
    expect(s.interStateUnregistered.single.pos, '29');
    expect(s.interStateUnregistered.single.igst, 90);

    expect([s.itcOther.igst, s.itcOther.cgst], [40, 30]);
    expect(s.itcReverseCharge.cgst, 25);
    expect([s.itcNet.igst, s.itcNet.cgst], [40, 55]);
    expect(s.inwardExemptIntra, 300);

    // IGST: 90 due, 40 ITC → 50 cash.
    expect([s.igst.payable, s.igst.paidByItc, s.igst.paidInCash], [90, 40, 50]);
    // CGST: 81 outward + 25 RCM; ITC 55 covers outward only → 26 + 25 cash.
    expect([s.cgst.payable, s.cgst.paidByItc, s.cgst.paidInCash], [106, 55, 51]);
    expect([s.sgst.payable, s.sgst.paidInCash], [106, 51]);
  });

  test('IGST credit is used first across heads; leftover carried forward', () {
    final s = _build([
      _sale('1', 1000, 5, gstin: '29ABCDE1234F1Z5', pos: '29', inter: true), // IGST 50
      _sale('2', 500, 12, gstin: '33PQRST6789L1ZQ'), // CGST 30 + SGST 30
    ], [
      _buy('a', 4000, 5, gstin: '29ABCDE1234F1Z5'), // ITC IGST 200
    ]);
    expect([s.igst.paidByItc, s.cgst.paidByItc, s.sgst.paidByItc], [50, 30, 30]);
    expect([s.igst.paidInCash, s.cgst.paidInCash, s.sgst.paidInCash], [0, 0, 0]);
    expect(s.igst.itcLeft, 90);
  });
}
