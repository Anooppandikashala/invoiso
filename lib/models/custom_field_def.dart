import 'dart:convert';

/// A user-defined custom field (e.g. "Vehicle No", "Delivery Note").
/// Defined once in settings, filled per invoice via [CustomFieldValue].
class CustomFieldDef {
  final String id; // stable id, so renaming a label doesn't orphan old invoice values
  final String label;
  final int sortOrder;
  // Customer custom fields only: whether values print on PDFs (default true;
  // missing in older saved JSON = true). Unused for invoice custom fields.
  final bool showInPdf;

  const CustomFieldDef({
    required this.id,
    required this.label,
    required this.sortOrder,
    this.showInPdf = true,
  });

  CustomFieldDef copyWith({String? label, int? sortOrder, bool? showInPdf}) =>
      CustomFieldDef(
        id: id,
        label: label ?? this.label,
        sortOrder: sortOrder ?? this.sortOrder,
        showInPdf: showInPdf ?? this.showInPdf,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'sortOrder': sortOrder,
        'showInPdf': showInPdf,
      };

  factory CustomFieldDef.fromJson(Map<String, dynamic> json) => CustomFieldDef(
        id: json['id'] as String? ?? '',
        label: json['label'] as String? ?? '',
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
        showInPdf: json['showInPdf'] as bool? ?? true,
      );

  static List<CustomFieldDef> listFromJson(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => CustomFieldDef.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String listToJson(List<CustomFieldDef> defs) =>
      jsonEncode(defs.map((d) => d.toJson()).toList());
}
