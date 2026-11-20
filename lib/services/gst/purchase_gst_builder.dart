import 'package:invoiso/common/gst_utils.dart';
import 'package:invoiso/domain/purchase_bill_totals_calculator.dart';
import 'package:invoiso/models/purchase_bill.dart';
import 'package:invoiso/models/purchase_gst_report.dart';
import 'package:invoiso/services/gst/gstr1_builder.dart';

/// Purchase side of GST from purchase bills (PurchaseGstReportsPlan.md P1).
/// Pure — the loader fetches the period's bills (SQLite or cloud).
///
/// Rules: inter-state = supplier GSTIN state ≠ company GSTIN state (bills
/// carry no flag; unknown supplier state → intra). ITC: reverse-charge bills,
/// or regular bills from a supplier with a valid GSTIN (Q2 — blocked credits
/// are the user's call). 0 % lines = exempt / nil inward (3B table 5).
class PurchaseGstBuilder {
  const PurchaseGstBuilder._();

  static PurchaseGstReport build({
    required String companyGstin,
    required List<PurchaseBill> bills,
  }) {
    final companyState = GstUtils.stateCodeFromGstin(companyGstin);
    final rows = <PurchaseGstRow>[];
    final buckets = <double, List<double>>{}; // rate → [taxable, igst, cgst]
    final warnings = <PurchaseGstIssue>[];
    var itc = [0.0, 0.0], rcm = [0.0, 0.0], noItc = [0.0, 0.0];
    var rcmTaxable = 0.0, exemptInter = 0.0, exemptIntra = 0.0;

    final sorted = [...bills.where((b) => !b.isDraft)]
      ..sort((a, b) => a.billDate.compareTo(b.billDate));
    for (final bill in sorted) {
      final number = bill.billNumber ?? '';
      final gstin = bill.supplierGstin.trim();
      final supplierState = GstUtils.stateCodeFromGstin(gstin);
      final inter = supplierState != null &&
          companyState != null &&
          supplierState != companyState;
      final eligible = bill.reverseCharge || supplierState != null;

      if (gstin.isNotEmpty && supplierState == null) {
        warnings.add(PurchaseGstIssue(
            PurchaseGstIssueKind.invalidSupplierGstin, bill.id, number));
      }

      var taxable = 0.0, tax = 0.0;
      for (final item in bill.items) {
        final l = PurchaseBillTotalsCalculator.line(
          costPerUnit: item.costPerUnit,
          quantity: item.quantity,
          taxRatePercent: item.taxRate,
          costIncludesTax: item.costIncludesTax,
        );
        taxable += l.lineTotal;
        tax += l.itemTax;
        if (item.taxRate == 0) {
          if (inter) {
            exemptInter += l.lineTotal;
          } else {
            exemptIntra += l.lineTotal;
          }
          continue;
        }
        if (!Gstr1Builder.gstRates.contains(item.taxRate)) {
          warnings.add(PurchaseGstIssue(PurchaseGstIssueKind.unusualRate,
              bill.id, number, _rateText(item.taxRate)));
        }
        final b = buckets.putIfAbsent(item.taxRate, () => [0, 0, 0]);
        b[0] += l.lineTotal;
        b[inter ? 1 : 2] += inter ? l.itemTax : l.itemTax / 2;
        if (bill.reverseCharge) rcmTaxable += l.lineTotal;
      }

      final heads = bill.reverseCharge ? rcm : eligible ? itc : noItc;
      heads[inter ? 0 : 1] += inter ? tax : tax / 2;
      if (!eligible && tax > 0) {
        warnings.add(PurchaseGstIssue(
            PurchaseGstIssueKind.taxWithoutGstin, bill.id, number));
      }

      rows.add(PurchaseGstRow(
        billId: bill.id,
        billNumber: number,
        date: bill.billDate,
        supplierName: bill.supplierName,
        supplierGstin: gstin,
        supplierState: supplierState,
        interState: inter,
        reverseCharge: bill.reverseCharge,
        itcEligible: eligible,
        taxable: _r(taxable),
        igst: inter ? _r(tax) : 0,
        cgst: inter ? 0 : _r(tax / 2),
        total: _r(bill.total),
      ));
    }

    GstHeads heads(List<double> h) => GstHeads(igst: _r(h[0]), cgst: _r(h[1]));
    return PurchaseGstReport(
      rows: rows,
      byRate: [
        for (final e in (buckets.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key))))
          PurchaseGstBucket(
            rate: e.key,
            taxable: _r(e.value[0]),
            igst: _r(e.value[1]),
            cgst: _r(e.value[2]),
          ),
      ],
      itcRegular: heads(itc),
      rcmTaxable: _r(rcmTaxable),
      rcmTax: heads(rcm),
      ineligibleTax: heads(noItc),
      exemptInwardInter: _r(exemptInter),
      exemptInwardIntra: _r(exemptIntra),
      warnings: warnings,
    );
  }

  static double _r(double v) => (v * 100).round() / 100;

  static String _rateText(double r) => r % 1 == 0 ? '${r.toInt()}' : '$r';
}
