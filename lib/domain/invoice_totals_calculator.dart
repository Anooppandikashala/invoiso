import 'package:invoiso/common.dart';

enum TaxRateFormat {
  fraction,
  percent,
}

class InvoiceLineAmount {
  final double lineTotal;
  final double grossTotal;
  final double discountTotal;
  final double taxRatePercent;
  final double displayTotal;

  const InvoiceLineAmount({
    required this.lineTotal,
    required this.grossTotal,
    required this.discountTotal,
    required this.taxRatePercent,
    required this.displayTotal,
  });

  double get itemTax => lineTotal * (taxRatePercent / 100);
}

class InvoiceTotals {
  final double subtotal;
  final double grossSubtotal;
  final double totalDiscount;
  final double tax;
  final double additionalCostsTotal;

  const InvoiceTotals({
    required this.subtotal,
    required this.grossSubtotal,
    required this.totalDiscount,
    required this.tax,
    required this.additionalCostsTotal,
  });

  double get total => subtotal + tax + additionalCostsTotal;
}

class InvoiceTotalsCalculator {
  const InvoiceTotalsCalculator._();

  static InvoiceLineAmount line({
    required double price,
    required double quantity,
    required double discount,
    required bool discountPerUnit,
    double extraCost = 0,
    double taxRatePercent = 0,
    bool priceIncludesTax = false,
  }) {
    final displayTotal = discountPerUnit
        ? (price - discount) * quantity + extraCost
        : (price * quantity) - discount + extraCost;
    // When price is tax-inclusive, back out the tax so lineTotal holds the
    // taxable base — itemTax and every downstream subtotal/tax sum then
    // stay correct without touching the totals() aggregation formula.
    final taxDivisor = (priceIncludesTax && taxRatePercent > 0)
        ? (1 + taxRatePercent / 100)
        : 1.0;
    final lineTotal = displayTotal / taxDivisor;
    return InvoiceLineAmount(
      lineTotal: lineTotal,
      // Back out tax here too, so grossSubtotal (pre-discount subtotal,
      // used whenever any line has a discount) stays on the same taxable
      // basis as subtotal — otherwise mixing inclusive/exclusive items
      // with a discount flips the displayed pre-discount figure between
      // tax-inclusive and tax-exclusive depending on which is shown.
      grossTotal: (price * quantity + extraCost) / taxDivisor,
      discountTotal: discountPerUnit ? discount * quantity : discount,
      taxRatePercent: taxRatePercent,
      displayTotal: displayTotal,
    );
  }

  static InvoiceLineAmount lineFromDbRow(Map<String, dynamic> row) {
    final price = (row['unit_price'] as num?)?.toDouble() ??
        (row['product_price'] as num?)?.toDouble() ??
        0.0;
    return line(
      price: price,
      quantity: (row['quantity'] as num?)?.toDouble() ?? 0.0,
      discount: (row['discount'] as num?)?.toDouble() ?? 0.0,
      discountPerUnit: (row['discount_per_unit'] as int?) == 1,
      extraCost: (row['extra_cost'] as num?)?.toDouble() ?? 0.0,
      taxRatePercent: (row['product_tax_rate'] as num?)?.toDouble() ?? 0.0,
      priceIncludesTax: (row['product_price_includes_tax'] as int?) == 1,
    );
  }

  static InvoiceTotals totals({
    required Iterable<InvoiceLineAmount> lines,
    required TaxMode taxMode,
    required double globalTaxRate,
    TaxRateFormat globalTaxRateFormat = TaxRateFormat.fraction,
    double additionalCostsTotal = 0,
  }) {
    double subtotal = 0;
    double grossSubtotal = 0;
    double totalDiscount = 0;
    double itemTax = 0;

    for (final line in lines) {
      subtotal += line.lineTotal;
      grossSubtotal += line.grossTotal;
      totalDiscount += line.discountTotal;
      if (taxMode == TaxMode.perItem) itemTax += line.itemTax;
    }

    final tax = switch (taxMode) {
      TaxMode.global => subtotal *
          (globalTaxRateFormat == TaxRateFormat.percent
              ? globalTaxRate / 100
              : globalTaxRate),
      TaxMode.perItem => itemTax,
      TaxMode.none => 0.0,
    };

    return InvoiceTotals(
      subtotal: subtotal,
      grossSubtotal: grossSubtotal,
      totalDiscount: totalDiscount,
      tax: tax,
      additionalCostsTotal: additionalCostsTotal,
    );
  }
}
