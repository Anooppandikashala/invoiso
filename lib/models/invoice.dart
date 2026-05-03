import '../common.dart';
import 'additional_cost.dart';
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
  String? upiId;           // selected UPI account for this invoice
  String? bankAccountId;   // selected bank account label key for this invoice
  DateTime? dueDate;
  String? quantityLabel; // custom label for the Qty column (e.g. "Words", "Hours")
  List<AdditionalCost> additionalCosts; // e.g. Shipping, Packaging (zero tax, added after tax)

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
    this.bankAccountId,
    this.dueDate,
    this.quantityLabel,
    this.additionalCosts = const [],
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.total);

  double get grossSubtotal => items.fold(0.0, (sum, item) => sum + item.grossPrice);

  double get totalDiscount => items.fold(0.0, (sum, item) => sum + item.totalDiscount);

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

  double get additionalCostsTotal =>
      additionalCosts.fold(0.0, (sum, c) => sum + c.amount);

  double get total => subtotal + tax + additionalCostsTotal;

  double get amountPaid => payments.fold(0.0, (sum, p) => sum + p.amountPaid);

  double get outstandingBalance => (total - amountPaid).clamp(0.0, double.infinity);

  PaymentStatus get paymentStatus {
    if (amountPaid <= 0) return PaymentStatus.unpaid;
    if (outstandingBalance <= 0) return PaymentStatus.paid;
    return PaymentStatus.partial;
  }
}
