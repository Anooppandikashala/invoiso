class InvoicePayment {
  final String id;
  final String invoiceId;
  final String invoiceNumber;
  final String receiptNumber;
  final double amountPaid;
  final double taxAmountPaid;
  final double previouslyPaid;
  final double balanceAfter;
  final DateTime datePaid;
  final String? paymentMethod;
  final String? notes;

  const InvoicePayment({
    required this.id,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.receiptNumber,
    required this.amountPaid,
    required this.taxAmountPaid,
    required this.previouslyPaid,
    required this.balanceAfter,
    required this.datePaid,
    this.paymentMethod,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'invoice_id': invoiceId,
        'invoice_number': invoiceNumber,
        'receipt_number': receiptNumber,
        'amount_paid': amountPaid,
        'tax_amount_paid': taxAmountPaid,
        'previously_paid': previouslyPaid,
        'balance_after': balanceAfter,
        'date_paid': datePaid.toIso8601String().split('T').first,
        'payment_method': paymentMethod,
        'notes': notes,
      };

  factory InvoicePayment.fromMap(Map<String, dynamic> map) => InvoicePayment(
        id: map['id'] as String,
        invoiceId: map['invoice_id'] as String,
        invoiceNumber: map['invoice_number'] as String,
        receiptNumber: map['receipt_number'] as String,
        amountPaid: (map['amount_paid'] as num).toDouble(),
        taxAmountPaid: (map['tax_amount_paid'] as num).toDouble(),
        previouslyPaid: (map['previously_paid'] as num).toDouble(),
        balanceAfter: (map['balance_after'] as num).toDouble(),
        datePaid: DateTime.parse(map['date_paid'] as String),
        paymentMethod: map['payment_method'] as String?,
        notes: map['notes'] as String?,
      );
}
