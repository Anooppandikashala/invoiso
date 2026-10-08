class StockTransaction {
  final String id;
  final String productId;
  final String transactionType; // 'purchase' | 'sale' | 'adjustment'
  final String? referenceId;
  final double quantityChange;
  final double stockBefore;
  final double stockAfter;
  final double? unitCost;
  final DateTime transactionDate;
  final String? notes;

  const StockTransaction({
    required this.id,
    required this.productId,
    required this.transactionType,
    this.referenceId,
    required this.quantityChange,
    required this.stockBefore,
    required this.stockAfter,
    this.unitCost,
    required this.transactionDate,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'product_id': productId,
        'transaction_type': transactionType,
        'reference_id': referenceId,
        'quantity_change': quantityChange,
        'stock_before': stockBefore,
        'stock_after': stockAfter,
        'unit_cost': unitCost,
        'transaction_date': transactionDate.toIso8601String(),
        'notes': notes,
      };

  factory StockTransaction.fromMap(Map<String, dynamic> map) =>
      StockTransaction(
        id: map['id'] as String,
        productId: map['product_id'] as String,
        transactionType: map['transaction_type'] as String,
        referenceId: map['reference_id'] as String?,
        quantityChange: (map['quantity_change'] as num).toDouble(),
        stockBefore: (map['stock_before'] as num).toDouble(),
        stockAfter: (map['stock_after'] as num).toDouble(),
        unitCost: (map['unit_cost'] as num?)?.toDouble(),
        transactionDate: DateTime.parse(map['transaction_date'] as String),
        notes: map['notes'] as String?,
      );
}
