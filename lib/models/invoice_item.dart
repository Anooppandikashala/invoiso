import 'package:uuid/uuid.dart';

import 'package:invoiso/models/product.dart';

import 'package:invoiso/domain/invoice_totals_calculator.dart';

class InvoiceItem {
  String id;
  Product product;
  double quantity;
  double discount;
  double? unitPrice; // overrides product.price when set
  double? extraCost; // optional flat fee added on top of the line total
  String? unit; // overrides product.unit when set
  String? description; // optional per-line note typed on the invoice
  bool
      discountPerUnit; // true  → (price − discount) × qty  (discount multiplied by qty)
  // false → (price × qty) − discount   (flat discount off line total)
  bool
      isProductSaved; // true → custom item was saved to product list; hides the save button

  InvoiceItem({
    String? id,
    required this.product,
    required this.quantity, // supports decimals (e.g. 1.5 hrs)
    this.discount = 0.0,
    this.unitPrice,
    this.extraCost,
    this.unit,
    this.description,
    this.discountPerUnit = false,
    this.isProductSaved = false,
  }) : id = id ?? const Uuid().v4();

  double get effectivePrice => unitPrice ?? product.price;

  String get effectiveUnit => unit ?? product.unit;
  
  String get effectiveDescription => (description ?? '').trim();

  /// What prints on an invoice (A4 + thermal): the per-line note if the user
  /// typed one, otherwise the product's own snapshotted description. Only
  /// rendered when the "Show Product Description" setting is on. Kept out of
  /// [effectiveDescription] so the edit field is never seeded from the
  /// product.
  String get printedDescription => effectiveDescription.isNotEmpty
      ? effectiveDescription
      : product.description.trim();

  InvoiceLineAmount get _amounts => InvoiceTotalsCalculator.line(
        price: effectivePrice,
        quantity: quantity,
        discount: discount,
        discountPerUnit: discountPerUnit,
        extraCost: extraCost ?? 0.0,
        taxRatePercent: product.tax_rate.toDouble(),
        priceIncludesTax: product.priceIncludesTax,
      );

  double get grossPrice => _amounts.grossTotal;

  double get totalDiscount => _amounts.discountTotal;

  double get total => _amounts.displayTotal;

  double get taxAmount => _amounts.itemTax;
}
