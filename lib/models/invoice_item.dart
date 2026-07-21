import 'package:invoiso/models/product.dart';

import 'package:invoiso/domain/invoice_totals_calculator.dart';

class InvoiceItem {
  Product product;
  double quantity;
  double discount;
  double? unitPrice; // overrides product.price when set
  double? extraCost; // optional flat fee added on top of the line total
  String? unit; // overrides product.unit when set
  bool
      discountPerUnit; // true  → (price − discount) × qty  (discount multiplied by qty)
  // false → (price × qty) − discount   (flat discount off line total)
  bool
      isProductSaved; // true → custom item was saved to product list; hides the save button

  InvoiceItem({
    required this.product,
    required this.quantity, // supports decimals (e.g. 1.5 hrs)
    this.discount = 0.0,
    this.unitPrice,
    this.extraCost,
    this.unit,
    this.discountPerUnit = false,
    this.isProductSaved = false,
  });

  double get effectivePrice => unitPrice ?? product.price;

  String get effectiveUnit => unit ?? product.unit;

  InvoiceLineAmount get _amounts => InvoiceTotalsCalculator.line(
        price: effectivePrice,
        quantity: quantity,
        discount: discount,
        discountPerUnit: discountPerUnit,
        extraCost: extraCost ?? 0.0,
        taxRatePercent: product.tax_rate.toDouble(),
      );

  double get grossPrice => _amounts.grossTotal;

  double get totalDiscount => _amounts.discountTotal;

  double get total => _amounts.lineTotal;

  double get taxAmount => _amounts.itemTax;
}
