import 'package:invoiso/models/product.dart';

class InvoiceItem {
  Product product;
  double quantity;
  double discount;
  double? unitPrice;       // overrides product.price when set
  double? extraCost;       // optional flat fee added on top of the line total
  bool discountPerUnit;    // true  → (price − discount) × qty  (discount multiplied by qty)
                           // false → (price × qty) − discount   (flat discount off line total)
  bool isProductSaved;     // true → custom item was saved to product list; hides the save button

  InvoiceItem({
    required this.product,
    required this.quantity,  // supports decimals (e.g. 1.5 hrs)
    this.discount = 0.0,
    this.unitPrice,
    this.extraCost,
    this.discountPerUnit = false,
    this.isProductSaved = false,
  });

  double get effectivePrice => unitPrice ?? product.price;

  double get total => discountPerUnit
      ? (effectivePrice - discount) * quantity + (extraCost ?? 0.0)
      : (effectivePrice * quantity) - discount + (extraCost ?? 0.0);

  double get taxAmount => total * (product.tax_rate / 100);
}
