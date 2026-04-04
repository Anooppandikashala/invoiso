import 'package:invoiso/models/product.dart';

class InvoiceItem {
  Product product;
  double quantity;
  double discount;
  double? unitPrice;  // overrides product.price when set
  double? extraCost;  // optional flat fee added on top of (price × qty) - discount

  InvoiceItem({
    required this.product,
    required this.quantity,  // supports decimals (e.g. 1.5 hrs)
    this.discount = 0.0,
    this.unitPrice,
    this.extraCost,
  });

  double get effectivePrice => unitPrice ?? product.price;

  double get total => (effectivePrice * quantity) - discount + (extraCost ?? 0.0);

  double get taxAmount => total * (product.tax_rate / 100);
}
