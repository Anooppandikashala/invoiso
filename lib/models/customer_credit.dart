/// Unused credit from one credit note: its number, the invoice it was raised
/// against (null when standalone), and what's left of it.
typedef CustomerCreditSource = ({
  String noteNumber,
  String? againstNumber,
  double remaining,
});

/// A stored credit balance a customer holds with the business, created when a
/// credit note is settled as "keep as customer credit". Drawn down (via
/// [appliedAmount]) by later invoices or by converting the credit to a refund.
class CustomerCredit {
  final String id;
  final String? customerId; // '' / null for ad-hoc (unsaved) customers
  final String customerName; // denormalized — customers can be unsaved
  final String currencyCode;
  final String sourceType; // 'credit_note'
  final String sourceId; // credit note invoices.id
  final double amount; // credit granted (positive)
  final double appliedAmount; // consumed by later invoices / converted to refund
  final DateTime createdAt;

  const CustomerCredit({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.currencyCode,
    required this.sourceType,
    required this.sourceId,
    required this.amount,
    this.appliedAmount = 0.0,
    required this.createdAt,
  });

  /// Credit still available on this row.
  double get remaining => (amount - appliedAmount).clamp(0.0, double.infinity);

  Map<String, dynamic> toMap() => {
        'id': id,
        'customer_id': customerId,
        'customer_name': customerName,
        'currency_code': currencyCode,
        'source_type': sourceType,
        'source_id': sourceId,
        'amount': amount,
        'applied_amount': appliedAmount,
        'created_at': createdAt.toIso8601String(),
      };

  factory CustomerCredit.fromMap(Map<String, dynamic> map) => CustomerCredit(
        id: map['id'] as String,
        customerId: map['customer_id'] as String?,
        customerName: map['customer_name'] as String,
        currencyCode: map['currency_code'] as String,
        sourceType: map['source_type'] as String,
        sourceId: map['source_id'] as String,
        amount: (map['amount'] as num).toDouble(),
        appliedAmount: (map['applied_amount'] as num?)?.toDouble() ?? 0.0,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
