import 'package:invoiso/utils/app_date.dart';

class SupplierPayment {
  final String id;
  final String billId;
  final String? supplierId;
  final double amountPaid;
  final double previouslyPaid;
  final double balanceAfter;
  final DateTime datePaid;
  final String? paymentMethod;
  final String? notes;

  const SupplierPayment({
    required this.id,
    required this.billId,
    this.supplierId,
    required this.amountPaid,
    required this.previouslyPaid,
    required this.balanceAfter,
    required this.datePaid,
    this.paymentMethod,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'bill_id': billId,
        'supplier_id': supplierId,
        'amount_paid': amountPaid,
        'previously_paid': previouslyPaid,
        'balance_after': balanceAfter,
        'date_paid': AppDate.dateKey(datePaid),
        'payment_method': paymentMethod,
        'notes': notes,
      };

  factory SupplierPayment.fromMap(Map<String, dynamic> map) => SupplierPayment(
        id: map['id'] as String,
        billId: map['bill_id'] as String,
        supplierId: map['supplier_id'] as String?,
        amountPaid: (map['amount_paid'] as num).toDouble(),
        previouslyPaid: (map['previously_paid'] as num).toDouble(),
        balanceAfter: (map['balance_after'] as num).toDouble(),
        datePaid: DateTime.parse(map['date_paid'] as String),
        paymentMethod: map['payment_method'] as String?,
        notes: map['notes'] as String?,
      );
}
