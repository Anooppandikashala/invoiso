import 'package:invoiso/common/common.dart';

// Price glossary — which "price" to use where:
//
// product.price          Stored catalog price. Tax-inclusive or exclusive
//                         depending on product.priceIncludesTax.
// item.unitPrice          Optional per-invoice override of product.price
//                         (null = use product.price). Same inclusive/exclusive
//                         rule as product.price applies to it too.
// item.effectivePrice     unitPrice ?? product.price. "The price actually
//                         charged for one unit on this invoice." Use this,
//                         never product.price directly, when displaying/
//                         calculating an invoice line.
// netPrice()              effectivePrice with tax backed out (only when
//                         priceIncludesTax is true). "What the unit is worth
//                         before tax." Use for tax-exclusive display only —
//                         never feed it back into line()'s `price` param.
// InvoiceLineAmount.lineTotal    Taxable base for the line (qty applied,
//                         discount/extraCost applied, tax backed out if
//                         inclusive). Feeds itemTax and totals().
// InvoiceLineAmount.grossTotal   Same as lineTotal but pre-discount —
//                         used for line-item "before discount" display.
// InvoiceLineAmount.displayTotal Qty × price incl. discount/extraCost,
//                         WITHOUT backing out tax. "What the line item row
//                         shows as its total." == item.total.
// InvoiceLineAmount.itemTax      lineTotal × taxRatePercent/100. == item.taxAmount.
// InvoiceTotals.subtotal/tax/total  Invoice-wide sums of the above across
//                         all lines — see totals() below.
//
// Rule of thumb: effectivePrice for calculating, netPrice() only for showing
// a tax-exclusive number to the user, displayTotal/total for the row's price tag.

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
  final double invoiceDiscountAmount;

  const InvoiceTotals({
    required this.subtotal,
    required this.grossSubtotal,
    required this.totalDiscount,
    required this.tax,
    required this.additionalCostsTotal,
    this.invoiceDiscountAmount = 0.0,
  });

  double get preDiscountTotal => subtotal + tax + additionalCostsTotal;

  double get total =>
      (preDiscountTotal - invoiceDiscountAmount).clamp(0.0, double.infinity);
}

class InvoiceTotalsCalculator {
  const InvoiceTotalsCalculator._();

  /// Backs tax out of a tax-inclusive price. Returns [price] unchanged
  /// when the price is exclusive or tax rate is 0.
  static double netPrice({
    required double price,
    required double taxRatePercent,
    required bool priceIncludesTax,
  }) {
    if (!priceIncludesTax || taxRatePercent <= 0) return price;
    return price / (1 + taxRatePercent / 100);
  }

  static InvoiceLineAmount line({
    required double price,
    required double quantity,
    required double discount,
    required bool discountPerUnit,
    double extraCost = 0,
    double taxRatePercent = 0,
    bool priceIncludesTax = false,
    TaxMode taxMode = TaxMode.perItem,
    double globalTaxRatePercent = 0,
  }) {
    final displayTotal = discountPerUnit
        ? (price - discount) * quantity + extraCost
        : (price * quantity) - discount + extraCost;
    // When price is tax-inclusive, back out the tax so lineTotal holds the
    // taxable base — itemTax and every downstream subtotal/tax sum then
    // stay correct without touching the totals() aggregation formula.
    // In global mode the invoice charges globalTaxRatePercent, not the
    // item's own rate, so that's the rate actually baked into the price
    // and the one that must be backed out here.
    final backOutRatePercent =
        taxMode == TaxMode.global ? globalTaxRatePercent : taxRatePercent;
    final taxDivisor = (priceIncludesTax && backOutRatePercent > 0)
        ? (1 + backOutRatePercent / 100)
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

  static InvoiceLineAmount lineFromDbRow(
    Map<String, dynamic> row, {
    TaxMode taxMode = TaxMode.perItem,
    double globalTaxRatePercent = 0,
  }) {
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
      taxMode: taxMode,
      globalTaxRatePercent: globalTaxRatePercent,
    );
  }

  static InvoiceTotals totals({
    required Iterable<InvoiceLineAmount> lines,
    required TaxMode taxMode,
    required double globalTaxRate,
    TaxRateFormat globalTaxRateFormat = TaxRateFormat.fraction,
    double additionalCostsTotal = 0,
    InvoiceDiscountType invoiceDiscountType = InvoiceDiscountType.percent,
    double invoiceDiscountValue = 0,
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

    final preDiscountTotal = subtotal + tax + additionalCostsTotal;
    final invoiceDiscountAmount = invoiceDiscountValue <= 0
        ? 0.0
        : (invoiceDiscountType == InvoiceDiscountType.percent
            ? preDiscountTotal * invoiceDiscountValue / 100
            : invoiceDiscountValue);

    return InvoiceTotals(
      subtotal: subtotal,
      grossSubtotal: grossSubtotal,
      totalDiscount: totalDiscount,
      tax: tax,
      additionalCostsTotal: additionalCostsTotal,
      invoiceDiscountAmount: invoiceDiscountAmount,
    );
  }
}
