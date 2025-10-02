import 'package:invoiso/models/product.dart';

class InvoiceItem {
  Product product;
  int quantity;
  double discount;

  InvoiceItem({
    required this.product,
    required this.quantity,
    this.discount = 0.0,
  });

  double get total => (product.price * quantity) - discount;
}
