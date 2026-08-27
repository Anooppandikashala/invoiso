import 'package:uuid/uuid.dart';

import 'package:invoiso/domain/purchase_bill_totals_calculator.dart';

class PurchaseBillItem {
  String id;
  String? productId; // nullable — ad-hoc/one-off items are not tied to a product
  String productName;
  String productDescription;
  double quantity;
  double costPerUnit;
  double taxRate; // percent
  bool costIncludesTax; // whether costPerUnit already includes taxRate

  PurchaseBillItem({
    String? id,
    this.productId,
    required this.productName,
    this.productDescription = '',
    required this.quantity,
    required this.costPerUnit,
    this.taxRate = 0.0,
    this.costIncludesTax = false,
  }) : id = id ?? const Uuid().v4();

  PurchaseBillLineAmount get _amounts => PurchaseBillTotalsCalculator.line(
        costPerUnit: costPerUnit,
        quantity: quantity,
        taxRatePercent: taxRate,
        costIncludesTax: costIncludesTax,
      );

  double get lineTotal => _amounts.lineTotal;

  double get taxAmount => _amounts.itemTax;

  double get total => _amounts.displayTotal;

  // Tax-exclusive cost per unit regardless of costIncludesTax — the figure
  // to persist as a product's "last cost"/stock-ledger unit cost, so those
  // stay consistently tax-exclusive no matter how a bill was entered.
  double get netCostPerUnit => quantity == 0 ? costPerUnit : lineTotal / quantity;

  factory PurchaseBillItem.fromMap(Map<String, dynamic> map) =>
      PurchaseBillItem(
        id: map['id'] as String?,
        productId: map['product_id'] as String?,
        productName: map['product_name'] as String? ?? '',
        productDescription: map['product_description'] as String? ?? '',
        quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
        costPerUnit: (map['cost_per_unit'] as num?)?.toDouble() ?? 0.0,
        taxRate: (map['tax_rate'] as num?)?.toDouble() ?? 0.0,
        costIncludesTax: (map['cost_includes_tax'] as int?) == 1,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'product_id': productId,
        'product_name': productName,
        'product_description': productDescription,
        'quantity': quantity,
        'cost_per_unit': costPerUnit,
        'tax_rate': taxRate,
        'cost_includes_tax': costIncludesTax ? 1 : 0,
        'line_total': lineTotal,
      };
}
