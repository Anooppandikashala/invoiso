import 'dart:convert';

class AdditionalCost {
  final String label;
  final double amount;

  const AdditionalCost({required this.label, required this.amount});

  Map<String, dynamic> toJson() => {'label': label, 'amount': amount};

  factory AdditionalCost.fromJson(Map<String, dynamic> json) => AdditionalCost(
        label: json['label'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
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
