import '../common.dart';
import 'customer.dart';
import 'invoice_item.dart';
import 'invoice_payment.dart';

class Invoice {
  String id;
  Customer customer;
  List<InvoiceItem> items;
  DateTime date;
  String? notes;
  double taxRate;
  String type;
  String currencyCode;
  String currencySymbol;
  TaxMode taxMode;
  List<InvoicePayment> payments;
  String? upiId; // selected UPI account for this invoice
  DateTime? dueDate;

  Invoice({
    required this.id,
    required this.customer,
    required this.items,
    required this.date,
    required this.type,
    this.notes,
    this.taxRate = 0.0,
    this.currencyCode = 'INR',
    this.currencySymbol = '₹',
    this.taxMode = TaxMode.global,
    this.payments = const [],
    this.upiId,
    this.dueDate,
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.total);

  double get tax {
    switch (taxMode) {
      case TaxMode.global:
        return subtotal * taxRate;
      case TaxMode.perItem:
        return items.fold(
          0.0,
          (sum, item) => sum + item.total * (item.product.tax_rate / 100),
        );
      case TaxMode.none:
        return 0.0;
    }
  }

  double get total => subtotal + tax;

  double get amountPaid => payments.fold(0.0, (sum, p) => sum + p.amountPaid);

  double get outstandingBalance => (total - amountPaid).clamp(0.0, double.infinity);

  PaymentStatus get paymentStatus {
    if (amountPaid <= 0) return PaymentStatus.unpaid;
    if (outstandingBalance <= 0) return PaymentStatus.paid;
    return PaymentStatus.partial;
  }
}
