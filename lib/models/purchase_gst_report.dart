// Purchase side of GST (PurchaseGstReportsPlan.md): purchase register rows
// and the GSTR-3B inward figures, built by PurchaseGstBuilder.

/// One purchase bill as GST sees it (purchase register row).
class PurchaseGstRow {
  final String billId;
  final String billNumber;
  final DateTime date;
  final String supplierName;
  final String supplierGstin; // copy on the bill; '' = none
  final String? supplierState; // 2-digit code from a valid GSTIN
  final bool interState;
  final bool reverseCharge;

  /// Tax claimable as ITC: valid supplier GSTIN, or a reverse-charge bill.
  final bool itcEligible;
  final double taxable; // all rates incl. 0 %
  final double igst;
  final double cgst; // SGST is the same amount
  final double total; // owed to the supplier (RCM: excludes the tax)

  const PurchaseGstRow({
    required this.billId,
    required this.billNumber,
    required this.date,
    required this.supplierName,
    required this.supplierGstin,
    required this.supplierState,
    required this.interState,
    required this.reverseCharge,
    required this.itcEligible,
    required this.taxable,
    required this.igst,
    required this.cgst,
    required this.total,
  });

  double get sgst => cgst;
  double get tax => igst + cgst * 2;
}

/// Taxable value and tax at one rate (register header / 3B tables).
class PurchaseGstBucket {
  final double rate;
  final double taxable;
  final double igst;
  final double cgst;

  const PurchaseGstBucket({
    required this.rate,
    required this.taxable,
    required this.igst,
    required this.cgst,
  });

  double get sgst => cgst;
}

/// IGST / CGST / SGST amounts (SGST = CGST).
class GstHeads {
  final double igst;
  final double cgst;

  const GstHeads({this.igst = 0, this.cgst = 0});

  double get sgst => cgst;
  double get total => igst + cgst * 2;
}

enum PurchaseGstIssueKind {
  /// Supplier GSTIN present but not a valid format → no ITC.
  invalidSupplierGstin,

  /// Tax on a bill without a valid supplier GSTIN (not reverse charge) —
  /// not claimable.
  taxWithoutGstin,

  /// Tax rate not in the GST rate list ([detail] = rate).
  unusualRate,
}

class PurchaseGstIssue {
  final PurchaseGstIssueKind kind;
  final String billId;
  final String billNumber;
  final String detail;

  const PurchaseGstIssue(this.kind, this.billId, this.billNumber,
      [this.detail = '']);
}

class PurchaseGstReport {
  final List<PurchaseGstRow> rows; // final bills, by date
  final List<PurchaseGstBucket> byRate; // every bill, rates > 0

  /// GSTR-3B 4A(5): ITC from regular bills of registered suppliers.
  final GstHeads itcRegular;

  /// GSTR-3B 3.1(d) (payable in cash) and 4A(3) (ITC): reverse-charge bills.
  final double rcmTaxable;
  final GstHeads rcmTax;

  /// Tax on bills that can't be claimed (no valid supplier GSTIN).
  final GstHeads ineligibleTax;

  /// GSTR-3B table 5: 0 % inward supplies, inter- / intra-state.
  final double exemptInwardInter;
  final double exemptInwardIntra;

  final List<PurchaseGstIssue> warnings;

  const PurchaseGstReport({
    required this.rows,
    required this.byRate,
    required this.itcRegular,
    required this.rcmTaxable,
    required this.rcmTax,
    required this.ineligibleTax,
    required this.exemptInwardInter,
    required this.exemptInwardIntra,
    required this.warnings,
  });
}
