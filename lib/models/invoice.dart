import '../common.dart';
import '../domain/invoice_calculator.dart';
import '../domain/invoice_totals_calculator.dart';
import 'additional_cost.dart';
import 'customer.dart';
import 'invoice_item.dart';
import 'invoice_payment.dart';

class Invoice {
  String id;
  String? invoiceNumber; // per-type sequential display number; null on legacy rows (falls back to id)
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
  String? bankAccountId; // selected bank account label key for this invoice
  DateTime? dueDate;
  String?
      quantityLabel; // custom label for the Qty column (e.g. "Words", "Hours")
  List<AdditionalCost>
      additionalCosts; // e.g. Shipping, Packaging (zero tax, added after tax)
  double previousBalance;

  Invoice({
    required this.id,
    this.invoiceNumber,
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
    this.previousBalance = 0.0,
  });

  InvoiceTotals get _totals => InvoiceTotalsCalculator.totals(
        lines: items.map((item) => item._amountsForInvoice),
        taxMode: taxMode,
        globalTaxRate: taxRate,
        globalTaxRateFormat: TaxRateFormat.fraction,
        additionalCostsTotal: additionalCostsTotal,
      );

  double get subtotal => _totals.subtotal;

  double get grossSubtotal => _totals.grossSubtotal;

  double get totalDiscount => _totals.totalDiscount;

  double get tax => _totals.tax;

  double get additionalCostsTotal =>
      additionalCosts.fold(0.0, (sum, c) => sum + c.amount);

  double get total => _totals.total;

  double get amountPaid => payments.fold(0.0, (sum, p) => sum + p.amountPaid);

  double get outstandingBalance =>
      InvoiceCalculator.outstanding(total: total, paid: amountPaid);

  PaymentStatus get paymentStatus =>
      InvoiceCalculator.paymentStatus(total: total, paid: amountPaid);
}

extension _InvoiceItemTotals on InvoiceItem {
  InvoiceLineAmount get _amountsForInvoice => InvoiceTotalsCalculator.line(
        price: effectivePrice,
        quantity: quantity,
        discount: discount,
        discountPerUnit: discountPerUnit,
        extraCost: extraCost ?? 0.0,
        taxRatePercent: product.tax_rate.toDouble(),
      );
}
