import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/invoice_payment.dart';

abstract class PaymentRepository {
  Future<InvoicePayment> addPayment({
    required Invoice invoice,
    required double amountPaid,
    required DateTime datePaid,
    String? paymentMethod,
    String? notes,
  });
  Future<int> addPaymentBatch({
    required List<Invoice> invoices,
    required DateTime datePaid,
    String? paymentMethod,
    String? notes,
  });
  /// Applies a single payment across multiple invoices for the same
  /// customer (e.g. smallest outstanding balance first, so it clears as
  /// many whole invoices as possible). Writes one [InvoicePayment] per
  /// allocation with a positive amount, in a single transaction. Amounts
  /// must already be decided by the caller — this does no allocation itself.
  Future<List<InvoicePayment>> applyPaymentAcrossInvoices({
    required List<({Invoice invoice, double amount})> allocations,
    required DateTime datePaid,
    String? paymentMethod,
    String? notes,
  });
  Future<List<InvoicePayment>> getPaymentsForInvoice(String invoiceId);
  Future<double> getTotalPaidForInvoice(String invoiceId);
  Future<Map<String, double>> getTotalPaidBatch(List<String> invoiceIds);
  Future<void> deletePayment(String paymentId);
  Future<List<InvoicePayment>> getAllPaymentsBetween(DateTime from, DateTime to);
  Future<double> getTaxPaidBetween(DateTime from, DateTime to);
}
