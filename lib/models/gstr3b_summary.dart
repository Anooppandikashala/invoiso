// GSTR-3B summary (PurchaseGstReportsPlan.md P5): the figures to type into
// the GST portal — 3B has no upload file. Built by Gstr3bBuilder from the
// GSTR-1 report (sales) and the purchase GST report.

import 'package:invoiso/models/gstr1_report.dart';
import 'package:invoiso/models/purchase_gst_report.dart';

/// Taxable value + tax by head (one 3B row).
class Gstr3bRow {
  final double taxable;
  final GstHeads tax;

  const Gstr3bRow({this.taxable = 0, this.tax = const GstHeads()});
}

/// Table 3.2: inter-state supplies to unregistered persons, one place of supply.
class Gstr3bInterStateRow {
  final String pos;
  final double taxable;
  final double igst;

  const Gstr3bInterStateRow(
      {required this.pos, required this.taxable, required this.igst});
}

/// Table 6.1 for one head (IGST / CGST / SGST).
class Gstr3bPayment {
  final double payable; // 3.1(a) + 3.1(d) tax
  final double paidByItc;
  final double paidInCash; // incl. all reverse-charge tax (cash only)
  final double itcLeft; // credit carried forward

  const Gstr3bPayment({
    required this.payable,
    required this.paidByItc,
    required this.paidInCash,
    required this.itcLeft,
  });
}

class Gstr3bSummary {
  final Gstr3bRow outwardTaxable; // 3.1(a)
  final double outwardZeroRated; // 3.1(b) — exports not supported → 0
  final double outwardNilExempt; // 3.1(c)
  final Gstr3bRow inwardReverseCharge; // 3.1(d)
  final double outwardNonGst; // 3.1(e)
  final List<Gstr3bInterStateRow> interStateUnregistered; // 3.2

  final GstHeads itcReverseCharge; // 4A(3)
  final GstHeads itcOther; // 4A(5)
  GstHeads get itcNet => GstHeads(
      igst: itcReverseCharge.igst + itcOther.igst,
      cgst: itcReverseCharge.cgst + itcOther.cgst); // 4C (no reversals)
  final GstHeads notClaimable; // purchase tax without a valid supplier GSTIN

  final double inwardExemptInter; // 5
  final double inwardExemptIntra;

  final Gstr3bPayment igst; // 6.1
  final Gstr3bPayment cgst;
  final Gstr3bPayment sgst;

  /// Warnings carried over from both sides.
  final List<Gstr1Issue> salesWarnings;
  final List<PurchaseGstIssue> purchaseWarnings;
  final List<Gstr1Issue> salesExcluded;
  final bool companyGstinValid;

  const Gstr3bSummary({
    required this.outwardTaxable,
    required this.outwardZeroRated,
    required this.outwardNilExempt,
    required this.inwardReverseCharge,
    required this.outwardNonGst,
    required this.interStateUnregistered,
    required this.itcReverseCharge,
    required this.itcOther,
    required this.notClaimable,
    required this.inwardExemptInter,
    required this.inwardExemptIntra,
    required this.igst,
    required this.cgst,
    required this.sgst,
    required this.salesWarnings,
    required this.purchaseWarnings,
    required this.salesExcluded,
    required this.companyGstinValid,
  });
}
