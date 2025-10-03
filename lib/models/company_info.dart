class CompanyInfo {
  final int? id;
  final String name;
  final String address;
  final String phone;
  final String email;
  final String website;
  final String gstin;

  CompanyInfo({
    this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    required this.website,
    required this.gstin,
  });

  factory CompanyInfo.fromMap(Map<String, dynamic> map) {
    return CompanyInfo(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      phone: map['phone'],
      email: map['email'],
      website: map['website'],
      gstin: map['gstin']
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
      'gstin':gstin
    };
  }
}
