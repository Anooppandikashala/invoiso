import 'dart:convert';

class AdditionalCost {
  final String label;
  final double amount;
  // GST Sec 15: charges are part of the taxable value unless a pure-agent
  // reimbursement. Missing in old JSON → untaxed, so saved totals never change.
  final bool taxable;
  final double taxRate; // percent; used in per-item tax mode only
  final String hsn; // HSN/SAC for the HSN summary

  const AdditionalCost({
    required this.label,
    required this.amount,
    this.taxable = false,
    this.taxRate = 0,
    this.hsn = '',
  });

  // New keys only when set, so untaxed charges keep the old JSON shape.
  Map<String, dynamic> toJson() => {
        'label': label,
        'amount': amount,
        if (taxable) 'taxable': true,
        if (taxRate != 0) 'taxRate': taxRate,
        if (hsn.isNotEmpty) 'hsn': hsn,
      };

  factory AdditionalCost.fromJson(Map<String, dynamic> json) => AdditionalCost(
        label: json['label'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        taxable: json['taxable'] == true,
        taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0.0,
        hsn: json['hsn'] as String? ?? '',
      );

  static List<AdditionalCost> listFromJson(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => AdditionalCost.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String listToJson(List<AdditionalCost> costs) =>
      jsonEncode(costs.map((c) => c.toJson()).toList());
}
