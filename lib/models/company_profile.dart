/// One entry in the device-level company registry (see
/// `CompanyRegistryService`) — metadata about a company's own SQLite file,
/// not the company's actual business data (that lives inside that file).
class CompanyProfile {
  final String id;
  final String name;
  final String dbFileName;
  final DateTime createdAt;

  const CompanyProfile({
    required this.id,
    required this.name,
    required this.dbFileName,
    required this.createdAt,
  });

  CompanyProfile copyWith({String? name}) => CompanyProfile(
        id: id,
        name: name ?? this.name,
        dbFileName: dbFileName,
        createdAt: createdAt,
      );

  factory CompanyProfile.fromJson(Map<String, dynamic> json) => CompanyProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        dbFileName: json['dbFileName'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dbFileName': dbFileName,
        'createdAt': createdAt.toIso8601String(),
      };
}
