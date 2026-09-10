import 'package:invoiso/utils/app_date.dart';

/// One-shot payout details for an immediate refund handed back with a credit
/// note (settlement `refund`) or recorded later against a stored credit.
typedef RefundInput = ({
  double amount,
  String? method,
  DateTime date,
  String? notes,
});

/// Money paid back to a customer against a credit note. The mirror of
/// [InvoicePayment] — deliberately its own table so aggregates over
/// `invoice_payments` keep meaning "money in".
class Refund {
  final String id;
  final String creditNoteId; // invoices.id where type = 'Credit Note'
  final String creditNoteNumber; // denormalized
  final String receiptNumber; // {creditNoteNumber}-R{n}
  final double amount;
  final double taxAmount;
  final String? refundMethod; // Cash | Bank Transfer | Check | Online | Other
  final DateTime dateRefunded;
  final String? notes;

  const Refund({
    required this.id,
    required this.creditNoteId,
    required this.creditNoteNumber,
    required this.receiptNumber,
    required this.amount,
    this.taxAmount = 0.0,
    this.refundMethod,
    required this.dateRefunded,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'credit_note_id': creditNoteId,
        'credit_note_number': creditNoteNumber,
        'receipt_number': receiptNumber,
        'amount': amount,
        'tax_amount': taxAmount,
        'refund_method': refundMethod,
        'date_refunded': AppDate.dateKey(dateRefunded),
        'notes': notes,
      };

  factory Refund.fromMap(Map<String, dynamic> map) => Refund(
        id: map['id'] as String,
        creditNoteId: map['credit_note_id'] as String,
        creditNoteNumber: map['credit_note_number'] as String,
        receiptNumber: map['receipt_number'] as String,
        amount: (map['amount'] as num).toDouble(),
        taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0.0,
        refundMethod: map['refund_method'] as String?,
        dateRefunded: DateTime.parse(map['date_refunded'] as String),
        notes: map['notes'] as String?,
      );
}
