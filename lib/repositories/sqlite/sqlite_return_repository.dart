import 'package:invoiso/database/return_service.dart';
import 'package:invoiso/models/customer_credit.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/refund.dart';
import 'package:invoiso/repositories/return_repository.dart';

class SqliteReturnRepository implements ReturnRepository {
  @override
  Future<void> createCreditNote({
    required Invoice creditNote,
    Invoice? originalInvoice,
    RefundInput? immediateRefund,
    bool replaceDraft = false,
  }) =>
      ReturnService.createCreditNote(
        creditNote: creditNote,
        originalInvoice: originalInvoice,
        immediateRefund: immediateRefund,
        replaceDraft: replaceDraft,
      );

  @override
  Future<void> createDebitNote({
    required Invoice debitNote,
    Invoice? originalInvoice,
    bool replaceDraft = false,
  }) =>
      ReturnService.createDebitNote(
        debitNote: debitNote,
        originalInvoice: originalInvoice,
        replaceDraft: replaceDraft,
      );

  @override
  Future<Refund> recordRefund({
    required Invoice creditNote,
    required double amount,
    required DateTime date,
    String? method,
    String? notes,
  }) =>
      ReturnService.recordRefund(
        creditNote: creditNote,
        amount: amount,
        date: date,
        method: method,
        notes: notes,
      );

  @override
  Future<Refund> convertCreditToRefund({
    required Invoice creditNote,
    required double amount,
    required DateTime date,
    String? method,
    String? notes,
  }) =>
      ReturnService.convertCreditToRefund(
        creditNote: creditNote,
        amount: amount,
        date: date,
        method: method,
        notes: notes,
      );

  @override
  Future<double> applyCustomerCreditToInvoice({
    required Invoice invoice,
    required double amount,
  }) =>
      ReturnService.applyCustomerCreditToInvoice(
        invoice: invoice,
        amount: amount,
      );

  @override
  Future<void> voidCreditNote(String creditNoteId) =>
      ReturnService.voidCreditNote(creditNoteId);

  @override
  Future<List<Invoice>> getNotesForInvoice(String invoiceId) =>
      ReturnService.getNotesForInvoice(invoiceId);

  @override
  Future<Map<String, List<Invoice>>> getNotesForInvoices(
          List<String> invoiceIds) =>
      ReturnService.getNotesForInvoices(invoiceIds);

  @override
  Future<Map<String, double>> getReturnedQtyByLine(String originalInvoiceId) =>
      ReturnService.getReturnedQtyByLine(originalInvoiceId);

  @override
  Future<double> getRemainingCustomerCredit({
    required String customerId,
    String? customerName,
    required String currencyCode,
  }) =>
      ReturnService.getRemainingCustomerCredit(
        customerId: customerId,
        customerName: customerName,
        currencyCode: currencyCode,
      );

  @override
  Future<List<CustomerCreditSource>> getCustomerCreditSources({
    required String customerId,
    String? customerName,
    required String currencyCode,
  }) =>
      ReturnService.getCustomerCreditSources(
        customerId: customerId,
        customerName: customerName,
        currencyCode: currencyCode,
      );

  @override
  Future<List<Refund>> getRefundsForCreditNote(String creditNoteId) =>
      ReturnService.getRefundsForCreditNote(creditNoteId);
}
