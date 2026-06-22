import 'package:invoiso/database/payment_service.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/invoice_payment.dart';
import 'package:invoiso/repositories/payment_repository.dart';

class SqlitePaymentRepository implements PaymentRepository {
  @override
  Future<InvoicePayment> addPayment({
    required Invoice invoice,
    required double amountPaid,
    required DateTime datePaid,
    String? paymentMethod,
    String? notes,
  }) =>
      PaymentService.addPayment(
        invoice: invoice,
        amountPaid: amountPaid,
        datePaid: datePaid,
        paymentMethod: paymentMethod,
        notes: notes,
      );
  @override
  Future<int> addPaymentBatch({
    required List<Invoice> invoices,
    required DateTime datePaid,
    String? paymentMethod,
    String? notes,
  }) =>
      PaymentService.addPaymentBatch(
        invoices: invoices,
        datePaid: datePaid,
        paymentMethod: paymentMethod,
        notes: notes,
      );
  @override
  Future<List<InvoicePayment>> getPaymentsForInvoice(String invoiceId) =>
      PaymentService.getPaymentsForInvoice(invoiceId);
  @override
  Future<double> getTotalPaidForInvoice(String invoiceId) =>
      PaymentService.getTotalPaidForInvoice(invoiceId);
  @override
  Future<Map<String, double>> getTotalPaidBatch(List<String> invoiceIds) =>
      PaymentService.getTotalPaidBatch(invoiceIds);
  @override
  Future<void> deletePayment(String paymentId) => PaymentService.deletePayment(paymentId);
  @override
  Future<List<InvoicePayment>> getAllPaymentsBetween(DateTime from, DateTime to) =>
      PaymentService.getAllPaymentsBetween(from, to);
  @override
  Future<double> getTaxPaidBetween(DateTime from, DateTime to) =>
      PaymentService.getTaxPaidBetween(from, to);
}
