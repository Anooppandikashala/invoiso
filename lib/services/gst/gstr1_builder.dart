import 'package:invoiso/common/common.dart';
import 'package:invoiso/common/gst_utils.dart';
import 'package:invoiso/domain/invoice_totals_calculator.dart';
import 'package:invoiso/models/gstr1_report.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/report_models.dart';

/// What the GSTR-1 builder needs; loaded by the caller (SQLite or cloud).
class Gstr1Input {
  final String companyGstin;

  /// Non-draft, non-deleted documents dated in the return period.
  final List<Invoice> documents;

  /// Document number as printed (prefix + number, or the custom number).
  final String Function(Invoice) numberOf;

  /// Original invoices of the period's credit / debit notes, by id (may be
  /// from an earlier period) — decides whether a B2C note is cdnur.
  final Map<String, Invoice> originals;

  /// Documents issued (Table 13) for the period — from the reports.
  final List<DocumentIssuedRow> documentsIssued;

  const Gstr1Input({
    required this.companyGstin,
    required this.documents,
    required this.numberOf,
    this.originals = const {},
    this.documentsIssued = const [],
  });
}

/// Builds GSTR-1 sections from invoices (Gstr1ExportPlan.md Part C). Pure —
/// no DB — so desktop and cloud share it. Amounts follow the printed invoice
/// (same calculator); each row is rounded to 2 decimals.
class Gstr1Builder {
  const Gstr1Builder._();

  /// B2C inter-state invoices above this value are B2C Large (from 1 Aug 2024).
  static const b2clLimit = 100000.0;

  static Gstr1Report build(Gstr1Input input) {
    final companyState = GstUtils.stateCodeFromGstin(input.companyGstin);
    final b2b = <Gstr1DocRow>[];
    final b2cl = <Gstr1DocRow>[];
    final cdnr = <Gstr1DocRow>[];
    final cdnur = <Gstr1DocRow>[];
    final b2csSums = <String, List<double>>{}; // 'pos|rate' → [taxable, igst, cgst]
    final excluded = <Gstr1Issue>[];
    // Table 8: 'interState|registered' → [nil, exempt, nonGst]
    final exemp = {
      for (final k in ['true|true', 'false|true', 'true|false', 'false|false'])
        k: [0.0, 0.0, 0.0],
    };
    // Table 12: 'registered|hsn|uqc|rate' → [qty, taxable, igst, cgst]
    final hsnSums = <String, List<double>>{};
    final hsnNames = <String, String>{};

    bool isB2cl(Invoice inv, String? pos) =>
        inv.customer.gstin.trim().isEmpty &&
        pos != companyState &&
        inv.total > b2clLimit;

    for (final inv in input.documents) {
      final isNote = inv.type == 'Credit Note' || inv.type == 'Debit Note';
      if (inv.type != 'Invoice' && !isNote) continue;
      final number = input.numberOf(inv);
      if (inv.currencyCode != 'INR') {
        excluded.add(Gstr1Issue(Gstr1IssueKind.nonInr, inv.id, number));
        continue;
      }
      final original = input.originals[inv.originalInvoiceId];
      final pos = placeOfSupply(inv, companyState) ??
          (original == null ? null : placeOfSupply(original, companyState));
      if (pos == null) {
        excluded.add(
            Gstr1Issue(Gstr1IssueKind.missingPlaceOfSupply, inv.id, number));
        continue;
      }
      // 0 % supplies go to the nil / exempt table, not the rate sections.
      final split = rateSplit(inv)..remove(0.0);
      final gstin = inv.customer.gstin.trim();
      final sign = inv.type == 'Credit Note' ? -1.0 : 1.0;
      final registered = gstin.isNotEmpty;

      final ex = exemp['${inv.isInterState}|$registered']!;
      for (final z in zeroRated(inv).entries) {
        ex[z.key == 'exempt' ? 1 : z.key == 'non_gst' ? 2 : 0] += sign * z.value;
      }
      for (final l in hsnLines(inv)) {
        final key = '$registered|${l.hsn}|${l.uqc}|${l.rate}';
        hsnNames.putIfAbsent(key, () => l.description);
        final h = hsnSums.putIfAbsent(key, () => [0, 0, 0, 0]);
        h[0] += sign * l.quantity;
        h[1] += sign * l.taxable;
        if (inv.isInterState) {
          h[2] += sign * l.tax;
        } else {
          h[3] += sign * l.tax / 2;
        }
      }

      final List<Gstr1DocRow>? rows = !isNote
          ? (gstin.isNotEmpty ? b2b : isB2cl(inv, pos) ? b2cl : null)
          : (gstin.isNotEmpty
              ? cdnr
              : original != null &&
                      isB2cl(original, placeOfSupply(original, companyState))
                  ? cdnur
                  : null);
      if (rows != null) {
        for (final e in split.entries) {
          rows.add(Gstr1DocRow(
            invoiceId: inv.id,
            gstin: gstin,
            name: inv.customer.businessName.trim().isNotEmpty
                ? inv.customer.businessName.trim()
                : inv.customer.name,
            number: number,
            date: inv.date,
            value: _r(inv.total),
            pos: pos,
            reverseCharge: inv.reverseCharge,
            noteType: !isNote ? null : inv.type == 'Credit Note' ? 'C' : 'D',
            rate: e.key,
            taxable: _r(e.value.taxable),
            igst: inv.isInterState ? _r(e.value.tax) : 0,
            cgst: inv.isInterState ? 0 : _r(e.value.tax / 2),
          ));
        }
      } else {
        // b2cs; unregistered credit notes reduce it, debit notes add.
        final sign = inv.type == 'Credit Note' ? -1.0 : 1.0;
        for (final e in split.entries) {
          final s = b2csSums.putIfAbsent('$pos|${e.key}', () => [0, 0, 0]);
          s[0] += sign * e.value.taxable;
          if (inv.isInterState) {
            s[1] += sign * e.value.tax;
          } else {
            s[2] += sign * e.value.tax / 2;
          }
        }
      }
    }

    return Gstr1Report(
      b2b: b2b,
      b2cl: b2cl,
      b2cs: [
        for (final e in b2csSums.entries)
          Gstr1B2csRow(
            pos: e.key.split('|')[0],
            rate: double.parse(e.key.split('|')[1]),
            taxable: _r(e.value[0]),
            igst: _r(e.value[1]),
            cgst: _r(e.value[2]),
          ),
      ]..sort((a, b) => a.pos != b.pos
          ? a.pos.compareTo(b.pos)
          : a.rate.compareTo(b.rate)),
      cdnr: cdnr,
      cdnur: cdnur,
      exemp: [
        for (final e in exemp.entries)
          Gstr1ExempRow(
            interState: e.key.startsWith('true'),
            registered: e.key.endsWith('true'),
            nil: _r(e.value[0]),
            exempt: _r(e.value[1]),
            nonGst: _r(e.value[2]),
          ),
      ],
      hsnB2b: _hsnRows(hsnSums, hsnNames, registered: true),
      hsnB2c: _hsnRows(hsnSums, hsnNames, registered: false),
      docs: input.documentsIssued,
      excluded: excluded,
    );
  }

  static List<Gstr1HsnRow> _hsnRows(Map<String, List<double>> sums,
      Map<String, String> names, {required bool registered}) {
    return [
      for (final e in sums.entries)
        if (e.key.startsWith('$registered|'))
          Gstr1HsnRow(
            hsn: e.key.split('|')[1],
            uqc: e.key.split('|')[2],
            rate: double.parse(e.key.split('|')[3]),
            description: names[e.key]!,
            quantity: _r(e.value[0]),
            taxable: _r(e.value[1]),
            igst: _r(e.value[2]),
            cgst: _r(e.value[3]),
          ),
    ]..sort((a, b) =>
        a.hsn != b.hsn ? a.hsn.compareTo(b.hsn) : a.rate.compareTo(b.rate));
  }

  /// Rate (%) a line is taxed at on this invoice.
  static double _lineRate(Invoice inv, InvoiceLineAmount l) =>
      switch (inv.taxMode) {
        TaxMode.none => 0.0,
        TaxMode.global => inv.taxRate * 100,
        TaxMode.perItem => l.taxRatePercent,
      };

  /// 0 % taxable value by product GST type ('' nil | 'exempt' | 'non_gst');
  /// 0 % taxable charges count as nil-rated.
  static Map<String, double> zeroRated(Invoice inv) {
    final out = <String, double>{};
    final lines = inv.lineAmounts;
    for (var i = 0; i < lines.length; i++) {
      if (_lineRate(inv, lines[i]) != 0) continue;
      final cat = inv.items[i].product.gstCategory;
      out[cat] = (out[cat] ?? 0) + lines[i].lineTotal;
    }
    for (final c in InvoiceTotalsCalculator.taxedCharges(
        inv.additionalCosts, inv.taxMode, inv.taxRate)) {
      if (c.rate == 0) out[''] = (out[''] ?? 0) + c.taxable;
    }
    return out;
  }

  /// HSN summary lines of one invoice (items + taxable charges). UQC: the
  /// item's saved code, else derived from unit / HSN, else OTH; NA → qty 0.
  static List<
      ({String hsn, String description, String uqc, double quantity,
        double rate, double taxable, double tax})> hsnLines(Invoice inv) {
    final lines = inv.lineAmounts;
    return [
      for (var i = 0; i < lines.length; i++)
        () {
          final item = inv.items[i];
          final l = lines[i];
          final hsn = item.product.hsncode.trim();
          final uqc = item.product.uqc.isNotEmpty
              ? item.product.uqc
              : GstUtils.suggestUqc(item.effectiveUnit,
                      hsn: hsn, isService: item.product.type == 'service') ??
                  'OTH';
          return (
            hsn: hsn,
            description: item.product.name,
            uqc: uqc,
            quantity: uqc == 'NA' ? 0.0 : item.quantity,
            rate: _lineRate(inv, l),
            taxable: l.lineTotal,
            tax: switch (inv.taxMode) {
              TaxMode.none => 0.0,
              TaxMode.global => l.lineTotal * inv.taxRate,
              TaxMode.perItem => l.itemTax,
            },
          );
        }(),
      for (final c in InvoiceTotalsCalculator.taxedCharges(
          inv.additionalCosts, inv.taxMode, inv.taxRate))
        (
          hsn: c.hsn,
          description: '',
          uqc: 'NA',
          quantity: 0.0,
          rate: c.rate,
          taxable: c.taxable,
          tax: c.tax,
        ),
    ];
  }

  /// Taxable value and tax per rate (%) as printed: lines in the invoice's
  /// tax mode plus taxable additional charges. No-tax invoices → all at 0 %.
  static Map<double, ({double taxable, double tax})> rateSplit(Invoice inv) {
    final sums = <double, List<double>>{};
    void add(double rate, double taxable, double tax) {
      final s = sums.putIfAbsent(rate, () => [0, 0]);
      s[0] += taxable;
      s[1] += tax;
    }

    final lines = inv.lineAmounts;
    switch (inv.taxMode) {
      case TaxMode.none:
        for (final l in lines) {
          add(0, l.lineTotal, 0);
        }
      case TaxMode.global:
        final subtotal = lines.fold(0.0, (s, l) => s + l.lineTotal);
        add(inv.taxRate * 100, subtotal, subtotal * inv.taxRate);
      case TaxMode.perItem:
        for (final l in lines) {
          add(l.taxRatePercent, l.lineTotal, l.itemTax);
        }
    }
    for (final c in InvoiceTotalsCalculator.taxedCharges(
        inv.additionalCosts, inv.taxMode, inv.taxRate)) {
      add(c.rate, c.taxable, c.tax);
    }
    return {
      for (final e in sums.entries) e.key: (taxable: e.value[0], tax: e.value[1]),
    };
  }

  /// Saved place of supply → else the customer GSTIN's state → else the
  /// company state when the supply was intra-state → else null (unknown).
  static String? placeOfSupply(Invoice inv, String? companyState) {
    final saved = inv.placeOfSupply;
    if (saved != null && saved.isNotEmpty) return saved;
    final fromGstin = GstUtils.stateCodeFromGstin(inv.customer.gstin);
    if (fromGstin != null) return fromGstin;
    return inv.isInterState ? null : companyState;
  }

  static double _r(double v) => (v * 100).round() / 100;
}
