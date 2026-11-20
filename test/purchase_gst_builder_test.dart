// Purchase GST builder (PurchaseGstReportsPlan.md P1): state rule, ITC
// eligibility, reverse charge, 0 % inward, drafts, warnings. Pure.
import 'package:flutter_test/flutter_test.dart';
import 'package:invoiso/models/purchase_bill.dart';
import 'package:invoiso/models/purchase_bill_item.dart';
import 'package:invoiso/models/purchase_gst_report.dart';
import 'package:invoiso/services/gst/purchase_gst_builder.dart';

const _company = '33ABCDE1234F1Z5'; // Tamil Nadu

PurchaseBill _bill(String id,
        {String gstin = '',
        bool rcm = false,
        bool draft = false,
        required List<PurchaseBillItem> items}) =>
    PurchaseBill(
      id: id,
      billNumber: 'PB-$id',
      supplierName: 'Supplier $id',
      billDate: DateTime(2026, 11, int.parse(id.replaceAll(RegExp(r'\D'), '1'))),
      items: items,
      supplierGstin: gstin,
      reverseCharge: rcm,
      isDraft: draft,
    );

PurchaseBillItem _item(double cost, double rate,
        {double qty = 1, bool incl = false}) =>
    PurchaseBillItem(
        productName: 'Item', quantity: qty, costPerUnit: cost, taxRate: rate,
        costIncludesTax: incl);

PurchaseGstReport _build(List<PurchaseBill> bills) =>
    PurchaseGstBuilder.build(companyGstin: _company, bills: bills);

void main() {
  test('registered intra-state supplier: CGST/SGST, eligible ITC', () {
    final r = _build([
      _bill('1', gstin: '33PQRST6789L1ZQ', items: [_item(1000, 18)]),
    ]);
    final row = r.rows.single;
    expect([row.supplierState, row.interState, row.itcEligible], ['33', false, true]);
    expect([row.taxable, row.cgst, row.sgst, row.igst, row.total], [1000, 90, 90, 0, 1180]);
    expect([r.itcRegular.cgst, r.itcRegular.igst], [90, 0]);
    expect(r.byRate.single.rate, 18);
    expect(r.warnings, isEmpty);
  });

  test('registered inter-state supplier, cost incl. tax: IGST ITC', () {
    final r = _build([
      _bill('2', gstin: '29ABCDE1234F1Z5', items: [_item(118, 18, incl: true)]),
    ]);
    expect([r.rows.single.taxable, r.rows.single.igst], [100, 18]);
    expect([r.itcRegular.igst, r.itcRegular.cgst], [18, 0]);
  });

  test('no GSTIN: tax not claimable, warned', () {
    final r = _build([_bill('3', items: [_item(200, 5)])]);
    expect(r.rows.single.itcEligible, isFalse);
    expect(r.ineligibleTax.cgst, 5);
    expect(r.itcRegular.total, 0);
    expect(r.warnings.single.kind, PurchaseGstIssueKind.taxWithoutGstin);
  });

  test('reverse charge: tax in 3.1(d)/4A(3), not owed to the supplier', () {
    final bill = _bill('4', rcm: true, items: [_item(1000, 5)]); // e.g. GTA
    expect(bill.total, 1000); // supplier charged no GST
    expect(bill.tax, 50);
    final r = _build([bill]);
    expect(r.rcmTaxable, 1000);
    expect([r.rcmTax.cgst, r.rcmTax.sgst], [25, 25]);
    expect(r.itcRegular.total, 0);
    expect(r.rows.single.itcEligible, isTrue);
    expect(r.rows.single.total, 1000);
    expect(r.warnings, isEmpty); // RCM without supplier GSTIN is fine
  });

  test('0 % lines are exempt inward (inter / intra); drafts skipped', () {
    final r = _build([
      _bill('5', gstin: '29ABCDE1234F1Z5', items: [_item(300, 0)]),
      _bill('6', gstin: '33PQRST6789L1ZQ', items: [_item(400, 0), _item(100, 18)]),
      _bill('7', gstin: '33PQRST6789L1ZQ', draft: true, items: [_item(999, 18)]),
    ]);
    expect([r.exemptInwardInter, r.exemptInwardIntra], [300, 400]);
    expect(r.rows.map((x) => x.billId), ['5', '6']);
    expect(r.byRate.single.taxable, 100); // 0 % not a rate bucket
  });

  test('invalid supplier GSTIN and unusual rate are warned', () {
    final r = _build([
      _bill('8', gstin: '123', items: [_item(100, 15)]),
    ]);
    expect({for (final w in r.warnings) (w.kind, w.detail)}, {
      (PurchaseGstIssueKind.invalidSupplierGstin, ''),
      (PurchaseGstIssueKind.unusualRate, '15'),
      (PurchaseGstIssueKind.taxWithoutGstin, ''),
    });
  });
}
