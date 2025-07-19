import 'customer.dart';
import 'invoice_item.dart';

class Invoice {
  String id;
  Customer customer;
  List<InvoiceItem> items;
  DateTime date;
  String? notes;
  double taxRate;
  String type;

  Invoice({
    required this.id,
    required this.customer,
    required this.items,
    required this.date,
    required this.type,
    this.notes,
    this.taxRate = 0.1, // 10% default tax
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.total);
  double get tax => subtotal * taxRate;
  double get total => subtotal + tax;
}