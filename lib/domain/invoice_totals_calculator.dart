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

  const InvoiceLineAmount({
    required this.lineTotal,
    required this.grossTotal,
    required this.discountTotal,
    required this.taxRatePercent,
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
  }) {
    final lineTotal = discountPerUnit
        ? (price - discount) * quantity + extraCost
        : (price * quantity) - discount + extraCost;
    return InvoiceLineAmount(
      lineTotal: lineTotal,
      grossTotal: price * quantity + extraCost,
      discountTotal: discountPerUnit ? discount * quantity : discount,
      taxRatePercent: taxRatePercent,
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
