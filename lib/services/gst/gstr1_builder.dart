import 'package:invoiso/common/common.dart';
import 'package:invoiso/common/gst_utils.dart';
import 'package:invoiso/domain/invoice_totals_calculator.dart';
import 'package:invoiso/models/gstr1_report.dart';
import 'package:invoiso/models/invoice.dart';

/// What the GSTR-1 builder needs; loaded by the caller (SQLite or cloud).
class Gstr1Input {
  final String companyGstin;

  /// Non-draft, non-deleted documents dated in the return period.
  final List<Invoice> documents;

  /// Document number as printed (prefix + number, or the custom number).
  final String Function(Invoice) numberOf;

  const Gstr1Input({
    required this.companyGstin,
    required this.documents,
    required this.numberOf,
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
    final b2csSums = <String, List<double>>{}; // 'pos|rate' → [taxable, igst, cgst]
    final excluded = <Gstr1Issue>[];

    for (final inv in input.documents) {
      if (inv.type != 'Invoice') continue;
      final number = input.numberOf(inv);
      if (inv.currencyCode != 'INR') {
        excluded.add(Gstr1Issue(Gstr1IssueKind.nonInr, inv.id, number));
        continue;
      }
      final pos = placeOfSupply(inv, companyState);
      if (pos == null) {
        excluded.add(
            Gstr1Issue(Gstr1IssueKind.missingPlaceOfSupply, inv.id, number));
        continue;
      }
      // 0 % supplies go to the nil / exempt table, not the rate sections.
      final split = rateSplit(inv)..remove(0.0);
      final gstin = inv.customer.gstin.trim();
      final isB2cl =
          gstin.isEmpty && pos != companyState && inv.total > b2clLimit;

      if (gstin.isNotEmpty || isB2cl) {
        for (final e in split.entries) {
          (gstin.isNotEmpty ? b2b : b2cl).add(Gstr1DocRow(
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
            rate: e.key,
            taxable: _r(e.value.taxable),
            igst: inv.isInterState ? _r(e.value.tax) : 0,
            cgst: inv.isInterState ? 0 : _r(e.value.tax / 2),
          ));
        }
      } else {
        for (final e in split.entries) {
          final s = b2csSums.putIfAbsent('$pos|${e.key}', () => [0, 0, 0]);
          s[0] += e.value.taxable;
          s[inv.isInterState ? 1 : 2] += inv.isInterState ? e.value.tax : e.value.tax / 2;
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
      excluded: excluded,
    );
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
