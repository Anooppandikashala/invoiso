// Purchase bill line/total math. Simpler than InvoiceTotalsCalculator on
// purpose — no discount and no tax-mode branching (D... see plan doc).

class PurchaseBillLineAmount {
  final double lineTotal; // cost basis: costPerUnit × quantity
  final double taxRatePercent;

  const PurchaseBillLineAmount({
    required this.lineTotal,
    required this.taxRatePercent,
  });

  double get itemTax => lineTotal * (taxRatePercent / 100);

  double get displayTotal => lineTotal + itemTax;
}

class PurchaseBillTotals {
  final double subtotal;
  final double tax;

  const PurchaseBillTotals({
    required this.subtotal,
    required this.tax,
  });

  double get total => subtotal + tax;
}

class PurchaseBillTotalsCalculator {
  const PurchaseBillTotalsCalculator._();

  static PurchaseBillLineAmount line({
    required double costPerUnit,
    required double quantity,
    double taxRatePercent = 0,
    bool costIncludesTax = false,
  }) {
    final rawTotal = costPerUnit * quantity;
    // When the entered cost already includes tax, back it out so lineTotal
    // holds the taxable base — itemTax/displayTotal (lineTotal + itemTax)
    // then still resolve back to the original rawTotal, same technique as
    // InvoiceTotalsCalculator.line's priceIncludesTax handling.
    final taxDivisor =
        (costIncludesTax && taxRatePercent > 0) ? (1 + taxRatePercent / 100) : 1.0;
    return PurchaseBillLineAmount(
      lineTotal: rawTotal / taxDivisor,
      taxRatePercent: taxRatePercent,
    );
  }

  static PurchaseBillLineAmount lineFromDbRow(Map<String, dynamic> row) {
    return line(
      costPerUnit: (row['cost_per_unit'] as num?)?.toDouble() ?? 0.0,
      quantity: (row['quantity'] as num?)?.toDouble() ?? 0.0,
      taxRatePercent: (row['tax_rate'] as num?)?.toDouble() ?? 0.0,
      costIncludesTax: (row['cost_includes_tax'] as int?) == 1,
    );
  }

  static PurchaseBillTotals totals({
    required Iterable<PurchaseBillLineAmount> lines,
  }) {
    double subtotal = 0;
    double tax = 0;
    for (final line in lines) {
      subtotal += line.lineTotal;
      tax += line.itemTax;
    }
    return PurchaseBillTotals(subtotal: subtotal, tax: tax);
  }
}
