import 'package:invoiso/common/gst_utils.dart';
import 'package:invoiso/models/gstr1_report.dart';
import 'package:invoiso/models/gstr3b_summary.dart';
import 'package:invoiso/models/purchase_gst_report.dart';

/// GSTR-3B summary from the GSTR-1 report (sales — same numbers as the
/// GSTR-1 export) and the purchase GST report (PurchaseGstReportsPlan.md P5).
/// Pure.
///
/// 6.1 set-off (Sec 49 / Rule 88A): IGST credit first against IGST, then
/// CGST, then SGST; CGST credit against CGST, then IGST; SGST credit against
/// SGST, then IGST (never CGST ↔ SGST). Reverse-charge tax is cash only.
class Gstr3bBuilder {
  const Gstr3bBuilder._();

  static Gstr3bSummary build({
    required String companyGstin,
    required Gstr1Report sales,
    required PurchaseGstReport purchases,
  }) {
    final companyState = GstUtils.stateCodeFromGstin(companyGstin);

    // 3.1(a): rate sections; credit notes subtract, debit notes add.
    var taxable = 0.0, igst = 0.0, cgst = 0.0;
    void addDoc(Gstr1DocRow x) {
      final sign = x.noteType == 'C' ? -1.0 : 1.0;
      taxable += sign * x.taxable;
      igst += sign * x.igst;
      cgst += sign * x.cgst;
    }

    for (final x in [...sales.b2b, ...sales.b2cl, ...sales.cdnr, ...sales.cdnur]) {
      addDoc(x);
    }
    for (final x in sales.b2cs) {
      taxable += x.taxable;
      igst += x.igst;
      cgst += x.cgst;
    }

    // 3.2: inter-state B2C (large + small, unregistered notes) by place of supply.
    final inter = <String, List<double>>{};
    void addInter(String pos, double t, double i) {
      if (pos == companyState) return;
      final s = inter.putIfAbsent(pos, () => [0, 0]);
      s[0] += t;
      s[1] += i;
    }

    for (final x in sales.b2cl) {
      addInter(x.pos, x.taxable, x.igst);
    }
    for (final x in sales.cdnur) {
      final sign = x.noteType == 'C' ? -1.0 : 1.0;
      addInter(x.pos, sign * x.taxable, sign * x.igst);
    }
    for (final x in sales.b2cs) {
      addInter(x.pos, x.taxable, x.igst);
    }

    double sum(double Function(Gstr1ExempRow) f) =>
        sales.exemp.fold(0.0, (a, x) => a + f(x));

    // 6.1 set-off.
    final outward = [igst, cgst, cgst]; // I, C, S liability (3.1(a))
    final rcm = purchases.rcmTax;
    final itc = [
      rcm.igst + purchases.itcRegular.igst,
      rcm.cgst + purchases.itcRegular.cgst,
      rcm.sgst + purchases.itcRegular.sgst,
    ];
    final left = [for (final v in outward) v < 0 ? 0.0 : v];
    final credit = [...itc];
    final used = [0.0, 0.0, 0.0]; // ITC applied against each head's liability
    void apply(int from, int to) {
      final x = credit[from] < left[to] ? credit[from] : left[to];
      credit[from] -= x;
      left[to] -= x;
      used[to] += x;
    }

    apply(0, 0); apply(0, 1); apply(0, 2); // IGST credit
    apply(1, 1); apply(1, 0); // CGST credit
    apply(2, 2); apply(2, 0); // SGST credit
    final rcmByHead = [rcm.igst, rcm.cgst, rcm.sgst];
    Gstr3bPayment pay(int h) => Gstr3bPayment(
          payable: _r(outward[h] + rcmByHead[h]),
          paidByItc: _r(used[h]),
          paidInCash: _r(left[h] + rcmByHead[h]),
          itcLeft: _r(credit[h]),
        );

    return Gstr3bSummary(
      outwardTaxable: Gstr3bRow(
          taxable: _r(taxable), tax: GstHeads(igst: _r(igst), cgst: _r(cgst))),
      outwardZeroRated: 0,
      outwardNilExempt: _r(sum((x) => x.nil + x.exempt)),
      inwardReverseCharge:
          Gstr3bRow(taxable: purchases.rcmTaxable, tax: purchases.rcmTax),
      outwardNonGst: _r(sum((x) => x.nonGst)),
      interStateUnregistered: [
        for (final e in (inter.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key))))
          Gstr3bInterStateRow(
              pos: e.key, taxable: _r(e.value[0]), igst: _r(e.value[1])),
      ],
      itcReverseCharge: purchases.rcmTax,
      itcOther: purchases.itcRegular,
      notClaimable: purchases.ineligibleTax,
      inwardExemptInter: purchases.exemptInwardInter,
      inwardExemptIntra: purchases.exemptInwardIntra,
      igst: pay(0),
      cgst: pay(1),
      sgst: pay(2),
      salesWarnings: sales.warnings,
      purchaseWarnings: purchases.warnings,
      salesExcluded: sales.excluded,
      companyGstinValid: sales.companyGstinValid,
    );
  }

  static double _r(double v) => (v * 100).round() / 100;
}
