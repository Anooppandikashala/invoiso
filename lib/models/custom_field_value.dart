import 'dart:convert';

/// A per-invoice value for a [CustomFieldDef].
class CustomFieldValue {
  final String defId; // references CustomFieldDef.id
  final String label; // snapshot of the label at fill time, so renaming a definition later doesn't relabel old PDFs
  final String value;

  const CustomFieldValue({
    required this.defId,
    required this.label,
    required this.value,
  });

  Map<String, dynamic> toJson() =>
      {'defId': defId, 'label': label, 'value': value};

  factory CustomFieldValue.fromJson(Map<String, dynamic> json) => CustomFieldValue(
        defId: json['defId'] as String? ?? '',
        label: json['label'] as String? ?? '',
        value: json['value'] as String? ?? '',
      );

  static List<CustomFieldValue> listFromJson(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => CustomFieldValue.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String listToJson(List<CustomFieldValue> values) =>
      jsonEncode(values.map((v) => v.toJson()).toList());
}
