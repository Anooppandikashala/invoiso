class CompanyInfo {
  final int? id;
  final String name;
  final String address;
  final String phone;
  final String email;
  final String website;

  CompanyInfo({
    this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    required this.website,
  });

  factory CompanyInfo.fromMap(Map<String, dynamic> map) {
    return CompanyInfo(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      phone: map['phone'],
      email: map['email'],
      website: map['website'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
    };
  }
}
