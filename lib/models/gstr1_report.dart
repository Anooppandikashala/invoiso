// GSTR-1 return data built from the period's documents (Gstr1ExportPlan.md
// Part C). Plain values only — the Excel writer (Part D) turns these into
// the Offline Tool template sheets.

import 'package:invoiso/models/report_models.dart';

/// One rate line of a document-level section (b2b, b2cl, cdnr, cdnur).
/// Document fields repeat on every rate line, as in the template.
class Gstr1DocRow {
  final String invoiceId;
  final String gstin; // '' for unregistered (b2cl / cdnur)
  final String name;
  final String number; // as printed
  final DateTime date;
  final double value; // document total as printed
  final String pos; // 2-digit state code
  final bool reverseCharge;
  final String? noteType; // cdnr / cdnur: 'C' credit | 'D' debit; null for invoices
  final double rate;
  final double taxable;
  final double igst;
  final double cgst; // SGST is the same amount

  const Gstr1DocRow({
    required this.invoiceId,
    required this.gstin,
    required this.name,
    required this.number,
    required this.date,
    required this.value,
    required this.pos,
    required this.reverseCharge,
    this.noteType,
    required this.rate,
    required this.taxable,
    required this.igst,
    required this.cgst,
  });

  double get sgst => cgst;
}

/// b2cs: small B2C supplies summed by place of supply × rate (type OE).
class Gstr1B2csRow {
  final String pos;
  final double rate;
  final double taxable;
  final double igst;
  final double cgst;

  const Gstr1B2csRow({
    required this.pos,
    required this.rate,
    required this.taxable,
    required this.igst,
    required this.cgst,
  });

  double get sgst => cgst;
}

/// Table 8 (exemp): 0 % supplies, one row per inter/intra × registered/unregistered.
class Gstr1ExempRow {
  final bool interState;
  final bool registered;
  final double nil;
  final double exempt;
  final double nonGst;

  const Gstr1ExempRow({
    required this.interState,
    required this.registered,
    required this.nil,
    required this.exempt,
    required this.nonGst,
  });
}

/// Table 12 HSN summary row (separate lists for B2B and B2C).
class Gstr1HsnRow {
  final String hsn;
  final String description;
  final String uqc; // GST unit code, 'NA' for services
  final double quantity;
  final double rate;
  final double taxable;
  final double igst;
  final double cgst; // SGST is the same amount

  const Gstr1HsnRow({
    required this.hsn,
    required this.description,
    required this.uqc,
    required this.quantity,
    required this.rate,
    required this.taxable,
    required this.igst,
    required this.cgst,
  });

  double get sgst => cgst;
  double get totalValue => taxable + igst + cgst + sgst;
}

enum Gstr1IssueKind {
  /// Excluded: invoice not in INR (exports aren't supported).
  nonInr,

  /// Excluded: no place of supply saved and none can be derived.
  missingPlaceOfSupply,
}

/// A document left out of the return, or exported with a warning.
class Gstr1Issue {
  final Gstr1IssueKind kind;
  final String invoiceId;
  final String number;

  const Gstr1Issue(this.kind, this.invoiceId, this.number);
}

class Gstr1Report {
  final List<Gstr1DocRow> b2b;
  final List<Gstr1DocRow> b2cl;
  final List<Gstr1B2csRow> b2cs; // unregistered notes netted in
  final List<Gstr1DocRow> cdnr; // credit / debit notes to registered buyers
  final List<Gstr1DocRow> cdnur; // unregistered notes against a B2C Large invoice
  final List<Gstr1ExempRow> exemp; // always 4 rows
  final List<Gstr1HsnRow> hsnB2b;
  final List<Gstr1HsnRow> hsnB2c;
  final List<DocumentIssuedRow> docs;
  final List<Gstr1Issue> excluded;

  const Gstr1Report({
    required this.b2b,
    required this.b2cl,
    required this.b2cs,
    required this.cdnr,
    required this.cdnur,
    required this.exemp,
    required this.hsnB2b,
    required this.hsnB2c,
    required this.docs,
    required this.excluded,
  });
}
