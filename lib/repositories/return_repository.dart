import 'package:invoiso/models/customer_credit.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/refund.dart';

/// Return management — credit / debit notes, refunds, customer credit.
abstract class ReturnRepository {
  /// [replaceDraft]: finalizing a saved draft note with the same id.
  Future<void> createCreditNote({
    required Invoice creditNote,
    Invoice? originalInvoice,
    RefundInput? immediateRefund,
    bool replaceDraft = false,
  });

  Future<void> createDebitNote({
    required Invoice debitNote,
    Invoice? originalInvoice,
    bool replaceDraft = false,
  });

  Future<Refund> recordRefund({
    required Invoice creditNote,
    required double amount,
    required DateTime date,
    String? method,
    String? notes,
  });

  Future<Refund> convertCreditToRefund({
    required Invoice creditNote,
    required double amount,
    required DateTime date,
    String? method,
    String? notes,
  });

  /// Applies a customer's stored credit against [invoice]; returns the amount
  /// actually consumed.
  Future<double> applyCustomerCreditToInvoice({
    required Invoice invoice,
    required double amount,
  });

  Future<void> voidCreditNote(String creditNoteId);

  Future<List<Invoice>> getNotesForInvoice(String invoiceId);

  /// Credit / debit notes keyed by the invoice they were raised against.
  Future<Map<String, List<Invoice>>> getNotesForInvoices(
      List<String> invoiceIds);

  Future<Map<String, double>> getReturnedQtyByLine(String originalInvoiceId);

  Future<double> getRemainingCustomerCredit({
    required String customerId,
    String? customerName,
    required String currencyCode,
  });

  /// Open credit per source credit note, oldest first.
  Future<List<CustomerCreditSource>> getCustomerCreditSources({
    required String customerId,
    String? customerName,
    required String currencyCode,
  });

  Future<List<Refund>> getRefundsForCreditNote(String creditNoteId);
}
