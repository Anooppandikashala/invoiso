class CustomerIdentity {
  const CustomerIdentity._();

  static const unknownName = 'Unknown';

  static String key({String? id, String? name}) {
    final trimmedId = id?.trim();
    if (trimmedId != null && trimmedId.isNotEmpty) return trimmedId;
    final trimmedName = name?.trim();
    if (trimmedName != null && trimmedName.isNotEmpty) return trimmedName;
    return unknownName;
  }

  static String displayName(String? name) {
    final trimmed = name?.trim();
    return trimmed == null || trimmed.isEmpty ? unknownName : trimmed;
  }
}
